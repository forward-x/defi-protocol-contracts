// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../externalContract/openzeppelin/upgradeable/MathUpgradeable.sol";
import "../../externalContract/openzeppelin/upgradeable/ReentrancyGuardUpgradeable.sol";
import "../../externalContract/modify/upgradeable/SelectorPausableUpgradeable.sol";
import "../../externalContract/modify/upgradeable/AssetHandlerUpgradeable.sol";
import "../../externalContract/modify/upgradeable/ManagerTimelockUpgradeable.sol";

contract PoolBase is
    AssetHandlerUpgradeable,
    ManagerTimelockUpgradeable,
    ReentrancyGuardUpgradeable,
    SelectorPausableUpgradeable
{
    struct Lend {
        uint8 rank;
        uint64 updatedTimestamp;
    }

    struct WithdrawResult {
        uint256 principle;
        uint256 tokenInterest;
        uint256 forwInterest;
        uint256 pTokenBurn;
        uint256 atpTokenBurn;
        uint256 lossBurn;
        uint256 itpTokenBurn;
        uint256 ifpTokenBurn;
        uint256 tokenInterestBonus;
        uint256 forwInterestBonus;
    }

    // Allocating __gap for futhur variable (need to subtract equal to new state added)
    uint256[50] private __gap_top_poolBase;

    uint256 internal WEI_UNIT; //               // 1e18
    uint256 internal WEI_PERCENT_UNIT; //       // 1e20 (100*1e18 for calculating percent)
    uint256 public BLOCK_TIME; //               // time between each block in seconds

    address public poolLendingAddress; //       // address of pool lending logic contract
    address public poolBorrowingAddress; //     // address of pool borrowing logic contract
    address public forwAddress; //              // forw token's address
    address public membershipAddress; //        // address of membership contract
    address public interestVaultAddress; //     // address of interestVault contract
    address public tokenAddress; //             // address of token which pool allows to lend
    address public coreAddress; //              // address of APHCore contract
    mapping(uint256 => Lend) public lenders; // // map nftId => rank

    uint256 internal initialAtpPrice;
    uint256 internal initialItpPrice;
    uint256 internal initialIfpPrice;

    // loss params
    uint256 public loss;

    // borrowing interest params
    uint256 public lambda; //                   // constant use for weight forw token in iftPrice

    uint256 public targetSupply; //             // weighting factor to proportional reduce utilOptimse vaule if total lending is less than targetSupply

    uint256[10] public rates; //                // list of target interest rate at each util
    uint256[10] public utils; //                // list of utilization rate to which each rate reached
    uint256 public utilsLen; //                 // length of current active rates and utils (both must be equl)

    uint256[50] private __gap_bottom_poolBase;
}
