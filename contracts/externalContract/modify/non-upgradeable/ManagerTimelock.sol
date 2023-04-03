// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract ManagerTimelock {
    address internal noTimelockManager;
    address internal configTimelockManager;
    address internal addressTimelockManager;

    event TransferNoTimelockManager(address, address);
    event TransferConfigTimelockManager(address, address);
    event TransferAddressTimelockManager(address, address);

    constructor() {}

    modifier onlyNoTimelockManager() {
        _onlyNoTimelockManager();
        _;
    }
    modifier onlyConfigTimelockManager() {
        _onlyConfigTimelockManager();
        _;
    }
    modifier onlyAddressTimelockManager() {
        _onlyAddressTimelockManager();
        _;
    }

    function getNoTimelockManager() external view returns (address) {
        return noTimelockManager;
    }

    function getConfigTimelockManager() external view returns (address) {
        return configTimelockManager;
    }

    function getAddressTimelockManager() external view returns (address) {
        return addressTimelockManager;
    }

    function _onlyNoTimelockManager() internal view {
        require(noTimelockManager == msg.sender, "Manager/caller-is-not-the-manager");
    }

    function _onlyConfigTimelockManager() internal view {
        require(configTimelockManager == msg.sender, "Manager/caller-is-not-the-manager");
    }

    function _onlyAddressTimelockManager() internal view {
        require(addressTimelockManager == msg.sender, "Manager/caller-is-not-the-manager");
    }

    function transferNoTimelockManager(address _address) public virtual onlyNoTimelockManager {
        require(_address != address(0), "Manager/new-manager-is-the-zero-address");
        _transferNoTimelockManager(_address);
    }

    function transferConfigTimelockManager(address _address)
        public
        virtual
        onlyConfigTimelockManager
    {
        require(_address != address(0), "Manager/new-manager-is-the-zero-address");
        _transferConfigTimelockManager(_address);
    }

    function transferAddressTimelockManager(address _address)
        public
        virtual
        onlyAddressTimelockManager
    {
        require(_address != address(0), "Manager/new-manager-is-the-zero-address");
        _transferAddressTimelockManager(_address);
    }

    function _transferNoTimelockManager(address _address) internal virtual {
        address oldManager = noTimelockManager;
        noTimelockManager = _address;
        emit TransferNoTimelockManager(oldManager, _address);
    }

    function _transferConfigTimelockManager(address _address) internal virtual {
        address oldManager = configTimelockManager;
        configTimelockManager = _address;
        emit TransferConfigTimelockManager(oldManager, _address);
    }

    function _transferAddressTimelockManager(address _address) internal virtual {
        address oldManager = addressTimelockManager;
        addressTimelockManager = _address;
        emit TransferAddressTimelockManager(oldManager, _address);
    }
}
