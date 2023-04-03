// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../externalContract/openzeppelin/upgradeable/ReentrancyGuardUpgradeable.sol";
import "../../externalContract/openzeppelin/upgradeable/MathUpgradeable.sol";
import "../../externalContract/modify/upgradeable/SelectorPausableUpgradeable.sol";
import "../../externalContract/modify/upgradeable/AssetHandlerUpgradeable.sol";
import "../../externalContract/modify/upgradeable/ManagerTimelockUpgradeable.sol";

import "../../interfaces/IAPHPool.sol";
import "../../interfaces/IInterestVault.sol";
import "../../interfaces/IMembership.sol";
import "../../interfaces/IPriceFeed.sol";
import "../../interfaces/IRouter.sol";
import "../../interfaces/IStakePool.sol";

contract CoreBase is
    AssetHandlerUpgradeable,
    ManagerTimelockUpgradeable,
    ReentrancyGuardUpgradeable,
    SelectorPausableUpgradeable
{
    struct NextForwDisPerBlock {
        uint256 amount;
        uint256 targetBlock;
    }
    struct Loan {
        address borrowTokenAddress;
        address collateralTokenAddress;
        uint256 borrowAmount;
        uint256 collateralAmount;
        uint256 owedPerDay;
        uint256 minInterest;
        uint256 interestOwed;
        uint256 interestPaid;
        uint64 rolloverTimestamp;
        uint64 lastSettleTimestamp;
    }

    struct LoanExt {
        bool active;
        uint64 startTimestamp;
        uint256 initialBorrowTokenPrice;
        uint256 initialCollateralTokenPrice;
    }

    struct LoanConfig {
        address borrowTokenAddress;
        address collateralTokenAddress;
        uint256 safeLTV;
        uint256 maxLTV;
        uint256 liquidationLTV;
        uint256 bountyFeeRate;
    }

    // struct Position {
    //     address swapTokenAddress;
    //     address borrowTokenAddress;
    //     address collateralTokenAddress;
    //     uint256 borrowAmount;
    //     uint256 collateralAmount;
    //     uint256 positionSize; // contract size after swapped
    //     uint256 inititalMargin;
    //     uint256 owedPerDay;
    //     uint256 interestOwed;
    //     uint256 interestPaid;
    //     uint64 lastSettleTimestamp;
    // }
    // struct PositionExt {
    //     bool active;
    //     bool long;
    //     bool short;
    //     uint64 startTimestamp;
    //     uint256 initialBorrowTokenPrice; // need?
    //     uint256 initialCollateralTokenPrice; // need?
    // }

    // struct PositionConfig {
    //     address borrowTokenAddress;
    //     address collateralTokenAddress;
    //     uint256 maxLeverage;
    //     uint256 maintenanceMargin;
    //     uint256 bountyFeeRate; // liquidation fee
    // }

    struct PoolStat {
        uint64 updatedTimestamp;
        uint256 totalBorrowAmount;
        uint256 borrowInterestOwedPerDay;
        uint256 totalInterestPaid;
    }

    // Allocating __gap for futhur variable (need to subtract equal to new state added)
    uint256[50] private __gap_top_coreBase;

    // constant
    uint256 internal WEI_UNIT; //                                                           // 1e18
    uint256 internal WEI_PERCENT_UNIT; //                                                   // 1e20 (100*1e18 for calculating percent)

    // lending
    uint256 public feeSpread; //                                                            // spread for borrowing interest to lending interest                                                    // fee taken from lender interest payments (fee when protocol settles interest to pool)

    // borrowing
    uint256 public loanDuration; //                                                         // max days for borrowing with fix rate interest
    uint256 public advancedInterestDuration; //                                             // duration for calculating minimum interest
    mapping(address => mapping(address => LoanConfig)) public loanConfigs; //               // borrowToken => collateralToken => config
    mapping(uint256 => uint256) public currentLoanIndex; //                                 // nftId => currentLoanIndex
    mapping(uint256 => mapping(uint256 => Loan)) public loans; //                           // nftId => loanId => loan
    mapping(uint256 => mapping(uint256 => LoanExt)) public loanExts; //                     // nftId => loanId => loanExt (extension data)

    // futureTrading
    // uint256 public tradingFees; //                                                          // fee collect when use open or close position
    // mapping(address => mapping(address => PositionConfig)) public positionConfigs; //       // borrowToken => collateralToken => config
    // mapping(uint256 => uint256) public currentPositionIndex; //                             // nftId => currentPositionIndex
    // mapping(uint256 => mapping(uint256 => Position)) public positions; //                   // nftId => positionId => position
    // mapping(uint256 => mapping(uint256 => PositionExt)) public positionExts; //             // nftId => positionId => positionExt (extension data)

    // stat
    mapping(address => uint256) public totalCollateralHold; //                              // tokenAddress => total collateral amount
    mapping(address => PoolStat) public poolStats; //                                       // pool's address => borrowStat
    mapping(address => bool) public swapableToken; //                                       // check that token is allowed for swap
    mapping(address => address) public poolToAsset; //                                      // pool => underlying (token address)
    mapping(address => address) public assetToPool; //                                      // underlying => pool
    address[] public poolList; //                                                           // list of pool

    // forw distributor
    mapping(address => uint256) public forwDisPerBlock; //                                  // pool => forw distribute per block
    mapping(address => uint256) public lastSettleForw; //                                   // pool => lastest settle forward by pool
    mapping(address => NextForwDisPerBlock) public nextForwDisPerBlock; //                  // pool => next forw distribute per block

    address public forwDistributorAddress; //                                               // address of vault which stores forw token for distribution
    address public forwAddress; //                                                          // forw token's address
    address public feesController; //                                                       // address target for withdrawing collected fees
    address public priceFeedAddress; //                                                     // address of price feed contract
    address public routerAddress; //                                                        // address of DEX contract
    address public membershipAddress; //                                                    // address of membership contract

    address public coreBorrowingAddress; //                                                 // address of borrowing logic contract

    uint256 public fixSlippage;

    mapping(uint256 => uint256) public nftsLossInUSD; //                                     // nftId => lossInUSD
    uint256 public totalLossInUSD; //                                                       // totalLossInUSD

    uint256[50] private __gap_bottom_coreBase;
}
