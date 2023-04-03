// SPDX-License-Identifier: GPL-3.0
/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.8.15;

import "../../externalContract/openzeppelin/non-upgradeable/IERC20Metadata.sol";
import "../../externalContract/modify/non-upgradeable/AggregatorV2V3Interface.sol";
import "../../externalContract/modify/non-upgradeable/ManagerTimelock.sol";

contract PriceFeeds_BSC is ManagerTimelock {
    event GlobalPricingPaused(address indexed sender, bool isPaused);
    event SetPriceFeed(
        address indexed sender,
        address[] tokens,
        address[] feeds
    );
    event SetDecimals(address indexed sender, address[] tokens);
    event SetStalePeriod(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    mapping(address => address) public pricesFeeds; // token => pricefeed
    mapping(address => uint256) public decimals; // decimals of supported tokens

    bool public globalPricingPaused = false;

    uint256 WEI_PRECISION = 10 ** 18;
    uint256 stalePeriod;
    address wethTokenAddress = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //mainnet

    constructor() {
        noTimelockManager = msg.sender;
        configTimelockManager = msg.sender;
        decimals[wethTokenAddress] = 18;
        stalePeriod = 2 hours;

        emit TransferNoTimelockManager(address(0), noTimelockManager);
        emit TransferConfigTimelockManager(address(0), configTimelockManager);
        emit SetStalePeriod(msg.sender, 0, stalePeriod);
    }

    function queryRate(
        address sourceToken,
        address destToken
    ) public view returns (uint256 rate, uint256 precision) {
        require(!globalPricingPaused, "PriceFeed/pricing-is-paused");
        return _queryRate(sourceToken, destToken);
    }

    function queryPrecision(
        address sourceToken,
        address destToken
    ) public view returns (uint256) {
        return
            sourceToken != destToken
                ? _getDecimalPrecision(sourceToken, destToken)
                : WEI_PRECISION;
    }

    //// NOTE: This function returns 0 during a pause, rather than a revert. Ensure calling contracts handle correctly. ///
    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount
    ) public view returns (uint256 destAmount) {
        require(!globalPricingPaused, "PriceFeed/pricing-is-paused");

        (uint256 rate, uint256 precision) = _queryRate(sourceToken, destToken);

        destAmount = (sourceAmount * rate) / precision;
    }

    function amountInEth(
        address tokenAddress,
        uint256 amount
    ) public view returns (uint256 ethAmount) {
        if (tokenAddress == wethTokenAddress) {
            ethAmount = amount;
        } else {
            (uint256 toEthRate, uint256 toEthPrecision) = queryRate(
                tokenAddress,
                wethTokenAddress
            );
            ethAmount = (amount * toEthRate) / toEthPrecision;
        }
    }

    /*
     * Owner functions
     */

    function setPriceFeed(
        address[] calldata tokens,
        address[] calldata feeds
    ) external onlyConfigTimelockManager {
        require(tokens.length == feeds.length, "PriceFeed/count-mismatch");
        for (uint256 i = 0; i < tokens.length; i++) {
            pricesFeeds[tokens[i]] = feeds[i];
        }

        emit SetPriceFeed(msg.sender, tokens, feeds);
    }

    function setStalePeriod(
        uint256 newValue
    ) external onlyConfigTimelockManager {
        uint256 oldValue = stalePeriod;
        stalePeriod = newValue;

        emit SetStalePeriod(msg.sender, oldValue, stalePeriod);
    }

    function setDecimals(
        IERC20Metadata[] calldata tokens
    ) external onlyConfigTimelockManager {
        address[] memory tokenAddresses = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            decimals[address(tokens[i])] = tokens[i].decimals();
            tokenAddresses[i] = address(tokens[i]);
        }

        emit SetDecimals(msg.sender, tokenAddresses);
    }

    function setGlobalPricingPaused(
        bool isPaused
    ) external onlyNoTimelockManager {
        globalPricingPaused = isPaused;

        emit GlobalPricingPaused(msg.sender, isPaused);
    }

    /*
     * Internal functions
     */

    function _queryRate(
        address sourceToken,
        address destToken
    ) internal view returns (uint256 rate, uint256 precision) {
        uint256 sourceRate;
        uint256 destRate;
        if (sourceToken != destToken) {
            (sourceRate, ) = _queryRateUSD(sourceToken);
            (destRate, ) = _queryRateUSD(destToken);

            rate = (sourceRate * WEI_PRECISION) / destRate;

            precision = _getDecimalPrecision(sourceToken, destToken);
        } else {
            rate = WEI_PRECISION;
            precision = WEI_PRECISION;
        }
    }

    function _queryRateUSD(
        address token
    ) internal view returns (uint256 rate, uint256 precision) {
        require(
            pricesFeeds[token] != address(0),
            "PriceFeed/unsupported-address"
        );
        AggregatorV2V3Interface _Feed = AggregatorV2V3Interface(
            pricesFeeds[token]
        );
        (, int256 answer, , uint256 updatedAt, ) = _Feed.latestRoundData();
        rate = uint256(answer);
        require(
            block.timestamp - updatedAt < stalePeriod,
            "PriceFeed/price-is-stale"
        );
    }

    function queryRateUSD(
        address token
    ) external view returns (uint256 rate, uint256 precision) {
        require(!globalPricingPaused, "PriceFeed/pricing-is-paused");
        (rate, precision) = _queryRateUSD(token);
    }

    function _getDecimalPrecision(
        address sourceToken,
        address destToken
    ) internal view returns (uint256) {
        if (sourceToken == destToken) {
            return WEI_PRECISION;
        } else {
            uint256 sourceTokenDecimals = decimals[sourceToken];
            if (sourceTokenDecimals == 0)
                sourceTokenDecimals = IERC20Metadata(sourceToken).decimals();

            uint256 destTokenDecimals = decimals[destToken];
            if (destTokenDecimals == 0)
                destTokenDecimals = IERC20Metadata(destToken).decimals();

            if (destTokenDecimals >= sourceTokenDecimals) {
                return 10 ** (18 - (destTokenDecimals - sourceTokenDecimals));
            } else {
                return 10 ** (18 + (sourceTokenDecimals - destTokenDecimals));
            }
        }
    }
}
