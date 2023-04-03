// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./event/CoreBorrowingEvent.sol";
import "./CoreBaseFunc.sol";
import "../../externalContract/openzeppelin/upgradeable/SafeERC20Upgradeable.sol";

contract CoreBorrowing is CoreBaseFunc, CoreBorrowingEvent {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
      @dev Function to borrow token from APHPool by providing other token as collateral,
            Moreover, this function allows users to borrow more from exists loan with or without
            adding more collateral.
      
      NOTE: This function can be only called by registerd APHPool (proxy).
     */
    function borrow(
        uint256 loanId,
        uint256 nftId,
        uint256 borrowAmount,
        address borrowTokenAddress,
        uint256 collateralSentAmount,
        address collateralTokenAddress,
        uint256 newOwedPerDay,
        uint256 interestRate
    ) external whenFuncNotPaused(msg.sig) nonReentrant returns (Loan memory) {
        return
            _borrow(
                loanId,
                nftId,
                borrowAmount,
                borrowTokenAddress,
                collateralSentAmount,
                collateralTokenAddress,
                newOwedPerDay,
                interestRate
            );
    }

    /**
      @dev Function to repay borrowToken (principal) or interest of loan with
            the given loanId and nftId back to protocol.

      NOTE: Users can choose to repay only interest or repay both principal and interest.
            Users can only repay to active loan.
     */
    function repay(
        uint256 loanId,
        uint256 nftId,
        uint256 repayAmount,
        bool isOnlyInterest
    )
        external
        payable
        whenFuncNotPaused(msg.sig)
        nonReentrant
        returns (uint256 borrowPaid, uint256 interestPaid)
    {
        nftId = _getUsableToken(msg.sender, nftId);
        Loan storage loan = loans[nftId][loanId];
        require(
            loan.borrowTokenAddress == wethAddress || msg.value == 0,
            "CoreBorrowing/no-support-transfering-ether-in"
        );

        bool isLoanClosed;
        uint256 tmpCollateralAmount = loan.collateralAmount;
        (borrowPaid, interestPaid, isLoanClosed) = _repay(
            loanId,
            nftId,
            repayAmount,
            isOnlyInterest
        );

        if (loan.borrowTokenAddress == wethAddress) {
            require(
                msg.value >= borrowPaid + interestPaid,
                "CoreBorrowing/insufficient-ether-amount"
            );
            _transferFromIn(msg.sender, address(this), wethAddress, msg.value);
            if (borrowPaid > 0) {
                IERC20Upgradeable(wethAddress).safeTransfer(
                    assetToPool[wethAddress],
                    borrowPaid
                );
            }
            IERC20Upgradeable(wethAddress).safeTransfer(
                IAPHPool(assetToPool[wethAddress]).interestVaultAddress(),
                interestPaid
            );
            _transferOut(
                msg.sender,
                wethAddress,
                msg.value - (borrowPaid + interestPaid)
            );
        } else {
            if (borrowPaid > 0) {
                _transferFromIn(
                    msg.sender,
                    assetToPool[loan.borrowTokenAddress],
                    loan.borrowTokenAddress,
                    borrowPaid
                );
            }
            _transferFromIn(
                msg.sender,
                IAPHPool(assetToPool[loan.borrowTokenAddress])
                    .interestVaultAddress(),
                loan.borrowTokenAddress,
                interestPaid
            );
        }
        if (isLoanClosed) {
            _transferOut(
                msg.sender,
                loan.collateralTokenAddress,
                tmpCollateralAmount
            );
        }
        return (borrowPaid, interestPaid);
    }

    /**
      @dev Function to adjust collateral of loan with the given loanId and nftId.
            Collateral can be both add or remove. For remove collateral, loan LTV after 
            remove must lower than maxLTV from LoanConfig.
     */
    function adjustCollateral(
        uint256 loanId,
        uint256 nftId,
        uint256 collateralAdjustAmount,
        bool isAdd
    )
        external
        payable
        whenFuncNotPaused(msg.sig)
        nonReentrant
        returns (Loan memory)
    {
        nftId = _getUsableToken(msg.sender, nftId);
        Loan storage loan = loans[nftId][loanId];
        require(
            (loan.collateralTokenAddress == wethAddress && isAdd) ||
                msg.value == 0,
            "CoreBorrowing/no-support-transfering-ether-in"
        );

        Loan memory loanData = _adjustCollateral(
            loanId,
            nftId,
            collateralAdjustAmount,
            isAdd
        );
        if (isAdd) {
            // add colla to core
            _transferFromIn(
                msg.sender,
                address(this),
                loan.collateralTokenAddress,
                collateralAdjustAmount
            );
        } else {
            // withdraw colla to user
            _transferOut(
                msg.sender,
                loan.collateralTokenAddress,
                collateralAdjustAmount
            );
        }
        return loanData;
    }

    /**
      @dev Function to rollover loan with the given loanId and nftId.
            Rollover is similar to close and open loan again to change loan's interest rate.
            If loan opened longer than 28 days, the interest from extended duration is calculated 
            with delay fees (ex: 5%), this delay fees is added into interestOwed which will be rewarded to lender.
            This function can be call by loan's owner, for overdue loan's other user can call via liquidate function. 
     */
    function rollover(
        uint256 loanId,
        uint256 nftId
    )
        external
        whenFuncNotPaused(msg.sig)
        nonReentrant
        returns (uint256 delayInterest, uint256 collateralBountyReward)
    {
        nftId = _getUsableToken(msg.sender, nftId);
        Loan storage loan = loans[nftId][loanId];
        _settleBorrowInterest(loan);
        (delayInterest, collateralBountyReward) = _rollover(
            loanId,
            nftId,
            msg.sender
        );
    }

    /**
      @dev Function to liquidate loan with the given loanId and nftId.
            First, this function will check if a loan is overdue or not.
            If a loan is overdue, _rollover is called 
                - For loan's owner: bounty fee is added to interestOwed same as rollover function.
                - For non loan's owner: bounty fee is given as reward in form of collateral token.

            Second, this function  call _liquidate , which sells some of loan's collateral to repay 
            principal and interest. While leftover collateral is divided into 2 parts.
            The former is liquidation fees (ex: 5%) and is added with the First and is rewarded to liquidator,
            the latter is sent back to loan's owner.
     */
    function liquidate(
        uint256 loanId,
        uint256 nftId
    )
        external
        whenFuncNotPaused(msg.sig)
        nonReentrant
        returns (
            uint256 repayBorrow,
            uint256 repayInterest,
            uint256 bountyReward,
            uint256 leftOverCollateral
        )
    {
        Loan storage loan = loans[nftId][loanId];
        (
            repayBorrow,
            repayInterest,
            bountyReward,
            leftOverCollateral
        ) = _liquidate(loanId, nftId);

        IERC20Upgradeable(loan.borrowTokenAddress).safeTransfer(
            assetToPool[loan.borrowTokenAddress],
            repayBorrow
        );
        IERC20Upgradeable(loan.borrowTokenAddress).safeTransfer(
            IAPHPool(assetToPool[loan.borrowTokenAddress])
                .interestVaultAddress(),
            repayInterest
        );

        _transferOut(msg.sender, loan.collateralTokenAddress, bountyReward);
        _transferOut(
            _getTokenOwnership(nftId),
            loan.collateralTokenAddress,
            leftOverCollateral
        );
    }

    // internal function
    function _borrow(
        uint256 loanId,
        uint256 nftId,
        uint256 borrowAmount,
        address borrowTokenAddress,
        uint256 collateralSentAmount,
        address collateralTokenAddress,
        uint256 newOwedPerDay,
        uint256 interestRate
    ) internal returns (Loan memory) {
        require(
            msg.sender == assetToPool[borrowTokenAddress],
            "CoreBorrowing/permission-denied-for-borrow"
        );

        require(
            assetToPool[collateralTokenAddress] != address(0),
            "CoreBorrowing/collateral-token-address-is-not-allowed"
        );

        Loan storage loan;
        LoanExt storage loanExt;

        // [newLoan, owedPerDay, maxLTV, rate, precision]
        uint256[] memory numberArray = new uint256[](5);

        PoolStat storage poolStat = poolStats[msg.sender];
        poolStat.updatedTimestamp = uint64(block.timestamp);
        poolStat.totalBorrowAmount += borrowAmount;

        if (loanId == 0) {
            currentLoanIndex[nftId] += 1;
            loanId = currentLoanIndex[nftId];
            numberArray[0] = 1;
        } else {}

        loan = loans[nftId][loanId];
        loanExt = loanExts[nftId][loanId];

        if (numberArray[0] == 1) {
            // Setup new loans
            loan.borrowTokenAddress = borrowTokenAddress;
            loan.collateralTokenAddress = collateralTokenAddress;
            loan.owedPerDay = newOwedPerDay;
            loan.lastSettleTimestamp = uint64(block.timestamp);

            (loanExt.initialBorrowTokenPrice, ) = _queryRateUSD(
                borrowTokenAddress
            );
            (loanExt.initialCollateralTokenPrice, ) = _queryRateUSD(
                collateralTokenAddress
            );
            loanExt.active = true;
            loanExt.startTimestamp = uint64(block.timestamp);

            poolStat.borrowInterestOwedPerDay += newOwedPerDay;
        } else {
            // Update existing loan
            require(loanExt.active == true, "CoreBorrowing/loan-is-closed");

            require(
                loan.borrowTokenAddress == borrowTokenAddress,
                "CoreBorrowing/borrow-token-not-matched"
            );
            require(
                loan.collateralTokenAddress == collateralTokenAddress,
                "CoreBorrowing/collateral-token-not-matched"
            );

            _settleBorrowInterest(loan);
            // Rollover loan if it is overdue.
            if (loan.rolloverTimestamp < block.timestamp) {
                _rollover(loanId, nftId, msg.sender);
            }

            numberArray[1] = loan.owedPerDay;
            // owedPerDay = [(r1/365 * (ld-now) * p1) + (r2/365 * ld * p2) + (r2/365 * (leftover) * p1)] / ld
            loan.owedPerDay =
                ((loan.owedPerDay *
                    (loan.rolloverTimestamp - block.timestamp)) +
                    (newOwedPerDay * loanDuration) +
                    ((interestRate *
                        loan.borrowAmount *
                        (loanDuration -
                            ((loan.rolloverTimestamp - block.timestamp)))) /
                        (365 * WEI_PERCENT_UNIT))) /
                loanDuration;

            poolStat.borrowInterestOwedPerDay =
                poolStat.borrowInterestOwedPerDay +
                loan.owedPerDay -
                numberArray[1];
        }

        loan.borrowAmount += borrowAmount;
        loan.collateralAmount += collateralSentAmount;
        loan.rolloverTimestamp = uint64(block.timestamp + loanDuration);
        loan.minInterest += (newOwedPerDay * advancedInterestDuration) / 1 days;

        totalCollateralHold[
            loan.collateralTokenAddress
        ] += collateralSentAmount;

        //maxLTV
        numberArray[2] = loanConfigs[borrowTokenAddress][collateralTokenAddress]
            .maxLTV;
        numberArray[2] += IStakePool(
            IMembership(membershipAddress).currentPool()
        ).getMaxLTVBonus(nftId);
        //rate and precision
        (numberArray[3], numberArray[4]) = _queryRate(
            loan.collateralTokenAddress,
            loan.borrowTokenAddress
        );
        require(
            _isLoanLTVExceedTargetLTV(
                loan.borrowAmount,
                loan.collateralAmount,
                MathUpgradeable.max(loan.interestOwed, loan.minInterest),
                numberArray[2], // maxLTV
                numberArray[3], // rate
                numberArray[4] // precision
            ) == false,
            "CoreBorrowing/loan-LTV-is-exceed-maxLTV"
        );

        emit Borrow(
            msg.sender,
            nftId,
            loanId,
            loan.borrowTokenAddress,
            loan.collateralTokenAddress,
            loan.borrowAmount,
            loan.collateralAmount,
            loan.owedPerDay,
            loan.minInterest,
            uint8(numberArray[0]),
            loan.rolloverTimestamp
        );
        return loan;
    }

    function _repay(
        uint256 loanId,
        uint256 nftId,
        uint256 repayAmount,
        bool isOnlyInterest
    )
        internal
        returns (uint256 borrowPaid, uint256 interestPaid, bool isLoanClosed)
    {
        Loan storage loan = loans[nftId][loanId];
        PoolStat storage poolStat = poolStats[
            assetToPool[loan.borrowTokenAddress]
        ];

        require(
            loanExts[nftId][loanId].active == true,
            "CoreBorrowing/loan-is-closed"
        );

        _settleBorrowInterest(loan);
        // Rollover loan if it is overdue.
        if (loan.rolloverTimestamp < block.timestamp) {
            _rollover(loanId, nftId, msg.sender);
        }

        uint256 collateralAmountWithdraw = 0;

        // Pay only interest (or when pay amount not cover all interest)
        if (isOnlyInterest || repayAmount <= loan.interestOwed) {
            interestPaid = MathUpgradeable.min(repayAmount, loan.interestOwed);
            loan.interestOwed -= interestPaid;
            loan.interestPaid += interestPaid;

            if (loan.minInterest > interestPaid) {
                loan.minInterest -= interestPaid;
            } else {
                loan.minInterest = 0;
            }

            poolStat.totalInterestPaid += interestPaid;
        } else {
            interestPaid = MathUpgradeable.max(
                loan.minInterest,
                loan.interestOwed
            );
            if (repayAmount >= (loan.borrowAmount + interestPaid)) {
                // Close loan
                poolStat.totalInterestPaid += interestPaid;
                poolStat.totalBorrowAmount -= loan.borrowAmount;
                poolStat.borrowInterestOwedPerDay -= loan.owedPerDay;

                collateralAmountWithdraw = loan.collateralAmount;

                totalCollateralHold[
                    loan.collateralTokenAddress
                ] -= collateralAmountWithdraw;

                borrowPaid = loan.borrowAmount;
                loan.minInterest = 0;
                loan.interestOwed = 0;
                loan.owedPerDay = 0;
                loan.borrowAmount = 0;
                loan.collateralAmount = 0;
                loan.interestPaid += interestPaid;

                isLoanClosed = true;
                loanExts[nftId][loanId].active = false;
            } else {
                // Pay all interest and some of principal (loan not closed)
                uint256 oldBorrowAmount = loan.borrowAmount;

                interestPaid = MathUpgradeable.min(
                    interestPaid,
                    loan.interestOwed
                );
                loan.interestPaid += interestPaid;

                borrowPaid = MathUpgradeable.min(
                    repayAmount - interestPaid,
                    loan.borrowAmount
                );
                loan.borrowAmount -= borrowPaid;

                poolStat.borrowInterestOwedPerDay -= loan.owedPerDay;

                // Set new owedPerDay
                loan.owedPerDay =
                    (loan.owedPerDay * loan.borrowAmount) /
                    oldBorrowAmount;
                poolStat.borrowInterestOwedPerDay += loan.owedPerDay;

                if (loan.minInterest > loan.interestOwed) {
                    loan.minInterest -= interestPaid;
                } else {
                    loan.minInterest = 0;
                }

                loan.interestOwed -= interestPaid;
                poolStat.totalInterestPaid += interestPaid;
                poolStat.totalBorrowAmount -= borrowPaid;
            }
        }

        _settleInterestAtInterestVault(
            assetToPool[loan.borrowTokenAddress],
            interestPaid,
            0
        );

        emit Repay(
            msg.sender,
            nftId,
            loanId,
            collateralAmountWithdraw > 0,
            borrowPaid,
            interestPaid,
            collateralAmountWithdraw
        );
    }

    function _adjustCollateral(
        uint256 loanId,
        uint256 nftId,
        uint256 collateralAdjustAmount,
        bool isAdd
    ) internal returns (Loan memory) {
        Loan storage loan = loans[nftId][loanId];
        require(
            loanExts[nftId][loanId].active == true,
            "CoreBorrowing/loan-is-closed"
        );

        _settleBorrowInterest(loan);

        LoanConfig storage loanConfig = loanConfigs[loan.borrowTokenAddress][
            loan.collateralTokenAddress
        ];

        if (isAdd) {
            loan.collateralAmount += collateralAdjustAmount;

            totalCollateralHold[
                loan.collateralTokenAddress
            ] += collateralAdjustAmount;
        } else {
            loan.collateralAmount -= collateralAdjustAmount;

            totalCollateralHold[
                loan.collateralTokenAddress
            ] -= collateralAdjustAmount;

            (uint256 rate, uint256 precision) = _queryRate(
                loan.collateralTokenAddress,
                loan.borrowTokenAddress
            );

            require(
                _isLoanLTVExceedTargetLTV(
                    loan.borrowAmount,
                    loan.collateralAmount,
                    MathUpgradeable.max(loan.interestOwed, loan.minInterest),
                    loanConfig.maxLTV +
                        IStakePool(IMembership(membershipAddress).currentPool())
                            .getMaxLTVBonus(nftId),
                    rate,
                    precision
                ) == false,
                "CoreBorrowing/loan-LTV-is-exceed-maxLTV"
            );
        }

        emit AdjustCollateral(
            msg.sender,
            nftId,
            loanId,
            isAdd,
            collateralAdjustAmount
        );
        return loan;
    }

    function _rollover(
        uint256 loanId,
        uint256 nftId,
        address caller
    ) internal returns (uint256 delayInterest, uint256 bountyReward) {
        Loan storage loan = loans[nftId][loanId];
        require(
            loanExts[nftId][loanId].active == true,
            "CoreBorrowing/loan-is-closed"
        );
        address bountyRewardTokenAddress;

        LoanConfig storage loanConfig = loanConfigs[loan.borrowTokenAddress][
            loan.collateralTokenAddress
        ];

        // This loan is overdue, the penalty is charged to loan's owner.
        if (block.timestamp > loan.rolloverTimestamp) {
            delayInterest =
                ((block.timestamp - loan.rolloverTimestamp) * loan.owedPerDay) /
                1 days;
            bountyReward =
                (delayInterest * loanConfig.bountyFeeRate) /
                WEI_PERCENT_UNIT;

            if (
                caller == _getTokenOwnership(nftId) ||
                poolToAsset[caller] != address(0)
            ) {
                // Caller is owner, collect delay interest to interestOwed
                loan.interestOwed += delayInterest + bountyReward;
                bountyRewardTokenAddress = loan.borrowTokenAddress;

                // Set bountyReward to zero since no bountyReward is for liquidator.
                bountyReward = 0;
            } else {
                // Caller is liquidator, bounty fee is sent to liquidator in form of collateral token equal to bountyFee
                bountyReward = IPriceFeed(priceFeedAddress).queryReturn(
                    loan.borrowTokenAddress,
                    loan.collateralTokenAddress,
                    bountyReward
                );

                loan.interestOwed += delayInterest;
                loan.collateralAmount -= bountyReward;
                bountyRewardTokenAddress = loan.collateralTokenAddress;
            }
        }
        address poolAddress = assetToPool[loan.borrowTokenAddress];
        PoolStat storage poolStat = poolStats[poolAddress];

        // Calculate new interest owed per day to this loan
        (uint256 interestRate, ) = IAPHPool(poolAddress).calculateInterest(0);
        uint256 interestOwedPerDay = (loan.borrowAmount * interestRate) /
            (WEI_PERCENT_UNIT * 365);

        loan.rolloverTimestamp = uint64(block.timestamp + loanDuration);

        poolStat.borrowInterestOwedPerDay =
            poolStat.borrowInterestOwedPerDay -
            loan.owedPerDay +
            interestOwedPerDay;

        loan.owedPerDay = interestOwedPerDay;
        loan.lastSettleTimestamp = uint64(block.timestamp);
        emit Rollover(
            _getTokenOwnership(nftId),
            nftId,
            loanId,
            caller,
            delayInterest,
            bountyReward,
            bountyRewardTokenAddress,
            interestOwedPerDay
        );
    }

    function _liquidate(
        uint256 loanId,
        uint256 nftId
    )
        internal
        returns (
            uint256 repayBorrow,
            uint256 repayInterest,
            uint256 bountyReward,
            uint256 leftOverCollateral
        )
    {
        Loan storage loan = loans[nftId][loanId];
        LoanConfig storage loanConfig = loanConfigs[loan.borrowTokenAddress][
            loan.collateralTokenAddress
        ];
        // rate, precision
        uint256[] memory numberArray = new uint256[](2);
        require(
            loanExts[nftId][loanId].active == true,
            "CoreBorrowing/loan-is-closed"
        );

        _settleBorrowInterest(loan);

        (numberArray[0], numberArray[1]) = _queryRate(
            loan.collateralTokenAddress,
            loan.borrowTokenAddress
        );

        // rollover if loan is overdue
        if (block.timestamp > loan.rolloverTimestamp) {
            (, bountyReward) = _rollover(loanId, nftId, msg.sender);
        }

        // liquidate
        if (
            _isLoanLTVExceedTargetLTV(
                loan.borrowAmount,
                loan.collateralAmount,
                MathUpgradeable.max(loan.interestOwed, loan.minInterest),
                loanConfig.liquidationLTV,
                numberArray[0],
                numberArray[1]
            )
        ) {
            // Loan is liquidatable
            uint256 leftoverBorrowToken;
            {
                // Swap all collateral token to borrow token to repay this loan
                (
                    uint256 collateralTokenAmountUsed,
                    uint256 borrowTokenAmountSwap
                ) = _liquidationSwap(loan);

                // Interest owed is deducted in case of swapped borrow token is insufficient for repaying borrow token
                if (
                    borrowTokenAmountSwap <
                    (loan.borrowAmount +
                        MathUpgradeable.max(
                            loan.interestOwed,
                            loan.minInterest
                        ))
                ) {
                    // exceedSwap is the amount of borrow token that insufficient for repaying
                    uint256 exceedSwap = (loan.borrowAmount +
                        MathUpgradeable.max(
                            loan.interestOwed,
                            loan.minInterest
                        )) - borrowTokenAmountSwap;

                    if (
                        exceedSwap >
                        MathUpgradeable.max(loan.interestOwed, loan.minInterest)
                    ) {
                        // In case that exceedSwap is more than max interest (cannot repay all principal)
                        loan.interestOwed = 0;
                        loan.minInterest = 0;
                    } else {
                        // In case that exceedSwap is equal or less than max interest (can repay all principal but not all interest)
                        // In this case, we repay interest partially
                        if (loan.interestOwed > loan.minInterest) {
                            loan.interestOwed = loan.interestOwed - exceedSwap;
                            loan.minInterest = 0;
                        } else {
                            loan.minInterest = loan.minInterest - exceedSwap;
                            loan.interestOwed = 0;
                        }
                    }
                }
                leftOverCollateral =
                    loan.collateralAmount -
                    collateralTokenAmountUsed;

                (repayBorrow, repayInterest, ) = _repay(
                    loanId,
                    nftId,
                    borrowTokenAmountSwap,
                    false
                );
                leftoverBorrowToken =
                    borrowTokenAmountSwap -
                    (repayBorrow + repayInterest);
            }

            // reduce variables use
            {
                address[] memory path_data = new address[](2);
                uint256[] memory amounts;
                if (leftoverBorrowToken > 0) {
                    //
                    path_data[0] = loan.borrowTokenAddress;
                    path_data[1] = loan.collateralTokenAddress;

                    // NOTE: must change amountOutMin to non-zero
                    amounts = IRouter(routerAddress).swapExactTokensForTokens(
                        leftoverBorrowToken, // amountIn
                        0, // amountOutMin
                        path_data,
                        address(this),
                        1 hours + block.timestamp
                    );
                    uint256 collateralAmountSwap = amounts[amounts.length - 1];
                    // Merge the swapped collateral with the leftOverCollateral
                    leftOverCollateral += collateralAmountSwap;
                }
            }

            if (loanExts[nftId][loanId].active == true) {
                // if loan is not fully repay, we manually set loan's status to close and add loss to borrowed pool
                IAPHPool(assetToPool[loan.borrowTokenAddress]).addLoss(
                    loan.borrowAmount
                );
                PoolStat storage poolStat = poolStats[
                    assetToPool[loan.borrowTokenAddress]
                ];
                poolStat.totalBorrowAmount -= loan.borrowAmount;
                poolStat.borrowInterestOwedPerDay -= loan.owedPerDay;
                loan.owedPerDay = 0;
                loan.borrowAmount = 0;
                loan.collateralAmount = 0;
                loanExts[nftId][loanId].active = false;
            } else {
                bountyReward +=
                    (leftOverCollateral * loanConfig.bountyFeeRate) /
                    WEI_PERCENT_UNIT;
                leftOverCollateral -=
                    (leftOverCollateral * loanConfig.bountyFeeRate) /
                    WEI_PERCENT_UNIT;
            }

            emit Liquidate(
                _getTokenOwnership(nftId),
                nftId,
                loanId,
                msg.sender,
                numberArray[0],
                numberArray[1],
                bountyReward,
                loan.collateralTokenAddress,
                leftOverCollateral
            );
        }
    }

    function _liquidationSwap(
        Loan storage loan
    )
        internal
        returns (
            uint256 collateralTokenAmountUsed,
            uint256 borrowTokenAmountSwap
        )
    {
        address[] memory path_data = new address[](2);
        path_data[0] = loan.collateralTokenAddress;
        path_data[1] = loan.borrowTokenAddress;
        uint256[] memory amounts;
        uint256 maxSwapAmount = IPriceFeed(priceFeedAddress).queryReturn(
            loan.collateralTokenAddress,
            loan.borrowTokenAddress,
            loan.collateralAmount
        );

        if (
            maxSwapAmount >
            (((loan.borrowAmount +
                MathUpgradeable.max(loan.interestOwed, loan.minInterest)) *
                (WEI_PERCENT_UNIT + fixSlippage)) / WEI_PERCENT_UNIT)
        ) {
            maxSwapAmount =
                loan.borrowAmount +
                MathUpgradeable.max(loan.interestOwed, loan.minInterest);
            // Normal condition, leftover collateral is exists
            amounts = IRouter(routerAddress).swapTokensForExactTokens(
                maxSwapAmount, // amountOut
                loan.collateralAmount, // amountInMax
                path_data,
                address(this),
                1 hours + block.timestamp
            );
        } else {
            amounts = IRouter(routerAddress).swapExactTokensForTokens(
                loan.collateralAmount, // // amountIn
                (maxSwapAmount * (WEI_PERCENT_UNIT - fixSlippage)) /
                    WEI_PERCENT_UNIT, // // amountOutMin
                path_data,
                address(this),
                1 hours + block.timestamp
            );
        }
        collateralTokenAmountUsed = amounts[0];
        borrowTokenAmountSwap = amounts[amounts.length - 1];
    }

    /**
      @dev Settle interest of the given loan, by calulating time form last settle to now in days
            and multiply by interest owedPerDay
     */
    function _settleBorrowInterest(Loan storage loan) internal {
        uint256 ts = uint256(block.timestamp);
        if (loan.lastSettleTimestamp < ts) {
            uint64 settleTimestamp = uint64(
                MathUpgradeable.min(ts, loan.rolloverTimestamp)
            );
            uint256 interestOwed = ((settleTimestamp -
                loan.lastSettleTimestamp) * loan.owedPerDay) / 1 days;
            loan.interestOwed += interestOwed;
            loan.lastSettleTimestamp = settleTimestamp;
        }
    }
}
