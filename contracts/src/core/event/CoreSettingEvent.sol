// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

contract CoreSettingEvent {
    event SetMembershipAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetPriceFeedAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetRouterAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetCoreBorrowingAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetFeeController(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetForwDistributorAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetWETHHandler(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event SetFixSlippage(
        address indexed owner,
        uint256 oldValue,
        uint256 newValue
    );

    event SetLoanDuration(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );
    event SetAdvancedInterestDuration(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );
    event SetFeeSpread(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    event RegisterNewPool(address indexed sender, address poolAddress);
    event SetupLoanConfig(
        address indexed sender,
        address indexed borrowTokenAddress,
        address indexed collateralTokenAddress,
        uint256 oldSafeLTV,
        uint256 oldMaxLTV,
        uint256 oldLiquidationLTV,
        uint256 oldBountyFeeRate,
        uint256 newSafeLTV,
        uint256 newMaxLTV,
        uint256 newLiquidationLTV,
        uint256 newBountyFeeRate
    );
    event SetForwPerBlock(
        address indexed sender,
        uint256 amount,
        uint256 targetBlock
    );
    event ApprovedForRouter(
        address indexed sender,
        address asset,
        address router
    );

    event SetForwAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
}
