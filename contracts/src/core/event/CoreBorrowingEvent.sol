// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

contract CoreBorrowingEvent {
    event Borrow(
        address indexed owner,
        uint256 indexed nftId,
        uint256 indexed loanId,
        address borrowTokenAddress,
        address collateralTokenAddress,
        uint256 borrowAmount,
        uint256 collateralAmount,
        uint256 owedPerDay,
        uint256 minInterest,
        uint8 newLoan,
        uint64 rolloverTimestamp
    );

    event Repay(
        address indexed owner,
        uint256 indexed nftId,
        uint256 indexed loanId,
        bool closeLoan,
        uint256 borrowPaid,
        uint256 interestPaid,
        uint256 collateralAmountWithdraw
    );

    event AdjustCollateral(
        address indexed owner,
        uint256 indexed nftId,
        uint256 indexed loanId,
        bool isAdd,
        uint256 collateralAdjustAmount
    );

    event Rollover(
        address indexed owner,
        uint256 indexed nftId,
        uint256 indexed loanId,
        address bountyHunter,
        uint256 delayInterest,
        uint256 bountyReward,
        address bountyRewardTokenAddress,
        uint256 newInterestOwedPerDay
    );

    event Liquidate(
        address indexed owner,
        uint256 indexed nftId,
        uint256 indexed loanId,
        address liquidator,
        uint256 swapPrice,
        uint256 swapPrecision,
        uint256 bountyReward,
        address bountyRewardTokenAddress,
        uint256 tokenSentBackToUser
    );
}
