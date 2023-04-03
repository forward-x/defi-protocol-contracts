// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../src/core/CoreBase.sol";

interface IAPHCore {
    function settleForwInterest() external;

    function addLossInUSD(uint256 nftId, uint256 lossAmount) external;

    function settleBorrowInterest(uint256 loanId, uint256 nftId) external;

    // External functions
    function getLoan(uint256 nftId, uint256 loanId) external view returns (CoreBase.Loan memory);

    function getLoanExt(uint256 nftId, uint256 loanId)
        external
        view
        returns (CoreBase.LoanExt memory);

    function isPool(address poolAddess) external view returns (bool);

    function getLoanConfig(address _borrowTokenAddress, address _collateralTokenAddress)
        external
        view
        returns (CoreBase.LoanConfig memory);

    function getActiveLoans(
        uint256 nftId,
        uint256 cursor,
        uint256 resultPerPage
    ) external view returns (CoreBase.Loan[] memory activaLoans, uint256 newCursor);

    function getPoolList() external view returns (address[] memory);

    function borrow(
        uint256 loanId,
        uint256 nftId,
        uint256 borrowAmount,
        address borrowTokenAddress,
        uint256 collateralSentAmount,
        address collateralTokenAddress,
        uint256 newOwedPerDay,
        uint256 interestRate
    ) external returns (CoreBase.Loan memory);

    function repay(
        uint256 loanId,
        uint256 nftId,
        uint256 repayAmount,
        bool isOnlyInterest
    ) external payable returns (uint256, uint256);

    function adjustCollateral(
        uint256 loanId,
        uint256 nftId,
        uint256 collateralAdjustAmount,
        bool isAdd
    ) external payable returns (CoreBase.Loan memory);

    function rollover(uint256 loanId, uint256 nftId) external returns (uint256, uint256);

    function liquidate(uint256 loanId, uint256 nftId)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    // function futureTrade(
    //     uint256 nftId,
    //     uint256 collateralSentAmount,
    //     address collateralTokenAddress,
    //     uint256 borrowAmount,
    //     address borrowTokenAddress,
    //     address swapTokenAddress,
    //     uint256 leverage,
    //     uint256 maxSlippage,
    //     bool isLong,
    //     uint256 newOwedPerDay
    // ) external returns (CoreBase.Position memory);

    // Getter functions
    function getLoanCurrentLTV(uint256 loanId, uint256 nftId) external view returns (uint256);

    function feeSpread() external view returns (uint256);

    function loanDuration() external view returns (uint256);

    function advancedInterestDuration() external view returns (uint256);

    function totalCollateralHold(address) external view returns (uint256);

    function poolStats(address) external view returns (CoreBase.PoolStat memory);

    function swapableToken(address) external view returns (bool);

    function poolToAsset(address) external view returns (address);

    function assetToPool(address) external view returns (address);

    function poolList(uint256) external view returns (address);

    function feesController() external view returns (address);

    function priceFeedAddress() external view returns (address);

    function routerAddress() external view returns (address);

    function forwDistributorAddress() external view returns (address);

    function membershipAddress() external view returns (address);

    function loans(uint256, uint256) external view returns (CoreBase.Loan memory);

    function loanExts(uint256, uint256) external view returns (CoreBase.LoanExt memory);

    function currentLoanIndex(uint256) external view returns (uint256);

    function loanConfigs(address, address) external view returns (CoreBase.LoanConfig memory);

    function forwDisPerBlock(address) external view returns (uint256);

    function lastSettleForw(address) external view returns (uint256);

    function fixSlippage() external view returns (uint256);

    function nftsLossInUSD(uint256 nftId) external view returns (uint256);

    function totalLossInUSD() external view returns (uint256);
}
