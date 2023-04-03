// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../interfaces/IAPHCore.sol";
import "../../interfaces/IStakePool.sol";
import "../../interfaces/IInterestVault.sol";
import "../../interfaces/IMembership.sol";
import "../../interfaces/IPriceFeed.sol";

import "./PoolBase.sol";
import "./PoolToken.sol";

contract PoolBaseFunc is PoolBase, PoolToken {
    modifier settleForwInterest() {
        IAPHCore(coreAddress).settleForwInterest();
        _;
    }

    function pause(bytes4 _func) external onlyNoTimelockManager {
        require(_func != bytes4(0), "PoolBaseFunc/msg.sig-func-is-zero");
        _pause(_func);
    }

    function unPause(bytes4 _func) external onlyNoTimelockManager {
        require(_func != bytes4(0), "PoolBaseFunc/msg.sig-func-is-zero");
        _unpause(_func);
    }

    // internal function
    function _calculateBorrowInterest(
        uint256 borrowAmount
    ) internal view returns (uint256 interestRate, uint256 interestOwedPerDay) {
        interestRate = _getNextBorrowingInterest(borrowAmount);

        interestOwedPerDay =
            (borrowAmount * interestRate) /
            (WEI_PERCENT_UNIT * 365);
    }

    function _getNextLendingInterest(
        uint256 newDepositAmount
    ) internal view returns (uint256 interestRate) {
        uint256 totalBorrow = _totalBorrowAmount();
        if (totalBorrow == 0) {
            return 0;
        }
        uint256 utilRate = _utilizationRate(
            totalBorrow, // borrow amount
            pTokenTotalSupply + newDepositAmount // total supply
        );

        uint256 borrowInterestOwedPerDay = IAPHCore(coreAddress)
            .poolStats(address(this))
            .borrowInterestOwedPerDay;

        uint256 avgBorrowInterestRate = (borrowInterestOwedPerDay *
            365 *
            WEI_PERCENT_UNIT) / totalBorrow;

        interestRate =
            ((WEI_PERCENT_UNIT - IAPHCore(coreAddress).feeSpread()) *
                avgBorrowInterestRate *
                utilRate) /
            (WEI_PERCENT_UNIT * WEI_PERCENT_UNIT);
    }

    function _getNextLendingForwInterest(
        uint256 newDepositAmount,
        uint256 forwPriceRate,
        uint256 forwPricePrecision
    ) internal view returns (uint256 interestRate) {
        uint256 newPTokenTotalSupply = pTokenTotalSupply + newDepositAmount;

        if (newPTokenTotalSupply == 0) {
            interestRate = 0;
        } else {
            interestRate =
                (IAPHCore(coreAddress).forwDisPerBlock(address(this)) *
                    (365 days / BLOCK_TIME) *
                    forwPriceRate *
                    WEI_PERCENT_UNIT) /
                (newPTokenTotalSupply * forwPricePrecision);
        }
    }

    function _getNextBorrowingInterest(
        uint256 newBorrowAmount
    ) internal view returns (uint256 nextInterestRate) {
        uint256[10] memory localUtils = utils;
        uint256[10] memory localRates = rates;

        nextInterestRate = localRates[0];

        if (pTokenTotalSupply == 0) {
            return nextInterestRate;
        }

        uint256 w = MathUpgradeable.max(
            WEI_UNIT,
            (targetSupply * WEI_UNIT) / pTokenTotalSupply
        );
        uint256 utilRate = _utilizationRate(
            _totalBorrowAmount() + newBorrowAmount,
            pTokenTotalSupply
        );

        localUtils[utilsLen - 1] = (localUtils[utilsLen - 1] * w) / WEI_UNIT;

        uint256 tmp;
        for (uint256 i = 1; i < utilsLen; i++) {
            tmp = 0;
            tmp = MathUpgradeable.max(
                (w * utilRate) / WEI_UNIT,
                localUtils[i - 1]
            );
            tmp = MathUpgradeable.min(tmp, localUtils[i]);
            if (tmp >= localUtils[i - 1]) {
                tmp = tmp - localUtils[i - 1];
            } else {
                tmp = 0;
            }
            nextInterestRate +=
                (tmp * (localRates[i] - localRates[i - 1])) /
                (localUtils[i] - localUtils[i - 1]);
        }
    }

    function _utilizationRate(
        uint256 assetBorrow,
        uint256 assetSupply
    ) internal view returns (uint256) {
        if (assetBorrow != 0 && assetSupply != 0) {
            // U = total_borrow / total_supply
            return (assetBorrow * WEI_PERCENT_UNIT) / assetSupply;
        }
        return 0;
    }

    function _getActualTokenPrice() internal view returns (uint256) {
        if (atpTokenTotalSupply == 0) {
            return initialAtpPrice;
        } else {
            return
                ((pTokenTotalSupply - loss) * WEI_UNIT) / atpTokenTotalSupply;
        }
    }

    function _getInterestTokenPrice() internal view returns (uint256) {
        if (itpTokenTotalSupply == 0) {
            return initialItpPrice;
        } else {
            return
                ((pTokenTotalSupply +
                    IInterestVault(interestVaultAddress)
                        .claimableTokenInterest()) * WEI_UNIT) /
                itpTokenTotalSupply;
        }
    }

    function _getInterestForwPrice() internal view returns (uint256) {
        if (ifpTokenTotalSupply == 0) {
            return initialIfpPrice;
        } else {
            return
                ((pTokenTotalSupply +
                    ((IInterestVault(interestVaultAddress)
                        .claimableForwInterest() * lambda) / WEI_UNIT)) *
                    WEI_UNIT) / ifpTokenTotalSupply;
        }
    }

    function _currentSupply() internal view returns (uint256) {
        return pTokenTotalSupply - _totalBorrowAmount() - loss;
    }

    function _totalBorrowAmount() internal view returns (uint256) {
        return IAPHCore(coreAddress).poolStats(address(this)).totalBorrowAmount;
    }

    function _getPoolRankInfo(
        uint256 nftId
    ) internal view returns (StakePoolBase.RankInfo memory) {
        return
            IStakePool(IMembership(membershipAddress).currentPool()).rankInfos(
                lenders[nftId].rank
            );
    }

    function _getNFTRankInfo(
        uint256 nftId
    ) internal view returns (StakePoolBase.RankInfo memory) {
        return
            IStakePool(IMembership(membershipAddress).currentPool()).rankInfos(
                _getNFTRank(nftId)
            );
    }

    function _getNFTRank(uint256 nftId) internal view returns (uint8) {
        return IMembership(membershipAddress).getRank(nftId);
    }

    function _NFTOwner(uint256 nftId) internal view returns (address) {
        return IMembership(membershipAddress).ownerOf(nftId);
    }

    function _getUsableToken(
        address owner,
        uint256 nftId
    ) internal view returns (uint256) {
        return IMembership(membershipAddress).usableTokenId(owner, nftId);
    }
}
