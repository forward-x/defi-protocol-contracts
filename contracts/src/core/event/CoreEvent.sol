// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

contract CoreEvent {
    event SettleForwInterest(
        address indexed coreAddress,
        address indexed interestVaultAddress,
        address forwDistributionAddress,
        address forwTokenAddress,
        uint256 amount
    );
    event AddLossInUSD(
        address indexed coreAddress,
        address indexed poolAddress,
        uint256 nftId,
        uint256 amount
    );
}
