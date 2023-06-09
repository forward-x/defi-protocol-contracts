// SPDX-License-Identifier: MIT

/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;


interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
