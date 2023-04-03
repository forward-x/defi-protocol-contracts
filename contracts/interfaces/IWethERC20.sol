// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "./IWeth.sol";
import "../externalContract/openzeppelin/non-upgradeable/IERC20.sol";

interface IWethERC20 is IWeth, IERC20 {}
