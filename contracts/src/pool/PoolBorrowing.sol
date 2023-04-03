// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./PoolBaseFunc.sol";
import "./event/PoolBorrowingEvent.sol";

contract PoolBorrowing is PoolBaseFunc, PoolBorrowingEvent {
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
        uint256 collateralSentAmount,
        address collateralTokenAddress
    )
        external
        payable
        nonReentrant
        whenFuncNotPaused(msg.sig)
        returns (CoreBase.Loan memory)
    {
        require(
            collateralTokenAddress == wethAddress || msg.value == 0,
            "PoolBorrowing/no-support-transfering-ether-in"
        );
        nftId = _getUsableToken(msg.sender, nftId);

        if (collateralSentAmount != 0) {
            _transferFromIn(
                msg.sender,
                coreAddress,
                collateralTokenAddress,
                collateralSentAmount
            );
        }
        CoreBase.Loan memory loan = _borrow(
            loanId,
            nftId,
            borrowAmount,
            collateralSentAmount,
            collateralTokenAddress
        );
        _transferOut(msg.sender, tokenAddress, borrowAmount);
        return loan;
    }

    function addLoss(uint256 amount) external {
        require(msg.sender == coreAddress, "PoolBorrowing/caller-is-not-core");
        loss += amount;
        emit AddLoss(msg.sender, amount);
    }

    // internal function
    function _borrow(
        uint256 loanId,
        uint256 nftId,
        uint256 borrowAmount,
        uint256 collateralSentAmount,
        address collateralTokenAddress
    ) internal returns (CoreBase.Loan memory) {
        require(
            loanId != 0 || collateralSentAmount > 0,
            "PoolBorrowing/new-loan-must-provide-collateral"
        );
        require(
            borrowAmount > 0 && _currentSupply() >= borrowAmount,
            "PoolBorrowing/pool-supply-sufficient-for-borrowing"
        );
        require(
            tokenAddress != collateralTokenAddress,
            "PoolBorrowing/collateral-token-is-same-as-borrow-token"
        );

        (
            uint256 interestRate,
            uint256 interestOwedPerDay
        ) = _calculateBorrowInterest(borrowAmount);

        return
            IAPHCore(coreAddress).borrow(
                loanId,
                nftId,
                borrowAmount,
                tokenAddress,
                collateralSentAmount,
                collateralTokenAddress,
                interestOwedPerDay,
                interestRate
            );
    }

    // function _futureTrade(
    //     uint256 nftId,
    //     uint256 collateralSentAmount,
    //     address collateralTokenAddress,
    //     address swapTokenAddress,
    //     uint256 leverage,
    //     uint256 maxSlippage
    // ) internal returns (CoreBase.Position memory a, bool) {
    //     require(
    //         collateralTokenAddress != address(0) && swapTokenAddress != address(0),
    //         "Error: address 0"
    //     );
    //     // already checked
    //     // require(collateralSentAmount > 0, "Error: colla = 0");
    //     require(leverage >= 1 ether, "Error: ");
    //     require(maxSlippage >= 0.25 ether && maxSlippage <= 40 ether, "Error: maxSlippage");

    //     uint256 borrowAmount;
    //     uint256 interestRate;
    //     uint256 interestOwedPerDay;
    //     bool isLong;

    //     // long position
    //     if (tokenAddress == collateralTokenAddress) {
    //         isLong = true;
    //         borrowAmount = (collateralSentAmount * (leverage - WEI_UNIT)) / WEI_UNIT;
    //         // IAPHCore(coreAddress).futureTrade
    //     } else {
    //         isLong = false;
    //         borrowAmount = collateralSentAmount * leverage;
    //         // IAPHCore(coreAddress).futureTrade
    //     }
    //     (interestRate, interestOwedPerDay) = _calculateBorrowInterest(borrowAmount);

    //     return (a, isLong);
    // }
}
