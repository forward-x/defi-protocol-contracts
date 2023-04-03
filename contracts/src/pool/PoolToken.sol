// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../externalContract/openzeppelin/upgradeable/MathUpgradeable.sol";

contract PoolToken {
    struct PoolTokens {
        uint256 pToken;
        uint256 atpToken;
        uint256 itpToken;
        uint256 ifpToken;
    }

    // Allocating __gap for futhur variable (need to subtract equal to new state added)
    uint256[10] private __gap_top_poolToken;

    uint256 public pTokenTotalSupply; //                // token represent principal lent to APHPool
    uint256 public atpTokenTotalSupply; //              // token represent printipal (same as pToken) - loss
    uint256 public itpTokenTotalSupply; //              // token represent printipal (same as pToken) + interest (claimable token interest in InterestVault)
    uint256 public ifpTokenTotalSupply; //              // token represent printipal (same as pToken) + interest (claimable forw interest in InterestVault)
    mapping(uint256 => PoolTokens) public tokenHolders; // map nftId -> struct

    uint256[10] private __gap_bottom_poolToken;

    event MintPToken(
        address indexed minter,
        uint256 indexed nftId,
        uint256 amount
    );
    event MintAtpToken(
        address indexed minter,
        uint256 indexed nftId,
        uint256 amount,
        uint256 price
    );
    event MintItpToken(
        address indexed minter,
        uint256 indexed nftId,
        uint256 amount,
        uint256 price
    );
    event MintIfpToken(
        address indexed minter,
        uint256 indexed nftId,
        uint256 amount,
        uint256 price
    );

    event BurnPToken(
        address indexed burner,
        uint256 indexed nftId,
        uint256 amount
    );
    event BurnAtpToken(
        address indexed burner,
        uint256 indexed nftId,
        uint256 amount,
        uint256 price
    );
    event BurnItpToken(
        address indexed burner,
        uint256 indexed nftId,
        uint256 amount,
        uint256 price
    );
    event BurnIfpToken(
        address indexed burner,
        uint256 indexed nftId,
        uint256 amount,
        uint256 price
    );

    // external function
    /**
      @dev Returns pToken's balance of the given nftId
     */
    function balancePTokenOf(uint256 nftId) external view returns (uint256) {
        return tokenHolders[nftId].pToken;
    }

    /**
      @dev Returns atpToken's balance of the given nftId
     */
    function balanceAtpTokenOf(uint256 nftId) external view returns (uint256) {
        return tokenHolders[nftId].atpToken;
    }

    /**
      @dev Returns itpToken's balance of the given nftId
     */
    function balanceItpTokenOf(uint256 nftId) external view returns (uint256) {
        return tokenHolders[nftId].itpToken;
    }

    /**
      @dev Returns ifpToken's balance of the given nftId
     */
    function balanceIfpTokenOf(uint256 nftId) external view returns (uint256) {
        return tokenHolders[nftId].ifpToken;
    }

    // internal function
    function _mintPToken(
        address receiver,
        uint256 nftId,
        uint256 mintAmount
    ) internal returns (uint256) {
        pTokenTotalSupply += mintAmount;
        tokenHolders[nftId].pToken += mintAmount;

        emit MintPToken(receiver, nftId, mintAmount);
        return mintAmount;
    }

    function _mintAtpToken(
        address receiver,
        uint256 nftId,
        uint256 mintAmount,
        uint256 price
    ) internal returns (uint256) {
        atpTokenTotalSupply += mintAmount;
        tokenHolders[nftId].atpToken += mintAmount;

        emit MintAtpToken(receiver, nftId, mintAmount, price);
        return mintAmount;
    }

    function _mintItpToken(
        address receiver,
        uint256 nftId,
        uint256 mintAmount,
        uint256 price
    ) internal returns (uint256) {
        itpTokenTotalSupply += mintAmount;
        tokenHolders[nftId].itpToken += mintAmount;

        emit MintItpToken(receiver, nftId, mintAmount, price);
        return mintAmount;
    }

    function _mintIfpToken(
        address receiver,
        uint256 nftId,
        uint256 mintAmount,
        uint256 price
    ) internal returns (uint256) {
        ifpTokenTotalSupply += mintAmount;
        tokenHolders[nftId].ifpToken += mintAmount;

        emit MintIfpToken(receiver, nftId, mintAmount, price);
        return mintAmount;
    }

    function _burnPToken(
        address burner,
        uint256 nftId,
        uint256 burnAmount
    ) internal returns (uint256) {
        pTokenTotalSupply -= burnAmount;
        tokenHolders[nftId].pToken -= burnAmount;

        emit BurnPToken(burner, nftId, burnAmount);
        return burnAmount;
    }

    function _burnAtpToken(
        address burner,
        uint256 nftId,
        uint256 burnAmount,
        uint256 price
    ) internal returns (uint256) {
        burnAmount = MathUpgradeable.min(
            burnAmount,
            tokenHolders[nftId].atpToken
        );

        atpTokenTotalSupply -= burnAmount;
        tokenHolders[nftId].atpToken -= burnAmount;

        emit BurnAtpToken(burner, nftId, burnAmount, price);
        return burnAmount;
    }

    function _burnItpToken(
        address burner,
        uint256 nftId,
        uint256 burnAmount,
        uint256 price
    ) internal returns (uint256) {
        burnAmount = MathUpgradeable.min(
            burnAmount,
            tokenHolders[nftId].itpToken
        );

        itpTokenTotalSupply -= burnAmount;
        tokenHolders[nftId].itpToken -= burnAmount;

        emit BurnItpToken(burner, nftId, burnAmount, price);
        return burnAmount;
    }

    function _burnIfpToken(
        address burner,
        uint256 nftId,
        uint256 burnAmount,
        uint256 price
    ) internal returns (uint256) {
        burnAmount = MathUpgradeable.min(
            burnAmount,
            tokenHolders[nftId].ifpToken
        );

        ifpTokenTotalSupply -= burnAmount;
        tokenHolders[nftId].ifpToken -= burnAmount;

        emit BurnIfpToken(burner, nftId, burnAmount, price);
        return burnAmount;
    }
}
