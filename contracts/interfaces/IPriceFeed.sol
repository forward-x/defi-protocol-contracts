// SPDX-License-Identifier: GPL-3.0
/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.8.15;

interface IPriceFeed {
    function queryRate(address sourceToken, address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function queryPrecision(address sourceToken, address destToken)
        external
        view
        returns (uint256 precision);

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount
    ) external view returns (uint256 destAmount);

    function amountInEth(address Token, uint256 amount) external view returns (uint256 ethAmount);

    function queryRateUSD(address token) external view returns (uint256 rate, uint256 precision);

    function stalePeriod() external view returns (uint256);
}
