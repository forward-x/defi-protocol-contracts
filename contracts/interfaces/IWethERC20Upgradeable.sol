// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "./IWeth.sol";
import "../externalContract/openzeppelin/upgradeable/IERC20Upgradeable.sol";

interface IWethERC20Upgradeable is IWeth, IERC20Upgradeable {}
