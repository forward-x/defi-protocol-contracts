// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../src/stakepool/StakePoolBase.sol";

interface IStakePool {
    // Getter functions

    function rankInfos(uint8) external view returns (StakePoolBase.RankInfo memory);

    function stakeInfos(uint256) external view returns (StakePoolBase.StakeInfo memory);

    // External functions

    function stake(uint256 nftId, uint256 amount) external returns (StakePoolBase.StakeInfo memory);

    function unstake(uint256 nftId, uint256 amount)
        external
        returns (StakePoolBase.StakeInfo memory);

    function setRankInfo(
        uint8[] memory _rank,
        uint256[] memory _interestBonusLending,
        uint256[] memory _forwardBonusLending,
        uint256[] memory _minimumStakeAmount,
        uint256[] memory _maxLTVBonus,
        uint256[] memory _tradingFee
    ) external;

    function setPoolStartTimestamp(uint64 timestamp) external;

    function settleInterval() external view returns (uint256);

    function settlePeriod() external view returns (uint256);

    function poolStartTimestamp() external view returns (uint64);

    function rankLen() external view returns (uint256);

    function getStakeInfo(uint256 nftId) external view returns (StakePoolBase.StakeInfo memory);

    function getMaxLTVBonus(uint256 nftId) external view returns (uint256);

    function deprecateStakeInfo(uint256 nftId) external;

    function migrate(uint256 nftId) external returns (StakePoolBase.StakeInfo memory);

    function setNextPool(address _address) external;

    function nextPoolAddress() external view returns (address);

    function totalStakeAmount() external view returns (uint256);
}
