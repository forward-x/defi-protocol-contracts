// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

contract InterestVaultEvent {
    event SetTokenAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetForwAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetProtocolAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );

    event OwnerApprove(
        address indexed sender,
        address tokenAddress,
        address forwAddress,
        uint256 tokenAmount,
        uint256 forwAmount,
        address pool
    );

    event SettleInterest(
        address indexed sender,
        uint256 claimableTokenInterest,
        uint256 heldTokenInterest,
        uint256 claimableForwInterest
    );

    event WithdrawTokenInterest(
        address indexed sender,
        uint256 claimable,
        uint256 bonus,
        uint256 profit
    );

    event WithdrawForwInterest(address indexed sender, uint256 claimable);

    event WithdrawActualProfit(address indexed sender, uint256 profitWithdraw);
}
