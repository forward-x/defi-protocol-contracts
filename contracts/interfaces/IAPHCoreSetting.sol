// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

interface IAPHCoreSetting {
    // External functions

    function setupLoanConfig(
        address borrowTokenAddress,
        address collateralTokenAddress,
        uint256 newSafeLTV,
        uint256 newMaxLTV,
        uint256 newLiquidationLTV,
        uint256 newBountyFeeRate
    ) external;

    function setMembershipAddress(address _address) external;

    function setPriceFeedAddress(address _address) external;

    function setForwDistributorAddress(address _address) external;

    function setRouterAddress(address _address) external;

    function setCoreBorrowingAddress(address _address) external;

    function setFeeController(address _address) external;

    function setWETHAddress(address _address) external;

    function setWETHHandler(address _address) external;

    function setLoanDuration(uint256 _value) external;

    function setAdvancedInterestDuration(uint256 _value) external;

    function setFeeSpread(uint256 _value) external;

    function registerNewPool(
        address poolAddress,
        uint256 amount,
        uint256 targetBlock
    ) external;

    function setForwDisPerBlock(
        address poolAddress,
        uint256 amount,
        uint256 targetBlock
    ) external;

    function approveForRouter(address _assetAddress) external;

    function setFixSlippage(uint256 _value) external;
}
