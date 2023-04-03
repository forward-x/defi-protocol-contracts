// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../externalContract/openzeppelin/non-upgradeable/ReentrancyGuard.sol";
import "../../externalContract/modify/non-upgradeable/SelectorPausable.sol";
import "../../externalContract/modify/non-upgradeable/ManagerTimelock.sol";

contract StakePoolBase is ManagerTimelock, ReentrancyGuard, SelectorPausable {
    struct StakeInfo {
        uint256 stakeBalance; //                                 // Staking forw token amount
        uint256 claimableAmount; //                              // Claimable forw token amount
        uint64 startTimestamp; //                                // Timestamo that user start staking
        uint64 endTimestamp; //                                  // Timestamp that user can withdraw all staking balance
        uint64 lastSettleTimestamp; //                           // Timestamp that represent a lastest update claimable amount of each user
        uint256[] payPattern; //                                 // Part of nft stakeInfo for record withdrawable of user that pass each a quater of settlePeriod
    }

    struct RankInfo {
        uint256 interestBonusLending; //                          // Bonus of lending of each membership tier (lending token bonus)
        uint256 forwardBonusLending; //                           // Bonus of lending of each membership tier (FORW token bonus)
        uint256 minimumStakeAmount; //                            // Minimum forw token staking to claim this rank
        uint256 maxLTVBonus; //                                   // Addition LTV which added during borrowing token
        uint256 tradingFee; //                                    // Trading Fee in future trading
    }

    address public membershipAddress; //                         // Address of membership contract
    address public nextPoolAddress; //                           // Address of new migration stakpool
    address public stakeVaultAddress; //                         // Address of stake vault that use for collect a staking FORW token
    address public forwAddress; //                               // Address of FORW token
    uint8 public rankLen; //                                     // Number of membership rank
    uint64 public poolStartTimestamp; //                         // Timestamp that record poolstart time use for calculate withdrawable balance
    uint256 public settleInterval; //                            // Duration that stake pool allow sender to withdraw a quarter of staking balance
    uint256 public constant settlePeriod = 4; //                              // Period that stake pool allow sender to withdraw all staking balance
    mapping(uint256 => StakeInfo) public stakeInfos; //          // Object that represent a status of staking of user
    mapping(uint8 => RankInfo) public rankInfos; //              // Represent array of a tier of membership mapping minimum staking balance
    uint256 public totalStakeAmount;
}
