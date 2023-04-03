// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract ManagerUpgradeable {
    // Allocating __gap for futhur variable (need to subtract equal to new state added)
    uint256[10] private __gap_top_manager;

    address internal manager;

    uint256[10] private __gap_bottom_manager;

    event TransferManager(address, address);

    constructor() {}

    modifier onlyManager() {
        _onlyManager();
        _;
    }

    function getManager() external view returns (address) {
        return manager;
    }

    function _onlyManager() internal view {
        require(manager == msg.sender, "Manager/caller-is-not-the-manager");
    }

    function transferManager(address _address) public virtual onlyManager {
        require(_address != address(0), "Manager/new-manager-is-the-zero-address");
        _transferManager(_address);
    }

    function _transferManager(address _address) internal virtual {
        address oldManager = manager;
        manager = _address;
        emit TransferManager(oldManager, _address);
    }
}
