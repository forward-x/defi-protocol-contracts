// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../src/helper/HelperBase.sol";
import "../src/pool/PoolBase.sol";
import "../src/core/CoreBase.sol";

interface IHelper {
    function getInterestGained(address poolAddress, uint256 nftId)
        external
        view
        returns (uint256 tokenInterest, uint256 forwInterest);

    function getInterestAmountByDepositAmount(
        address poolAddress,
        uint256 depositAmount,
        uint256 daySecond
    ) external view returns (uint256 interestAmount);

    function getDepositAmountByInterestAmount(
        address poolAddress,
        uint256 interestAmount,
        uint256 daySecond
    ) external view returns (uint256 depositAmount);

    function getActiveLoans(
        uint256 nftId,
        uint256 cursor,
        uint256 resultsPerPage
    )
        external
        view
        returns (
            CoreBase.Loan[] memory activeLoans,
            HelperBase.ActiveLoanInfo[] memory activeLoanInfos,
            uint256 newCursor
        );

    function calculateBorrowingInterest(
        address poolAddress,
        uint256 daySecond,
        uint256 borrowingAmount,
        uint256 collateralAmount,
        address collateralTokenAddress
    ) external view returns (uint256 ltv, uint256 interest);

    function getLoanCollateralInfo(uint256 nftId, uint256 loanId)
        external
        view
        returns (uint256 minimumCollateral, uint256 removableCollateral);

    function getLoanBorrowAmount(uint256 nftId, uint256 loanId)
        external
        view
        returns (uint256 maximumBorrowAmount);

    function getPoolInfo(address poolAddress, uint256 forwPrice, uint256 forwPrecision)
        external
        view
        returns (
            uint256 borrowingInterest,
            uint256 lendingTokenInterest,
            uint256 lendingForwInterest,
            uint256 utilizationRate,
            uint256 pTokenTotalSupply,
            uint256 currentSupply
        );

    function getLendingInfo(address poolAddress, uint256 nftId)
        external
        view
        returns (
            uint256 lendingBalance,
            uint256 interestTokenGained,
            uint256 interestForwGained,
            uint8 rank,
            StakePoolBase.RankInfo memory rankInfo
        );

    function getNFTList(address owner)
        external
        view
        returns (uint256 count, uint256[] memory nftList);

    function getRankInfoList() external view returns (StakePoolBase.RankInfo[] memory rankInfos);

    function getStakeInfo(uint256 nftId)
        external
        view
        returns (StakePoolBase.StakeInfo memory stakeInfo);
}
