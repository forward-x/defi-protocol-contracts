// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../../interfaces/IWethERC20Upgradeable.sol";
import "../../externalContract/openzeppelin/upgradeable/SafeERC20Upgradeable.sol";

contract WETHHandler {
    address public constant wethAddress =
        0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    using SafeERC20Upgradeable for IWethERC20Upgradeable;

    //address public constant wethToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c  // bsc (Wrapped BNB)

    function withdrawETH(address to, uint256 amount) external {
        IWethERC20Upgradeable(wethAddress).withdraw(amount);
        (bool success, ) = to.call{value: amount}(new bytes(0));
        if (success) {
            return;
        } else {
            IWethERC20Upgradeable(wethAddress).deposit{value: amount}();
            IWethERC20Upgradeable(wethAddress).safeTransfer(to, amount);
        }
    }

    fallback() external {
        revert("WETHHandler/fallback-function-not-allowed");
    }

    receive() external payable {}
}
