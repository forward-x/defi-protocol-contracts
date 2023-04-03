// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../../../interfaces/IWethERC20.sol";
import "../../../interfaces/IWethHandler.sol";
import "../../openzeppelin/non-upgradeable/IERC20.sol";
import "../../openzeppelin/non-upgradeable/SafeERC20.sol";

contract AssetHandler {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWethERC20;

    address public wethAddress;
    address public wethHandler;

    constructor(address _wethAddress, address _wethHandler) {
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
            IWethERC20(wethAddress).deposit{value: amount}();
            IWethERC20(wethAddress).safeTransfer(to, amount);
        } else {
            IERC20(token).safeTransferFrom(from, to, amount);
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
            IWethERC20(wethAddress).safeTransferFrom(from, wethHandler, amount);
            IWethHandler(payable(wethHandler)).withdrawETH(to, amount);
        } else {
            IERC20(token).safeTransferFrom(from, to, amount);
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
            IWethERC20(wethAddress).safeTransfer(wethHandler, amount);
            IWethHandler(payable(wethHandler)).withdrawETH(to, amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}
