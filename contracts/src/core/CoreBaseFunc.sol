// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./CoreBase.sol";

contract CoreBaseFunc is CoreBase {
    // Pause / unPause
    function pause(bytes4 _func) external onlyNoTimelockManager {
        require(_func != bytes4(0), "CoreBaseFunc/msg.sig-func-is-zero");
        _pause(_func);
    }

    function unPause(bytes4 _func) external onlyNoTimelockManager {
        require(_func != bytes4(0), "CoreBaseFunc/msg.sig-func-is-zero");
        _unpause(_func);
    }

    /**
      @dev Calculate amount of forw token when settles by multiplying forwDisPerBlock
            with block diff from last settle to current block.
            
            If nextForwDisPerBlock is set and current block is more than target block, 
            newForwDisPerBlock is used to calculated from target block.
     */
    function _settleForwInterest() internal returns (uint256 forwAmount) {
        if (lastSettleForw[msg.sender] != 0) {
            uint256 targetBlock = nextForwDisPerBlock[msg.sender].targetBlock;
            uint256 newForwDisPerBlock = nextForwDisPerBlock[msg.sender].amount;

            if (targetBlock != 0) {
                if (targetBlock >= block.number) {
                    forwAmount =
                        (block.number - lastSettleForw[msg.sender]) *
                        forwDisPerBlock[msg.sender];
                } else {
                    forwAmount =
                        ((targetBlock - lastSettleForw[msg.sender]) *
                            forwDisPerBlock[msg.sender]) +
                        ((block.number - targetBlock) * newForwDisPerBlock);
                }

                if (targetBlock <= block.number) {
                    forwDisPerBlock[msg.sender] = newForwDisPerBlock;
                    nextForwDisPerBlock[msg.sender] = NextForwDisPerBlock(0, 0);
                }
            } else {
                forwAmount =
                    (block.number - lastSettleForw[msg.sender]) *
                    forwDisPerBlock[msg.sender];
            }
        }

        lastSettleForw[msg.sender] = block.number;

        if (forwAmount != 0) {
            IInterestVault(IAPHPool(msg.sender).interestVaultAddress())
                .settleInterest(0, 0, forwAmount);
        }
    }

    /**
      @dev Returns usable nftId of caller
     */
    function _getUsableToken(
        address owner,
        uint256 nftId
    ) internal view returns (uint256) {
        return IMembership(membershipAddress).usableTokenId(owner, nftId);
    }

    /**
      @dev Returns owner of the given nftId
     */
    function _getTokenOwnership(uint256 nftId) internal view returns (address) {
        return IMembership(membershipAddress).ownerOf(nftId);
    }

    /**
      @dev Returns boolean which represent that the given loan can be liquidated or not.
            LTV is calculated by (borrowAmount + interest)/(collateralAmount) of which all
            value are in the same currency.
     */
    function _isLoanLTVExceedTargetLTV(
        uint256 borrowAmount,
        uint256 collateralAmount,
        uint256 interestOwed,
        uint256 targetLTV,
        uint256 rate,
        uint256 precision
    ) internal view returns (bool) {
        uint256 loanLTV = ((borrowAmount + interestOwed) *
            WEI_PERCENT_UNIT *
            precision) / (collateralAmount * rate);
        return loanLTV > targetLTV ? true : false;
    }

    /**
      @dev Returns price and precision between tokenA and tokenB
     */
    function _queryRate(
        address tokenA,
        address tokenB
    ) internal view returns (uint256 price, uint256 precision) {
        return IPriceFeed(priceFeedAddress).queryRate(tokenA, tokenB);
    }

    /**
      @dev Returns price between token and USD
     */
    function _queryRateUSD(
        address token
    ) internal view returns (uint256 price, uint256 precision) {
        (price, precision) = IPriceFeed(priceFeedAddress).queryRateUSD(token);
    }

    function _getInterestVault(
        address poolAddress
    ) internal view returns (address interestVaultAddress) {
        interestVaultAddress = IAPHPool(poolAddress).interestVaultAddress();
    }

    function _settleInterestAtInterestVault(
        address poolAddress,
        uint256 tokenInterest,
        uint256 forwInterest
    )
        internal
        returns (uint256 claimableTokenInterest, uint256 heldTokenInterest)
    {
        if (tokenInterest != 0) {
            heldTokenInterest = (tokenInterest * feeSpread) / WEI_PERCENT_UNIT;
            claimableTokenInterest = tokenInterest - heldTokenInterest;
        }

        IInterestVault(_getInterestVault(poolAddress)).settleInterest(
            claimableTokenInterest,
            heldTokenInterest,
            forwInterest
        );
    }
}
