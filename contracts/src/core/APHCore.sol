// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./CoreBaseFunc.sol";
import "./APHCoreProxy.sol";
import "./CoreSetting.sol";
import "./event/CoreEvent.sol";

contract APHCore is CoreBaseFunc, CoreSetting, APHCoreProxy, CoreEvent {
    constructor() initializer {}

    /**
      @dev Function for set initial value.

      NOTE: This function must be call after deploy by deployer.
     */
    function initialize(
        address _membershipAddress,
        address _forwAddress,
        address _routerAddress,
        address _wethAddress,
        address _wethHandlerAddress
    ) external initializer {
        noTimelockManager = msg.sender;
        configTimelockManager = msg.sender;
        addressTimelockManager = msg.sender;

        WEI_UNIT = 10 ** 18;
        WEI_PERCENT_UNIT = 10 ** 20;

        feeSpread = 10 ether;
        loanDuration = 28 days;
        advancedInterestDuration = 3 days;

        routerAddress = _routerAddress;
        // routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // mainnet

        forwAddress = _forwAddress;

        membershipAddress = _membershipAddress;

        fixSlippage = 10 ether;

        //AssetHandler_init_unchained parse 2 parameter _wethAddress ,_wethHandler
        __AssetHandler_init_unchained(_wethAddress, _wethHandlerAddress);
        __ReentrancyGuard_init_unchained();

        emit SetRouterAddress(msg.sender, address(0), routerAddress);
        emit TransferNoTimelockManager(address(0), noTimelockManager);
        emit TransferConfigTimelockManager(address(0), configTimelockManager);
        emit TransferAddressTimelockManager(address(0), addressTimelockManager);
        emit SetLoanDuration(msg.sender, 0, loanDuration);
        emit SetFeeSpread(msg.sender, 0, feeSpread);
        emit SetAdvancedInterestDuration(
            msg.sender,
            0,
            advancedInterestDuration
        );
        emit SetMembershipAddress(msg.sender, address(0), _membershipAddress);
        emit SetFixSlippage(msg.sender, 0, fixSlippage);

        emit SetForwAddress(msg.sender, address(0), forwAddress);
    }

    /**
      @dev Function for distribute forw token to APHPool.

      NOTE: This function can be called only by registered APHPool (proxy)
     */
    function settleForwInterest() external {
        require(
            poolToAsset[msg.sender] != address(0),
            "APHCore/caller-is-not-pool"
        );

        address interestVaultAddress = IAPHPool(msg.sender)
            .interestVaultAddress();
        uint256 forwAmount = _settleForwInterest();
        _transferFromOut(
            forwDistributorAddress,
            interestVaultAddress,
            forwAddress,
            forwAmount
        );

        emit SettleForwInterest(
            address(this),
            interestVaultAddress,
            forwDistributorAddress,
            forwAddress,
            forwAmount
        );
    }

    /**
      @dev Function for add user loss from APHPool.

      NOTE: This function can be called only by registered APHPool (proxy)
     */
    function addLossInUSD(uint256 nftId, uint256 lossAmount) external {
        require(
            poolToAsset[msg.sender] != address(0),
            "APHCore/caller-is-not-pool"
        );
        uint256 rate;
        {
            (rate, ) = _queryRateUSD(IAPHPool(msg.sender).tokenAddress());
        }
        lossAmount = (lossAmount * rate) / WEI_UNIT;
        nftsLossInUSD[nftId] = nftsLossInUSD[nftId] + lossAmount;
        totalLossInUSD = totalLossInUSD + lossAmount;

        emit AddLossInUSD(address(this), msg.sender, nftId, lossAmount);
    }

    // Getter function
    /**
      @dev Returns Loan data of given nftId and loanId
     */
    function getLoan(
        uint256 nftId,
        uint256 loanId
    ) external view returns (Loan memory) {
        return loans[nftId][loanId];
    }

    /**
      @dev Returns LoanExt data of given nftId and loanId
     */
    function getLoanExt(
        uint256 nftId,
        uint256 loanId
    ) external view returns (LoanExt memory) {
        return loanExts[nftId][loanId];
    }

    /**
      @dev Returns LoanConfig data of given borrowToken and collateralToken
     */
    function getLoanConfig(
        address borrowTokenAddress,
        address collateralTokenAddress
    ) external view returns (LoanConfig memory) {
        return loanConfigs[borrowTokenAddress][collateralTokenAddress];
    }

    /**
      @dev Returns All active loan of given nftId
     */
    function getActiveLoans(
        uint256 nftId,
        uint256 cursor,
        uint256 resultsPerPage
    ) external view returns (Loan[] memory activeLoans, uint256 newCursor) {
        uint256 loanLength = currentLoanIndex[nftId];
        require(cursor > 0, "APHCore/cursor-must-be-greater-than-zero");
        require(cursor <= loanLength, "APHCore/cursor-out-of-range");
        require(resultsPerPage > 0, "resultsPerPage-cannot-be-zero");

        uint256 index;
        uint256 count;
        for (
            index = cursor;
            index <= loanLength && count < resultsPerPage;
            index++
        ) {
            if (loanExts[nftId][index].active) {
                count++;
            }
        }
        activeLoans = new Loan[](count);
        count = 0;
        for (
            index = cursor;
            index <= loanLength && count < resultsPerPage;
            index++
        ) {
            if (loanExts[nftId][index].active) {
                activeLoans[count] = loans[nftId][index];
                count++;
            }
        }
        return (activeLoans, index);
    }

    /**
      @dev Returns all registered APHPool (proxy) in protocol
     */
    function getPoolList() external view returns (address[] memory) {
        return poolList;
    }

    /**
      @dev Returns loan's current LTV of the given loanId and nftId.

      NOTE: The calculated LTV include unsettled interest which is calculated 
      from interestOwed multiply with amount of time since last settled.
     */
    function getLoanCurrentLTV(
        uint256 loanId,
        uint256 nftId
    ) external view returns (uint256 ltv) {
        Loan memory loan = loans[nftId][loanId];
        LoanConfig memory loanConfig = loanConfigs[loan.borrowTokenAddress][
            loan.collateralTokenAddress
        ];
        (uint256 rate, uint256 precision) = IPriceFeed(priceFeedAddress)
            .queryRate(loan.collateralTokenAddress, loan.borrowTokenAddress);
        if (loan.collateralAmount == 0 || rate == 0) {
            return 0;
        }

        uint256 totalInterest = loan.interestOwed;
        if (block.timestamp <= loan.rolloverTimestamp) {
            // loan is not overdue yet
            totalInterest += ((loan.owedPerDay *
                (block.timestamp - loan.lastSettleTimestamp)) / 1 days);
        } else {
            // loan is overdue
            totalInterest += ((loan.owedPerDay *
                (loan.rolloverTimestamp - loan.lastSettleTimestamp)) / 1 days);

            totalInterest +=
                ((loan.owedPerDay *
                    (block.timestamp - loan.rolloverTimestamp) *
                    (WEI_PERCENT_UNIT + loanConfig.bountyFeeRate)) / 1 days) /
                WEI_PERCENT_UNIT;
        }
        // +
        //     ((loan.owedPerDay * (block.timestamp - uint256(loan.lastSettleTimestamp))) / 1 days);
        totalInterest = MathUpgradeable.max(loan.minInterest, totalInterest);
        ltv = loan.borrowAmount + totalInterest;
        ltv =
            (ltv * WEI_PERCENT_UNIT * precision) /
            (loan.collateralAmount * rate);
        return ltv;
    }

    /**
      @dev Returns boolean which represents that the given address is registered APHPool (proxy) or not.
     */
    function isPool(address poolAddess) external view returns (bool) {
        return poolToAsset[poolAddess] != address(0);
    }
}
