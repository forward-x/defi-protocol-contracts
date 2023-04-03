// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../../../interfaces/IWethERC20Upgradeable.sol";
import "../../../interfaces/IWethHandler.sol";
import "../../openzeppelin/upgradeable/InitializableUpgradeable.sol";
import "../../openzeppelin/upgradeable/SafeERC20Upgradeable.sol";
import "../../openzeppelin/upgradeable/IERC20Upgradeable.sol";

contract AssetHandlerUpgradeable is InitializableUpgradeable {
    // Allocating __gap for futhur variable (need to subtract equal to new state added)
    uint256[10] private __gap_top_assetHandler;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IWethERC20Upgradeable;

    address public wethAddress;
    address public wethHandler;

    uint256[10] private __gap_bottom_assetHandler;

    function __AssetHandler_init_unchained(address _wethAddress, address _wethHandler)
        internal
        onlyInitializing
    {
        wethAddress = _wethAddress;
        wethHandler = _wethHandler;
    }

    function _transferFromIn(
        address from,
        address to,
        address token,
        uint256 amount
    ) internal {
        require(amount != 0, "AssetHandler/amount-is-zero");

        if (token == wethAddress) {
            require(amount == msg.value, "AssetHandler/value-not-matched");
            IWethERC20Upgradeable(wethAddress).deposit{value: amount}();
            IWethERC20Upgradeable(wethAddress).safeTransfer(to, amount);
        } else {
            IERC20Upgradeable(token).safeTransferFrom(from, to, amount);
        }
    }

    function _transferFromOut(
        address from,
        address to,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        if (token == wethAddress) {
            IWethERC20Upgradeable(wethAddress).safeTransferFrom(from, wethHandler, amount);
            IWethHandler(payable(wethHandler)).withdrawETH(to, amount);
        } else {
            IERC20Upgradeable(token).safeTransferFrom(from, to, amount);
        }
    }

    function _transferOut(
        address to,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        if (token == wethAddress) {
            IWethERC20Upgradeable(wethAddress).safeTransfer(wethHandler, amount);
            IWethHandler(payable(wethHandler)).withdrawETH(to, amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(to, amount);
        }
    }
}
