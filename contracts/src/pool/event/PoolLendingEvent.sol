// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

contract PoolLendingEvent {
    event Deposit(
        address indexed owner,
        uint256 indexed nftId,
        uint256 depositAmount,
        uint256 mintedP,
        uint256 mintedAtp,
        uint256 mintedItp,
        uint256 mintedIfp
    );
    event Withdraw(
        address indexed owner,
        uint256 indexed nftId,
        uint256 withdrawAmount,
        uint256 burnedP,
        uint256 burnedAtp,
        uint256 burnedLoss,
        uint256 burnedItp,
        uint256 burnedIfp
    );
    event ClaimTokenInterest(
        address indexed owner,
        uint256 indexed nftId,
        uint256 interestTokenClaimed,
        uint256 interestTokenBonus,
        uint256 burnedItp
    );
    event ClaimForwInterest(
        address indexed owner,
        uint256 indexed nftId,
        uint256 interestForwClaimed,
        uint256 interestForwBonus,
        uint256 burnedIfp
    );
    event ActivateRank(
        address indexed owner,
        uint256 indexed nftId,
        uint8 oldRank,
        uint8 newRank
    );
}
