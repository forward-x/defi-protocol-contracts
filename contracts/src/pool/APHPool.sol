// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./PoolBaseFunc.sol";

import "./PoolSetting.sol";
import "./APHPoolProxy.sol";
import "./InterestVault.sol";

contract APHPool is PoolBaseFunc, APHPoolProxy, PoolSetting {
    constructor() initializer {}

    /**
      @dev Function for set initial value.

      NOTE: This function must be call after deploy by deployer.
     */
    function initialize(
        address _tokenAddress,
        address _coreAddress,
        address _membershipAddress,
        address _forwAddress,
        address _wethAddress,
        address _wethHandlerAddress,
        uint256 _blockTime
    ) external virtual initializer {
        require(
            _tokenAddress != address(0),
            "APHPool/initialize/tokenAddress-zero-address"
        );
        require(
            _coreAddress != address(0),
            "APHPool/initialize/coreAddress-zero-address"
        );
        require(
            _membershipAddress != address(0),
            "APHPool/initialize/membership-zero-address"
        );
        tokenAddress = _tokenAddress;
        coreAddress = _coreAddress;
        membershipAddress = _membershipAddress;
        noTimelockManager = msg.sender;
        configTimelockManager = msg.sender;
        addressTimelockManager = msg.sender;

        forwAddress = _forwAddress;
        interestVaultAddress = address(
            new InterestVault(
                tokenAddress,
                forwAddress,
                coreAddress,
                msg.sender
            )
        );
        require(_blockTime != 0, "_blockTime cannot be zero");
        BLOCK_TIME = _blockTime;

        WEI_UNIT = 10 ** 18;
        WEI_PERCENT_UNIT = 10 ** 20;
        initialAtpPrice = WEI_UNIT;
        initialItpPrice = WEI_UNIT;
        initialIfpPrice = WEI_UNIT;
        lambda = 1 ether / 100;
        __AssetHandler_init_unchained(_wethAddress, _wethHandlerAddress);
        __ReentrancyGuard_init_unchained();

        emit Initialize(
            msg.sender,
            coreAddress,
            interestVaultAddress,
            membershipAddress,
            _tokenAddress
        );
        emit TransferNoTimelockManager(address(0), noTimelockManager);
        emit TransferConfigTimelockManager(address(0), configTimelockManager);
        emit TransferAddressTimelockManager(address(0), addressTimelockManager);

        emit SetForwAddress(msg.sender, address(0), forwAddress);
        emit SetBlockTime(msg.sender, 0, _blockTime);
    }

    /**
      @dev Returns price to calculate atpToken mint/burn compared to pToken deposit/withdraw
      NOTE: calculated by (pToken - loss)/atpToken
     */
    function getActualTokenPrice() external view returns (uint256) {
        return _getActualTokenPrice();
    }

    /**
      @dev Returns lending interest rate if lender deposit more token to APHPool

      NOTE: if depositAmount is 0, this return current lending interest rate
     */
    function getNextLendingInterest(
        uint256 depositAmount
    ) external view returns (uint256) {
        return _getNextLendingInterest(depositAmount);
    }

    /**
      @dev Returns forw interest rate if lender deposit more token to APHPool

      NOTE: if depositAmount is 0, this return current forw interest rate
     */
    function getNextLendingForwInterest(
        uint256 depositAmount,
        uint256 forwPriceRate,
        uint256 forwPricePrecision
    ) external view returns (uint256) {
        return
            _getNextLendingForwInterest(
                depositAmount,
                forwPriceRate,
                forwPricePrecision
            );
    }

    /**
      @dev Returns borrowing interest rate if borrower borrow more token from APHPool

      NOTE: if borrowAmount is 0, this return current borrowing interest rate
     */
    function getNextBorrowingInterest(
        uint256 borrowAmount
    ) external view returns (uint256) {
        return _getNextBorrowingInterest(borrowAmount);
    }

    /**
      @dev Returns borrowing interest rate and interest owedPerDay if borrower borrow more token from APHPool
      NOTE: if borrowAmount is 0, this return current borrowing interest rate and interest owedPerDay
     */
    function calculateInterest(
        uint256 borrowAmount
    ) external view returns (uint256, uint256) {
        return _calculateBorrowInterest(borrowAmount);
    }

    /**
      @dev Returns price to calculate itpToken mint/burn compared to pToken deposit/withdraw
      NOTE: calculated by (pToken + claimableTokenInterest)/itpToken
     */
    function getInterestTokenPrice() external view returns (uint256) {
        return _getInterestTokenPrice();
    }

    /**
      @dev Returns price to calculate ifpToken mint/burn compared to pToken deposit/withdraw
      NOTE: calculated by (pToken + claimableForwInterest)/ifpToken
     */
    function getInterestForwPrice() external view returns (uint256) {
        return _getInterestForwPrice();
    }

    /**
      @dev Returns available token for lending
     */
    function currentSupply() external view returns (uint256) {
        return _currentSupply();
    }

    /**
      @dev Returns utilizationRate which is ratio between total token borrowed and total token lent
     */
    function utilizationRate() external view returns (uint256) {
        return _utilizationRate(_totalBorrowAmount(), pTokenTotalSupply);
    }

    /**
      @dev Returns claimable token interest and forw interest
     */
    function claimableInterest(
        uint256 nftId
    ) external view returns (uint256 tokenInterest, uint256 forwInterest) {
        PoolTokens memory tokenHolder = tokenHolders[nftId];

        if (
            (tokenHolder.itpToken * _getInterestTokenPrice()) / WEI_UNIT >=
            tokenHolder.pToken
        ) {
            tokenInterest =
                ((tokenHolder.itpToken * _getInterestTokenPrice()) / WEI_UNIT) -
                tokenHolder.pToken;
        } else {
            tokenInterest = 0;
        }
        if (
            ((tokenHolder.ifpToken * _getInterestForwPrice()) / WEI_UNIT) >=
            tokenHolder.pToken
        ) {
            forwInterest =
                ((tokenHolder.ifpToken * _getInterestForwPrice()) / WEI_UNIT) -
                tokenHolder.pToken;
            forwInterest = (forwInterest * WEI_UNIT) / lambda;
        } else {
            forwInterest = 0;
        }
    }
}
