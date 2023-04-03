// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

interface IAPHPoolSetting {
    // External functions

    function setupLoanConfig(
        address collateralTokenAddress,
        uint256 safeLTV,
        uint256 maxLTV,
        uint256 liqLTV,
        uint256 bountyFeeRate
    ) external;

    function setBorrowInterestParams(
        uint256[] memory _rates,
        uint256[] memory _utils,
        uint256 _targetSupply
    ) external;

    function setWETHAddress(address _address) external;

    function setWETHHandler(address _address) external;

    function setPoolLendingAddress(address _address) external;

    function setPoolBorrowingAddress(address _address) external;

    function setMembershipAddress(address _address) external;
}
