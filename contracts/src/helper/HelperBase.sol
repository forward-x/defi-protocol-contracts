// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../externalContract/modify/non-upgradeable/Manager.sol";

import "../../interfaces/IAPHCore.sol";
import "../../interfaces/IAPHPool.sol";
import "../../interfaces/IPriceFeed.sol";

contract HelperBase is Manager {
    struct ActiveLoanInfo {
        uint256 id;
        uint256 currentLTV;
        uint256 liquidationLTV;
        uint256 apr;
        uint256 actualInterestOwed;
    }
    address public immutable aphCoreAddress;
    uint256 public constant WEI_UNIT = 1 ether;
    uint256 public constant WEI_PERCENT_UNIT = 100 ether;

    constructor(address _aphCoreAddres) {
        require(
            _aphCoreAddres != address(0),
            "Helper/initialize/coreAddress-zero-address"
        );
        manager = msg.sender;
        aphCoreAddress = _aphCoreAddres;
    }
}
