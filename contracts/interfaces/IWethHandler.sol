// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

interface IWethHandler {
    function withdrawETH(address to, uint256 amount) external;
}
