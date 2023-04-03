// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

contract PoolSettingEvent {
    event SetBorrowInterestParams(
        address indexed sender,
        uint256[] rates,
        uint256[] utils,
        uint256 targetSupply
    );

    event SetLoanConfig(
        address indexed sender,
        address collateralTokenAddress,
        uint256 safeLTV,
        uint256 maxLTV,
        uint256 liqLTV,
        uint256 bountyFeeRate
    );

    event SetPoolLendingAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );

    event SetPoolBorrowingAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );

    event SetMembershipAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );

    event Initialize(
        address indexed caller,
        address indexed coreAddress,
        address interestVaultAddress,
        address membershipAddress,
        address tokenAddress
    );

    event SetWETHHandler(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetForwAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetBlockTime(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );
}
