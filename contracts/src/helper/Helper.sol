// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./HelperBase.sol";
import "../../externalContract/openzeppelin/non-upgradeable/Math.sol";

contract Helper is HelperBase {
    constructor(address _coreAddress) HelperBase(_coreAddress) {}

    function getInterestGained(
        address poolAddress,
        uint256 nftId
    ) external view returns (uint256 tokenInterest, uint256 forwInterest) {
        if (IAPHCore(aphCoreAddress).poolToAsset(poolAddress) != address(0)) {
            (tokenInterest, forwInterest) = IAPHPool(poolAddress)
                .claimableInterest(nftId);
        }
    }

    function getInterestAmountByDepositAmount(
        address poolAddress,
        uint256 depositAmount,
        uint256 daySecond
    ) external view returns (uint256 interestAmount) {
        if (IAPHCore(aphCoreAddress).poolToAsset(poolAddress) != address(0)) {
            uint256 interestRate = IAPHPool(poolAddress).getNextLendingInterest(
                0
            );
            interestAmount = ((depositAmount * interestRate * daySecond) /
                (WEI_PERCENT_UNIT * 365 * 86400));
        }
    }

    function getDepositAmountByInterestAmount(
        address poolAddress,
        uint256 interestAmount,
        uint256 daySecond
    ) external view returns (uint256 depositAmount) {
        if (IAPHCore(aphCoreAddress).poolToAsset(poolAddress) != address(0)) {
            uint256 interestRate = IAPHPool(poolAddress).getNextLendingInterest(
                0
            );
            depositAmount =
                (interestAmount * WEI_PERCENT_UNIT * 365 * 86400) /
                (interestRate * daySecond);
        }
    }

    function getActiveLoans(
        uint256 nftId,
        uint256 cursor,
        uint256 resultsPerPage
    )
        external
        view
        returns (
            CoreBase.Loan[] memory activeLoans,
            ActiveLoanInfo[] memory activeLoanInfos,
            uint256 newCursor
        )
    {
        IAPHCore iAPHCore = IAPHCore(aphCoreAddress);
        uint256 loanLength = iAPHCore.currentLoanIndex(nftId);
        require(cursor > 0, "APHCore/cursor-must-be-greater-than-zero");
        require(resultsPerPage > 0, "resultsPerPage-cannot-be-zero");

        uint256 index;
        uint256 count;
        for (
            index = cursor;
            index <= loanLength && count < resultsPerPage;
            index++
        ) {
            if (iAPHCore.getLoanExt(nftId, index).active) {
                count++;
            }
        }

        if (count == 0) {
            activeLoans = new CoreBase.Loan[](1);
            activeLoanInfos = new ActiveLoanInfo[](1);
            return (activeLoans, activeLoanInfos, index);
        }

        activeLoans = new CoreBase.Loan[](count);
        activeLoanInfos = new ActiveLoanInfo[](count);

        count = 0;
        for (
            index = cursor;
            index <= loanLength && count < resultsPerPage;
            index++
        ) {
            if (iAPHCore.getLoanExt(nftId, index).active) {
                activeLoans[count] = iAPHCore.getLoan(nftId, index);

                uint256 totalInterest = activeLoans[count].interestOwed +
                    ((block.timestamp -
                        activeLoans[count].lastSettleTimestamp) *
                        activeLoans[count].owedPerDay) /
                    1 days;

                activeLoans[count].interestOwed = totalInterest;

                activeLoanInfos[count].actualInterestOwed = Math.max(
                    activeLoans[count].minInterest,
                    totalInterest
                );

                activeLoanInfos[count].id = index;

                activeLoanInfos[count].currentLTV = iAPHCore.getLoanCurrentLTV(
                    index,
                    nftId
                );

                activeLoanInfos[count].liquidationLTV = iAPHCore
                    .getLoanConfig(
                        activeLoans[count].borrowTokenAddress,
                        activeLoans[count].collateralTokenAddress
                    )
                    .liquidationLTV;

                if (activeLoans[count].borrowAmount != 0) {
                    activeLoanInfos[count].apr =
                        (activeLoans[count].owedPerDay *
                            365 *
                            WEI_PERCENT_UNIT) /
                        activeLoans[count].borrowAmount;
                }

                count++;
            }
        }
        return (activeLoans, activeLoanInfos, index);
    }

    function calculateBorrowingInterest(
        address poolAddress,
        uint256 daySecond,
        uint256 borrowingAmount,
        uint256 collateralAmount,
        address collateralTokenAddress
    ) external view returns (uint256 ltv, uint256 interest) {
        IAPHCore iAPHCore = IAPHCore(aphCoreAddress);
        address borrowTokenAddress = iAPHCore.poolToAsset(poolAddress);

        require(
            borrowTokenAddress != address(0),
            "Helper/invalid-pool-address"
        );

        uint256 interestRate = IAPHPool(poolAddress).getNextBorrowingInterest(
            0
        );

        interest = ((borrowingAmount * interestRate * daySecond) /
            (WEI_PERCENT_UNIT * 365 * 86400));

        (uint256 rate, uint256 precision) = IPriceFeed(
            iAPHCore.priceFeedAddress()
        ).queryRate(collateralTokenAddress, borrowTokenAddress);

        ltv =
            ((borrowingAmount + interest) * WEI_PERCENT_UNIT * precision) /
            (collateralAmount * rate);
    }

    function getLoanCollateralInfo(
        uint256 nftId,
        uint256 loanId
    )
        public
        view
        returns (uint256 minimumCollateral, uint256 removableCollateral)
    {
        IAPHCore iAPHCore = IAPHCore(aphCoreAddress);

        CoreBase.Loan memory loan = iAPHCore.loans(nftId, loanId);
        CoreBase.LoanConfig memory loanConfig = iAPHCore.loanConfigs(
            loan.borrowTokenAddress,
            loan.collateralTokenAddress
        );

        (
            uint256 settledBorrowAmount,
            ,
            uint256 rate,
            uint256 precision
        ) = _getSettleBorrowInfo(iAPHCore, loan);

        IMembership membership = IMembership(
            IAPHCore(aphCoreAddress).membershipAddress()
        );
        IStakePool stakePool = IStakePool(membership.currentPool());
        uint8 rank = membership.getRank(nftId);
        StakePoolBase.RankInfo memory rankInfo = stakePool.rankInfos(rank);

        minimumCollateral =
            (settledBorrowAmount * WEI_PERCENT_UNIT * precision) /
            ((loanConfig.maxLTV + rankInfo.maxLTVBonus - WEI_UNIT) * rate);
        if (loan.collateralAmount > minimumCollateral) {
            removableCollateral = loan.collateralAmount - minimumCollateral;
        }
    }

    function getLoanBorrowAmount(
        uint256 nftId,
        uint256 loanId
    ) public view returns (uint256 maximumBorrowAmount) {
        IAPHCore iAPHCore = IAPHCore(aphCoreAddress);

        CoreBase.Loan memory loan = iAPHCore.loans(nftId, loanId);
        CoreBase.LoanConfig memory loanConfig = iAPHCore.loanConfigs(
            loan.borrowTokenAddress,
            loan.collateralTokenAddress
        );

        (
            ,
            uint256 settledLTV,
            uint256 rate,
            uint256 precision
        ) = _getSettleBorrowInfo(iAPHCore, loan);

        IMembership membership = IMembership(
            IAPHCore(aphCoreAddress).membershipAddress()
        );
        IStakePool stakePool = IStakePool(membership.currentPool());
        uint8 rank = membership.getRank(nftId);
        StakePoolBase.RankInfo memory rankInfo = stakePool.rankInfos(rank);

        if (loanConfig.maxLTV > settledLTV) {
            maximumBorrowAmount =
                ((Math.max(
                    loanConfig.maxLTV + rankInfo.maxLTVBonus - settledLTV,
                    WEI_UNIT
                ) - WEI_UNIT) *
                    loan.collateralAmount *
                    rate) /
                (WEI_PERCENT_UNIT * precision);
        }
    }

    function getSettleBorrowInfo(
        uint256 nftId,
        uint256 loanId
    ) public view returns (uint256, uint256, uint256, uint256) {
        IAPHCore iAPHCore = IAPHCore(aphCoreAddress);
        CoreBase.Loan memory loan = iAPHCore.loans(nftId, loanId);
        return _getSettleBorrowInfo(iAPHCore, loan);
    }

    function _getSettleBorrowInfo(
        IAPHCore iAPHCore,
        CoreBase.Loan memory loan
    )
        private
        view
        returns (
            uint256 settledBorrowAmount,
            uint256 settledLTV,
            uint256 rate,
            uint256 precision
        )
    {
        (rate, precision) = IPriceFeed(iAPHCore.priceFeedAddress()).queryRate(
            loan.collateralTokenAddress,
            loan.borrowTokenAddress
        );

        // calculate 1 day interest forward
        settledBorrowAmount =
            loan.borrowAmount +
            Math.max(
                loan.minInterest,
                loan.interestOwed +
                    (((block.timestamp - loan.lastSettleTimestamp) *
                        loan.owedPerDay) / 1 days)
            );
        // divide by zero if loan is closed
        settledLTV =
            (settledBorrowAmount * WEI_PERCENT_UNIT * precision) /
            (loan.collateralAmount * rate);
    }

    function getStakePoolNextSettleTimeStamp(
        address stakePoolAddress
    ) public view returns (uint256) {
        uint256 poolNextSettle = block.timestamp -
            ((block.timestamp -
                IStakePool(stakePoolAddress).poolStartTimestamp()) %
                IStakePool(stakePoolAddress).settleInterval()) +
            IStakePool(stakePoolAddress).settleInterval();
        return poolNextSettle;
    }

    function getPoolInfo(
        address poolAddress,
        uint256 forwPrice,
        uint256 forwPrecision
    )
        public
        view
        returns (
            uint256 borrowingInterest,
            uint256 lendingTokenInterest,
            uint256 lendingForwInterest,
            uint256 utilizationRate,
            uint256 pTokenTotalSupply,
            uint256 currentSupply
        )
    {
        IAPHPool pool = IAPHPool(poolAddress);

        borrowingInterest = pool.getNextBorrowingInterest(0);
        lendingTokenInterest = pool.getNextLendingInterest(0);
        lendingForwInterest = pool.getNextLendingForwInterest(
            0,
            forwPrice,
            forwPrecision
        );
        utilizationRate = pool.utilizationRate();
        pTokenTotalSupply = pool.pTokenTotalSupply();
        currentSupply = pool.currentSupply();
    }

    function getLendingInfo(
        address poolAddress,
        uint256 nftId
    )
        public
        view
        returns (
            uint256 lendingBalance,
            uint256 interestTokenGained,
            uint256 interestForwGained,
            uint8 rank,
            StakePoolBase.RankInfo memory rankInfo
        )
    {
        IAPHPool pool = IAPHPool(poolAddress);
        IMembership membership = IMembership(pool.membershipAddress());
        IStakePool stakepool = IStakePool(membership.currentPool());

        lendingBalance = pool.balancePTokenOf(nftId);
        (interestTokenGained, interestForwGained) = pool.claimableInterest(
            nftId
        );
        // rank = membership.getRank(nftId);
        (rank, ) = pool.lenders(nftId);
        rankInfo = stakepool.rankInfos(rank);
    }

    function getNFTList(
        address owner
    ) public view returns (uint256 count, uint256[] memory nftList) {
        IMembership membership = IMembership(
            IAPHCore(aphCoreAddress).membershipAddress()
        );

        count = membership.balanceOf(owner);

        nftList = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            nftList[i] = membership.tokenOfOwnerByIndex(owner, i);
        }
    }

    function getRankInfoList()
        public
        view
        returns (StakePoolBase.RankInfo[] memory rankInfos)
    {
        IMembership membership = IMembership(
            IAPHCore(aphCoreAddress).membershipAddress()
        );
        IStakePool stakePool = IStakePool(membership.currentPool());

        uint256 rankLen = stakePool.rankLen();

        rankInfos = new StakePoolBase.RankInfo[](rankLen);

        for (uint8 i = 0; i < rankLen; i++) {
            rankInfos[i] = stakePool.rankInfos(i);
        }
    }

    function getStakeInfo(
        uint256 nftId
    ) public view returns (StakePoolBase.StakeInfo memory stakeInfo) {
        IMembership membership = IMembership(
            IAPHCore(aphCoreAddress).membershipAddress()
        );
        IStakePool stakePool = IStakePool(membership.currentPool());

        stakeInfo = stakePool.getStakeInfo(nftId);

        uint256 settleInterval = stakePool.settleInterval();
        uint256 settlePeriod = stakePool.settlePeriod();
        uint256 poolLastSettleTimestamp = block.timestamp -
            ((block.timestamp - uint256(stakePool.poolStartTimestamp())) %
                settleInterval);

        if (stakeInfo.stakeBalance != 0) {
            uint256 I = Math.min(
                uint256(
                    (poolLastSettleTimestamp - stakeInfo.lastSettleTimestamp) /
                        uint256(settleInterval)
                ),
                settlePeriod
            );
            if (I != 0) {
                for (uint256 index = 0; index < I; index++) {
                    stakeInfo.claimableAmount += stakeInfo.payPattern[index];
                    stakeInfo.payPattern[index] = 0;
                }
            }

            for (uint256 i = 0; i < I; i++) {
                for (uint256 x = 0; x < stakeInfo.payPattern.length - 1; x++) {
                    stakeInfo.payPattern[x] = stakeInfo.payPattern[x + 1];
                }
                delete stakeInfo.payPattern[stakeInfo.payPattern.length - 1];
            }
        }
    }
}
