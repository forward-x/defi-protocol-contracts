// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../../externalContract/modify/non-upgradeable/ManagerTimelock.sol";
import "../../externalContract/openzeppelin/non-upgradeable/IERC20.sol";
import "../../externalContract/openzeppelin/non-upgradeable/SafeERC20.sol";

contract Vault is ManagerTimelock {
    using SafeERC20 for IERC20;
    address public immutable tokenAddress;

    event SetTokenAddress(
        address indexed sender,
        address oldValue,
        address newValue
    );
    event OwnerApproveVault(
        address indexed sender,
        address pool,
        uint256 amount
    );
    event ApproveInterestVault(
        address indexed sender,
        address core,
        uint256 amount
    );

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        addressTimelockManager = msg.sender;
        _ownerApprove(msg.sender, type(uint256).max);
        emit TransferAddressTimelockManager(address(0), addressTimelockManager);
        emit SetTokenAddress(msg.sender, address(0), tokenAddress);
    }

    function ownerApprove(
        address _pool,
        uint256 tokenApproveAmount
    ) external onlyAddressTimelockManager {
        _ownerApprove(_pool, tokenApproveAmount);
    }

    function _ownerApprove(address _pool, uint256 tokenApproveAmount) internal {
        IERC20(tokenAddress).safeIncreaseAllowance(_pool, tokenApproveAmount);

        emit OwnerApproveVault(msg.sender, _pool, tokenApproveAmount);
    }

    function approveInterestVault(
        address _core,
        uint256 tokenApproveAmount
    ) external onlyAddressTimelockManager {
        IERC20(tokenAddress).safeIncreaseAllowance(_core, tokenApproveAmount);
        emit ApproveInterestVault(msg.sender, _core, tokenApproveAmount);
    }
}
