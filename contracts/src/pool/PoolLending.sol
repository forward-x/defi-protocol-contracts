// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./PoolBaseFunc.sol";
import "./event/PoolLendingEvent.sol";

contract PoolLending is PoolBaseFunc, PoolLendingEvent {
    // external function
    /**
      @dev Function to update lender rank when users stake forw token to stakePool and achieve new rank.
            This function claim all forw interest + bonus back to user, while
            claim all token interest + bonus and deposit them back to lending pool.
     */
    function activateRank(
        uint256 nftId
    )
        external
        nonReentrant
        whenFuncNotPaused(msg.sig)
        settleForwInterest
        returns (uint8)
    {
        nftId = _getUsableToken(msg.sender, nftId);
        (WithdrawResult memory result, uint8 newRank) = _activateRank(
            msg.sender,
            nftId
        );
        // transfer forw interest
        _transferFromOut(
            interestVaultAddress,
            msg.sender,
            forwAddress,
            result.forwInterest
        );
        // transfer forw bonus from forwDis
        _transferFromOut(
            IAPHCore(coreAddress).forwDistributorAddress(),
            msg.sender,
            forwAddress,
            result.forwInterestBonus
        );

        _transferFromOut(
            interestVaultAddress,
            address(this),
            tokenAddress,
            result.tokenInterest + result.tokenInterestBonus
        );
        return newRank;
    }

    /**
      @dev Function to deposit token to APHPool, when users deposit token, pool generates
            pToken, itpToken and ifpToken in proportion to users.
      
      NOTE: users must have nft before deposit
     */
    function deposit(
        uint256 nftId,
        uint256 depositAmount
    )
        external
        payable
        nonReentrant
        whenFuncNotPaused(msg.sig)
        settleForwInterest
        returns (
            uint256 mintedP,
            uint256 mintedAtp,
            uint256 mintedItp,
            uint256 mintedIfp
        )
    {
        require(
            tokenAddress == wethAddress || msg.value == 0,
            "PoolLending/no-support-transfering-ether-in"
        );
        nftId = _getUsableToken(msg.sender, nftId);

        if (tokenHolders[nftId].pToken != 0) {
            require(
                lenders[nftId].rank == _getNFTRank(nftId),
                "PoolBaseFunc/nft-rank-not-match"
            );
        } else {
            lenders[nftId].rank = _getNFTRank(nftId);
            lenders[nftId].updatedTimestamp = uint64(block.timestamp);
        }

        _transferFromIn(msg.sender, address(this), tokenAddress, depositAmount);
        (mintedP, mintedAtp, mintedItp, mintedIfp) = _deposit(
            msg.sender,
            nftId,
            depositAmount
        );
    }

    /**
      @dev Function to withdraw token from APHPool, wheb users withdraw token, pool burns
            pToken, itpToken and ifpToken in proportion to users.
            If users withdraws all deposited token, APHPool automatically claim all 
            token and forw interest back to user.

      NOTE: users must have nft before withdraw
     */
    function withdraw(
        uint256 nftId,
        uint256 withdrawAmount
    )
        external
        nonReentrant
        whenFuncNotPaused(msg.sig)
        settleForwInterest
        returns (WithdrawResult memory)
    {
        nftId = _getUsableToken(msg.sender, nftId);
        WithdrawResult memory result = _withdraw(
            msg.sender,
            nftId,
            withdrawAmount
        );

        // transfer principal
        _transferOut(msg.sender, tokenAddress, result.principle);
        // transfer token interest
        _transferFromOut(
            interestVaultAddress,
            msg.sender,
            tokenAddress,
            result.tokenInterest + result.tokenInterestBonus
        );
        // transfer forw interest
        _transferFromOut(
            interestVaultAddress,
            msg.sender,
            forwAddress,
            result.forwInterest
        );
        // transfer forw bonus from forwDis
        _transferFromOut(
            IAPHCore(coreAddress).forwDistributorAddress(),
            msg.sender,
            forwAddress,
            result.forwInterestBonus
        );
        return result;
    }

    /**
      @dev Fuction to claim all token and forw interest back to user.
     */
    function claimAllInterest(
        uint256 nftId
    )
        external
        nonReentrant
        whenFuncNotPaused(msg.sig)
        settleForwInterest
        returns (WithdrawResult memory result)
    {
        nftId = _getUsableToken(msg.sender, nftId);
        result = _claimAllInterest(msg.sender, nftId);

        // transfer tokenInterest and bonus
        _transferFromOut(
            interestVaultAddress,
            msg.sender,
            tokenAddress,
            result.tokenInterest + result.tokenInterestBonus
        );

        // transfer forwInterest
        _transferFromOut(
            interestVaultAddress,
            msg.sender,
            forwAddress,
            result.forwInterest
        );

        // transfer forwInterest bonus
        _transferFromOut(
            IAPHCore(coreAddress).forwDistributorAddress(),
            msg.sender,
            forwAddress,
            result.forwInterestBonus
        );
        return result;
    }

    /**
      @dev Fuction to claim token interest, add-on with token interest bonus which is calculated
            from amount of token interest claimed and %bonus from current lender rank.
     */
    function claimTokenInterest(
        uint256 nftId,
        uint256 claimAmount
    )
        external
        nonReentrant
        whenFuncNotPaused(msg.sig)
        settleForwInterest
        returns (WithdrawResult memory)
    {
        nftId = _getUsableToken(msg.sender, nftId);
        WithdrawResult memory result = _claimTokenInterest(
            msg.sender,
            nftId,
            claimAmount
        );
        _transferFromOut(
            interestVaultAddress,
            msg.sender,
            tokenAddress,
            result.tokenInterest + result.tokenInterestBonus
        );
        return result;
    }

    /**
      @dev Fuction to claim forw interest, add-on with forw interest bonus which is calculated
            from amount of forw interest claimed and %bonus from current lender rank.
     */
    function claimForwInterest(
        uint256 nftId,
        uint256 claimAmount
    )
        external
        nonReentrant
        whenFuncNotPaused(msg.sig)
        settleForwInterest
        returns (WithdrawResult memory)
    {
        nftId = _getUsableToken(msg.sender, nftId);
        WithdrawResult memory result = _claimForwInterest(
            msg.sender,
            nftId,
            claimAmount
        );

        _transferFromOut(
            interestVaultAddress,
            msg.sender,
            forwAddress,
            result.forwInterest
        );
        _transferFromOut(
            IAPHCore(coreAddress).forwDistributorAddress(),
            msg.sender,
            forwAddress,
            result.forwInterestBonus
        );

        return result;
    }

    // getter function

    // internal function
    function _activateRank(
        address receiver,
        uint256 nftId
    ) internal returns (WithdrawResult memory, uint8) {
        Lend storage lender = lenders[nftId];
        uint8 oldRank = lender.rank;
        uint8 newRank = _getNFTRank(nftId);

        require(lender.rank != newRank, "PoolLending/invalid-rank");
        WithdrawResult memory interestResult = _claimTokenInterest(
            receiver,
            nftId,
            type(uint256).max
        );

        // Redeposit token interest and bonus back to pool
        uint256 depositAmount = interestResult.tokenInterest +
            interestResult.tokenInterestBonus;
        if (depositAmount > 0) {
            _deposit(receiver, nftId, depositAmount);
        }
        WithdrawResult memory result = _claimForwInterest(
            receiver,
            nftId,
            type(uint256).max
        );

        lender.rank = newRank;
        lender.updatedTimestamp = uint64(block.timestamp);

        // add tokenInt to result
        result.tokenInterest = interestResult.tokenInterest;
        result.tokenInterestBonus = interestResult.tokenInterestBonus;

        emit ActivateRank(receiver, nftId, oldRank, newRank);
        return (result, newRank);
    }

    function _deposit(
        address receiver,
        uint256 nftId,
        uint256 depositAmount
    )
        internal
        returns (
            uint256 pMintAmount,
            uint256 atpMintAmount,
            uint256 itpMintAmount,
            uint256 ifpMintAmount
        )
    {
        require(depositAmount > 0, "PoolLending/deposit-amount-is-zero");

        Lend storage lend = lenders[nftId];

        uint256 atpPrice = _getActualTokenPrice();
        uint256 itpPrice = _getInterestTokenPrice();
        uint256 ifpPrice = _getInterestForwPrice();

        //mint ip, atp, itp, ifp
        pMintAmount = _mintPToken(receiver, nftId, depositAmount);

        atpMintAmount = _mintAtpToken(
            receiver,
            nftId,
            ((depositAmount * WEI_UNIT) / atpPrice),
            atpPrice
        );

        itpMintAmount = _mintItpToken(
            receiver,
            nftId,
            ((depositAmount * WEI_UNIT) / itpPrice),
            itpPrice
        );

        ifpMintAmount = _mintIfpToken(
            receiver,
            nftId,
            ((depositAmount * WEI_UNIT) / ifpPrice),
            ifpPrice
        );

        lend.updatedTimestamp = uint64(block.timestamp);

        emit Deposit(
            receiver,
            nftId,
            depositAmount,
            pMintAmount,
            atpMintAmount,
            itpMintAmount,
            ifpMintAmount
        );
    }

    function _withdraw(
        address receiver,
        uint256 nftId,
        uint256 withdrawAmount
    ) internal returns (WithdrawResult memory) {
        PoolTokens storage tokenHolder = tokenHolders[nftId];

        uint256 atpPrice = _getActualTokenPrice();
        uint256 itpPrice = _getInterestTokenPrice();
        uint256 ifpPrice = _getInterestForwPrice();

        WithdrawResult memory interestResult;

        // If withdraw all lending amount, all interests is claimed
        if (withdrawAmount >= tokenHolder.pToken) {
            interestResult = _claimAllInterest(receiver, nftId);
            withdrawAmount = tokenHolder.pToken;
        }

        uint256 actualWithdrawAmount = tokenHolder.pToken > 0
            ? MathUpgradeable.min(
                (tokenHolder.atpToken * atpPrice * withdrawAmount) /
                    (tokenHolder.pToken * WEI_UNIT),
                tokenHolder.pToken
            )
            : 0;

        require(
            actualWithdrawAmount <= _currentSupply(),
            "PoolLending/pool-supply-insufficient"
        );

        uint256 itpBurnAmount = _burnItpToken(
            receiver,
            nftId,
            (withdrawAmount * WEI_UNIT) / itpPrice,
            itpPrice
        );

        uint256 ifpBurnAmount = _burnIfpToken(
            receiver,
            nftId,
            (withdrawAmount * WEI_UNIT) / ifpPrice,
            ifpPrice
        );

        uint256 atpBurnAmount = tokenHolder.pToken > 0
            ? ((withdrawAmount * tokenHolder.atpToken) / (tokenHolder.pToken))
            : 0;
        atpBurnAmount = _burnAtpToken(receiver, nftId, atpBurnAmount, atpPrice);

        uint256 pBurnAmount = _burnPToken(receiver, nftId, withdrawAmount);

        uint256 lossBurnAmount = withdrawAmount - actualWithdrawAmount;
        loss -= lossBurnAmount;

        IAPHCore(coreAddress).addLossInUSD(nftId, lossBurnAmount);

        emit Withdraw(
            receiver,
            nftId,
            actualWithdrawAmount,
            pBurnAmount,
            atpBurnAmount,
            lossBurnAmount,
            itpBurnAmount,
            ifpBurnAmount
        );

        return
            WithdrawResult({
                principle: actualWithdrawAmount,
                tokenInterest: interestResult.tokenInterest,
                forwInterest: interestResult.forwInterest,
                pTokenBurn: pBurnAmount,
                atpTokenBurn: atpBurnAmount,
                lossBurn: lossBurnAmount,
                itpTokenBurn: itpBurnAmount + interestResult.itpTokenBurn,
                ifpTokenBurn: ifpBurnAmount + interestResult.ifpTokenBurn,
                tokenInterestBonus: interestResult.tokenInterestBonus,
                forwInterestBonus: interestResult.forwInterestBonus
            });
    }

    function _claimAllInterest(
        address receiver,
        uint256 nftId
    ) internal returns (WithdrawResult memory) {
        WithdrawResult memory tokenWithdrawResult = _claimTokenInterest(
            receiver,
            nftId,
            type(uint256).max
        );

        WithdrawResult memory forwWithdrawResult = _claimForwInterest(
            receiver,
            nftId,
            type(uint256).max
        );

        return
            WithdrawResult({
                principle: 0,
                tokenInterest: tokenWithdrawResult.tokenInterest,
                forwInterest: forwWithdrawResult.forwInterest,
                pTokenBurn: 0,
                atpTokenBurn: 0,
                lossBurn: 0,
                itpTokenBurn: tokenWithdrawResult.itpTokenBurn,
                ifpTokenBurn: forwWithdrawResult.ifpTokenBurn,
                tokenInterestBonus: tokenWithdrawResult.tokenInterestBonus,
                forwInterestBonus: forwWithdrawResult.forwInterestBonus
            });
    }

    function _claimTokenInterest(
        address receiver,
        uint256 nftId,
        uint256 claimAmount
    ) internal returns (WithdrawResult memory) {
        uint256 itpPrice = _getInterestTokenPrice();
        PoolTokens storage tokenHolder = tokenHolders[nftId];

        uint256 claimableAmount;
        if (
            ((tokenHolder.itpToken * itpPrice) / WEI_UNIT) > tokenHolder.pToken
        ) {
            claimableAmount =
                ((tokenHolder.itpToken * itpPrice) / WEI_UNIT) -
                tokenHolder.pToken;
        }

        claimAmount = MathUpgradeable.min(claimAmount, claimableAmount);

        uint256 burnAmount = _burnItpToken(
            receiver,
            nftId,
            (claimAmount * WEI_UNIT) / itpPrice,
            itpPrice
        );
        uint256 bonusAmount = (claimAmount *
            _getPoolRankInfo(nftId).interestBonusLending) / WEI_PERCENT_UNIT;

        uint256 feeSpread = IAPHCore(coreAddress).feeSpread();
        uint256 profitAmount = ((claimAmount * feeSpread) /
            (WEI_PERCENT_UNIT - feeSpread)) - bonusAmount;

        IInterestVault(interestVaultAddress).withdrawTokenInterest(
            claimAmount,
            bonusAmount,
            profitAmount
        );

        emit ClaimTokenInterest(
            receiver,
            nftId,
            claimAmount,
            bonusAmount,
            burnAmount
        );

        return
            WithdrawResult({
                principle: 0,
                tokenInterest: claimAmount,
                forwInterest: 0,
                pTokenBurn: 0,
                atpTokenBurn: 0,
                lossBurn: 0,
                itpTokenBurn: burnAmount,
                ifpTokenBurn: 0,
                tokenInterestBonus: bonusAmount,
                forwInterestBonus: 0
            });
    }

    function _claimForwInterest(
        address receiver,
        uint256 nftId,
        uint256 claimAmount
    ) internal returns (WithdrawResult memory) {
        uint256 ifpPrice = _getInterestForwPrice();
        PoolTokens storage tokenHolder = tokenHolders[nftId];

        uint256 claimableAmount;
        if (
            ((tokenHolder.ifpToken * ifpPrice) / WEI_UNIT) > tokenHolder.pToken
        ) {
            claimableAmount =
                ((tokenHolder.ifpToken * ifpPrice) / WEI_UNIT) -
                tokenHolder.pToken;
        }

        claimableAmount = (claimableAmount * WEI_UNIT) / lambda;

        claimAmount = MathUpgradeable.min(claimAmount, claimableAmount);

        uint256 burnAmount = _burnIfpToken(
            receiver,
            nftId,
            ((claimAmount * WEI_UNIT) * lambda) / (ifpPrice * WEI_UNIT),
            ifpPrice
        );
        uint256 bonusAmount = (claimAmount *
            _getPoolRankInfo(nftId).forwardBonusLending) / WEI_PERCENT_UNIT;

        IInterestVault(interestVaultAddress).withdrawForwInterest(claimAmount);

        emit ClaimForwInterest(
            receiver,
            nftId,
            claimAmount,
            bonusAmount,
            burnAmount
        );

        return
            WithdrawResult({
                principle: 0,
                tokenInterest: 0,
                forwInterest: claimAmount,
                pTokenBurn: 0,
                atpTokenBurn: 0,
                lossBurn: 0,
                itpTokenBurn: 0,
                ifpTokenBurn: burnAmount,
                tokenInterestBonus: 0,
                forwInterestBonus: bonusAmount
            });
    }
}
