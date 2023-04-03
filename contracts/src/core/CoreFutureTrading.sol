// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./event/CoreFutureTradingEvent.sol";
import "./CoreBaseFunc.sol";

contract CoreFutureTrading is CoreBaseFunc, CoreFutureTradingEvent {
    // function futureTrade(
    //     uint256 nftId,
    //     uint256 collateralSentAmount,
    //     address collateralTokenAddress,
    //     uint256 borrowAmount,
    //     address borrowTokenAddress,
    //     address swapTokenAddress,
    //     uint256 leverage,
    //     uint256 maxSlippage,
    //     bool isLong,
    //     uint256 newOwedPerDay
    // ) external whenFuncNotPaused(msg.sig) nonReentrant returns (Position memory) {
    //     return
    //         _futureTrade(
    //             nftId,
    //             collateralSentAmount,
    //             collateralTokenAddress,
    //             borrowAmount,
    //             borrowTokenAddress,
    //             swapTokenAddress,
    //             leverage,
    //             maxSlippage,
    //             isLong,
    //             newOwedPerDay
    //         );
    // }
    // function adjustPositionCollateral(
    //     uint256 loanId,
    //     uint256 nftId,
    //     uint256 collateralAdjustAmount,
    //     bool isAdd
    // ) external payable whenFuncNotPaused(msg.sig) nonReentrant returns (Position memory) {}
    // function closePosition(
    //     uint256 loanId,
    //     uint256 nftId,
    //     uint256 closeSize
    // ) external whenFuncNotPaused(msg.sig) nonReentrant returns (Position memory) {}
    // function liquidatePosition(uint256 loanId, uint256 nftId)
    //     external
    //     whenFuncNotPaused(msg.sig)
    //     nonReentrant
    //     returns (Position memory)
    // {}
    // function _futureTrade(
    //     uint256 nftId,
    //     uint256 collateralSentAmount,
    //     address collateralTokenAddress,
    //     uint256 borrowAmount,
    //     address borrowTokenAddress,
    //     address swapTokenAddress,
    //     uint256 leverage,
    //     uint256 maxSlippage,
    //     bool isLong,
    //     uint256 newOwedPerDay
    // ) internal returns (Position memory) {
    //     require(msg.sender == assetToPool[borrowTokenAddress], "01");
    //     require(assetToPool[collateralTokenAddress] != address(0), "Error: colla invalid");
    //     require(swapableToken[swapTokenAddress], "Error: swap invalid");
    //     require(collateralSentAmount != 0 && borrowAmount != 0, "Error");
    //     currentPositionIndex[nftId] += 1;
    //     PoolStat storage poolStat = poolStats[borrowTokenAddress];
    //     Position storage position = positions[nftId][currentPositionIndex[nftId]];
    //     PositionExt storage positionExt = positionExts[nftId][currentPositionIndex[nftId]];
    //     PositionConfig storage positionConfig = positionConfigs[borrowTokenAddress][
    //         swapTokenAddress
    //     ];
    //     require(leverage <= positionConfig.maxLeverage, "Error: leverage too high");
    //     uint256 swapAmount = isLong ? borrowAmount + collateralSentAmount : borrowAmount;
    //     uint256 tradingFee = (swapAmount * tradingFees) / WEI_PERCENT_UNIT;
    //     swapAmount = swapAmount - tradingFee;
    //     // TODO: collect trading fee 0.03% of ???
    //     // TODO: distirbute fee ??
    //     // TODO: swap
    //     leverage = (WEI_PERCENT_UNIT * WEI_UNIT) / leverage; // convert to initialMargin
    //     // TODO: check margin
    //     // open position
    //     position.swapTokenAddress = swapTokenAddress;
    //     position.borrowTokenAddress = borrowTokenAddress;
    //     position.collateralTokenAddress = collateralTokenAddress;
    //     position.borrowAmount = borrowAmount;
    //     position.collateralAmount = collateralSentAmount;
    //     // position.positionSize = res
    //     position.inititalMargin = leverage;
    //     position.owedPerDay = newOwedPerDay;
    //     position.lastSettleTimestamp = uint64(block.timestamp);
    //     positionExt.active = true;
    //     positionExt.long = isLong;
    //     positionExt.short = !isLong;
    //     positionExt.startTimestamp = uint64(block.timestamp);
    //     // update pool stat
    //     poolStat.borrowInterestOwedPerDay += newOwedPerDay;
    //     poolStat.totalBorrowAmount += borrowAmount;
    //     poolStat.updatedTimestamp = uint64(block.timestamp);
    //     return position;
    // }
    // // TODO:
    // function _isPositionLiquidatable(
    //     uint256 borrowAmount,
    //     uint256 collateralAmount,
    //     uint256 interestOwed,
    //     uint256 targetLTV,
    //     uint256 rate,
    //     uint256 precision
    // ) internal view returns (bool) {
    //     uint256 loanLTV = ((borrowAmount + interestOwed) * WEI_PERCENT_UNIT * precision) /
    //         (collateralAmount * rate);
    //     return loanLTV > targetLTV ? true : false;
    // }
}
