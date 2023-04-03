// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../src/pool/PoolBase.sol";
import "../src/core/CoreBase.sol";

interface IAPHPool {
    /**
     * @dev Deposit the asset token to the pool
     * @param nftId The nft tokenId that is holding the user's lending position
     * @param depositAmount The amount of token that are being transfered
     * @return mintedP The 'amount' of pToken (principal) minted
     * @return mintedItp The 'amount' of itpToken (asset token interest) minted
     * @return mintedIfp The 'amount' of ifpToken (Forward token interest) minted
     */
    function deposit(uint256 nftId, uint256 depositAmount)
        external
        payable
        returns (
            uint256 mintedP,
            uint256 mintedItp,
            uint256 mintedIfp
        );

    /**
     * @dev Withdraw the 'amount' of the principal (and claim all interest if user withdraw all of the principal)
     * @param nftId The nft tokenId that is holding the user's lending position
     * @param withdrawAmount The 'amount' of token that are being withdraw
     * @return The 'amount' of all tokens is withdraw and burnt
     */
    function withdraw(uint256 nftId, uint256 withdrawAmount)
        external
        returns (PoolBase.WithdrawResult memory);

    /**
     * @dev Claim the entire remaining of both asset token and Forward interest
     * @param nftId The nft tokenId that is holding the user's lending position
     * @return The 'amount' of all tokens is claimed and burnt
     */
    function claimAllInterest(uint256 nftId) external returns (PoolBase.WithdrawResult memory);

    /**
     * @dev Claim the 'amount' of Forward token interest
     * @param nftId The nft TokenId that is holding the user's lending position
     * @param claimAmount The 'amount' of asset token interest that are being claimed
     * @return The 'amount' of asset token interest is claimed and burnt
     */
    function claimTokenInterest(uint256 nftId, uint256 claimAmount)
        external
        returns (PoolBase.WithdrawResult memory);

    /**
     * @dev Claim the 'amount' of asset token interest
     * @param nftId The nft tokenId that is holding the user's lending position
     * @param claimAmount The 'amount' of Forward token interest that are being claimed
     * @return The 'amount' of Forward token interest is claimed and burnt
     */
    function claimForwInterest(uint256 nftId, uint256 claimAmount)
        external
        returns (PoolBase.WithdrawResult memory);

    function borrow(
        uint256 loanId,
        uint256 nftId,
        uint256 borrowAmount,
        uint256 collateralSentAmount,
        address collateralTokenAddress
    ) external payable returns (CoreBase.Loan memory);

    // function futureTrade(
    //     uint256 nftId,
    //     uint256 collateralSentAmount,
    //     address collateralTokenAddress,
    //     address swapTokenAddress,
    //     uint256 leverage,
    //     uint256 maxSlippage
    // ) external payable returns (CoreBase.Position memory);

    /**
     * @dev Set the rank in APHPool to equal the user's NFT rank
     * @param nftId The user's nft tokenId is used to activate the new rank
     * @return The new rank from user's nft
     */
    function activateRank(uint256 nftId) external returns (uint8);

    function getNextLendingInterest(uint256 depositAmount) external view returns (uint256);

    function getNextLendingForwInterest(
        uint256 depositAmount,
        uint256 forwPriceRate,
        uint256 forwPricePrecision
    ) external view returns (uint256);

    function getNextBorrowingInterest(uint256 borrowAmount) external view returns (uint256);

    /**
     * @dev Get interestRate and interestOwedPerDay from new borrow amount
     * @param borrowAmount The 'amount' of token borrow
     * @return The interestRate and interestOwedPerDay
     */
    function calculateInterest(uint256 borrowAmount) external view returns (uint256, uint256);

    /**
     * @dev Get asset interest token (itpToken) price
     * @return interest token price (pToken per itpToken)
     */
    function getInterestTokenPrice() external view returns (uint256);

    /**
     * @dev Get Forward interest token (ifpToken) price
     * @return Forward interest token price (pToken per ifpToken)
     */
    function getInterestForwPrice() external view returns (uint256);

    function getActualTokenPrice() external view returns (uint256);

    /**
     * @dev Get current supply of the asset token in the pool
     * @return The 'amount' of asset token in the pool
     */
    function currentSupply() external view returns (uint256);

    function utilizationRate() external view returns (uint256);

    function membershipAddress() external view returns (address);

    function interestVaultAddress() external view returns (address);

    function forwAddress() external view returns (address);

    function tokenAddress() external view returns (address);

    function stakePoolAddress() external view returns (address);

    function coreAddress() external view returns (address);

    function utils(uint256) external view returns (uint256);

    function rates(uint256) external view returns (uint256);

    function utilsLen() external view returns (uint256);

    function targetSupply() external view returns (uint256);

    // from PoolToken
    function balancePTokenOf(uint256 NFTId) external view returns (uint256);

    function balanceItpTokenOf(uint256 NFTId) external view returns (uint256);

    function balanceIfpTokenOf(uint256 NFTId) external view returns (uint256);

    function balanceAtpTokenOf(uint256 NFTId) external view returns (uint256);

    function pTokenTotalSupply() external view returns (uint256);

    function itpTokenTotalSupply() external view returns (uint256);

    function ifpTokenTotalSupply() external view returns (uint256);

    function atpTokenTotalSupply() external view returns (uint256);

    function lenders(uint256 NFTId) external view returns (uint8, uint64);

    function claimableInterest(uint256 nftId)
        external
        view
        returns (uint256 tokenInterest, uint256 forwInterest);

    function addLoss(uint256 amount) external;

    function loss() external view returns (uint256);
}
