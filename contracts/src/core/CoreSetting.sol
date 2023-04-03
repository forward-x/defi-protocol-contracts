// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./CoreBaseFunc.sol";
import "./event/CoreSettingEvent.sol";
import "../../externalContract/openzeppelin/upgradeable/SafeERC20Upgradeable.sol";

contract CoreSetting is CoreBaseFunc, CoreSettingEvent {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Set Address
    function setMembershipAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = membershipAddress;
        membershipAddress = _address;

        emit SetMembershipAddress(msg.sender, oldAddress, _address);
    }

    function setPriceFeedAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = priceFeedAddress;
        priceFeedAddress = _address;

        emit SetPriceFeedAddress(msg.sender, oldAddress, _address);
    }

    function setForwDistributorAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = forwDistributorAddress;
        forwDistributorAddress = _address;

        if (oldAddress != address(0)) {
            IERC20Upgradeable(forwAddress).safeApprove(oldAddress, 0);
        }
        IERC20Upgradeable(forwAddress).safeApprove(
            forwDistributorAddress,
            type(uint256).max
        );
        emit SetForwDistributorAddress(msg.sender, oldAddress, _address);
    }

    function setRouterAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = routerAddress;
        routerAddress = _address;

        emit SetRouterAddress(msg.sender, oldAddress, _address);
    }

    function setWETHHandler(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = wethHandler;
        wethHandler = _address;

        emit SetWETHHandler(msg.sender, oldAddress, _address);
    }

    function setCoreBorrowingAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = coreBorrowingAddress;
        coreBorrowingAddress = _address;

        emit SetCoreBorrowingAddress(msg.sender, oldAddress, _address);
    }

    function setFeeController(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = feesController;
        feesController = _address;

        emit SetFeeController(msg.sender, oldAddress, _address);
    }

    // Set value
    function setLoanDuration(
        uint256 _value
    ) external onlyConfigTimelockManager {
        uint256 oldValue = loanDuration;
        loanDuration = _value;

        emit SetLoanDuration(msg.sender, oldValue, _value);
    }

    function setAdvancedInterestDuration(
        uint256 _value
    ) external onlyConfigTimelockManager {
        uint256 oldValue = advancedInterestDuration;
        advancedInterestDuration = _value;

        emit SetAdvancedInterestDuration(msg.sender, oldValue, _value);
    }

    function setFeeSpread(uint256 _value) external onlyConfigTimelockManager {
        require(
            _value <= WEI_PERCENT_UNIT,
            "CoreSetting/value-exceed-100-percent"
        );
        uint256 oldValue = feeSpread;
        feeSpread = _value;

        emit SetFeeSpread(msg.sender, oldValue, _value);
    }

    function setFixSlippage(uint256 _value) external onlyConfigTimelockManager {
        if (_value > WEI_PERCENT_UNIT) {
            revert("CoreSetting/value-exceed-100-percent");
        }
        uint256 oldValue = fixSlippage;
        fixSlippage = _value;
        emit SetFixSlippage(msg.sender, oldValue, _value);
    }

    function registerNewPool(
        address _poolAddress,
        uint256 _amount,
        uint256 _targetBlock
    ) external onlyConfigTimelockManager {
        require(
            poolToAsset[_poolAddress] == address(0),
            "CoreSetting/pool-is-already-exist"
        );

        address assetAddress = IAPHPool(_poolAddress).tokenAddress();
        _approveForRouter(assetAddress);

        poolToAsset[_poolAddress] = assetAddress;
        assetToPool[assetAddress] = _poolAddress;
        swapableToken[assetAddress] = true;
        poolList.push(_poolAddress);

        lastSettleForw[_poolAddress] = block.number;

        _setForwDisPerBlock(_poolAddress, _amount, _targetBlock);

        emit RegisterNewPool(msg.sender, _poolAddress);
    }

    function setForwDisPerBlock(
        address _poolAddress,
        uint256 _amount,
        uint256 _targetBlock
    ) external onlyConfigTimelockManager {
        _setForwDisPerBlock(_poolAddress, _amount, _targetBlock);
    }

    function _setForwDisPerBlock(
        address _poolAddress,
        uint256 _amount,
        uint256 _targetBlock
    ) internal {
        require(
            poolToAsset[_poolAddress] != address(0),
            "CoreSetting/pool-is-not-exist"
        );

        if (_targetBlock == 0) {
            forwDisPerBlock[_poolAddress] = _amount;

            nextForwDisPerBlock[_poolAddress].amount = 0;
            nextForwDisPerBlock[_poolAddress].targetBlock = 0;
        } else {
            require(_targetBlock >= block.number, "CoreSetting/error");

            nextForwDisPerBlock[_poolAddress].amount = _amount;
            nextForwDisPerBlock[_poolAddress].targetBlock = _targetBlock;
        }

        emit SetForwPerBlock(msg.sender, _amount, _targetBlock);
    }

    function setupLoanConfig(
        address _borrowTokenAddress,
        address _collateralTokenAddress,
        uint256 _safeLTV,
        uint256 _maxLTV,
        uint256 _liqLTV,
        uint256 _bountyFeeRate
    ) external {
        require(
            poolToAsset[msg.sender] != address(0) ||
                msg.sender == configTimelockManager,
            "CoreSetting/permission-denied-for-setup-loan-config"
        );

        require(
            _safeLTV < _maxLTV &&
                _maxLTV < _liqLTV &&
                _liqLTV < WEI_PERCENT_UNIT,
            "PoolSetting/invalid-loan-config"
        );

        require(
            _borrowTokenAddress != _collateralTokenAddress &&
                assetToPool[_borrowTokenAddress] != address(0) &&
                assetToPool[_collateralTokenAddress] != address(0),
            "CoreSetting/_borrowTokenAddress-is-not-registered-yet"
        );

        require(
            _bountyFeeRate <= WEI_PERCENT_UNIT,
            "CoreSetting/_bountyFeeRate-too-high"
        );

        LoanConfig memory configOld = loanConfigs[_borrowTokenAddress][
            _collateralTokenAddress
        ];
        LoanConfig storage config = loanConfigs[_borrowTokenAddress][
            _collateralTokenAddress
        ];
        config.borrowTokenAddress = _borrowTokenAddress;
        config.collateralTokenAddress = _collateralTokenAddress;
        config.safeLTV = _safeLTV;
        config.maxLTV = _maxLTV;
        config.liquidationLTV = _liqLTV;
        config.bountyFeeRate = _bountyFeeRate;

        emit SetupLoanConfig(
            msg.sender,
            _borrowTokenAddress,
            _collateralTokenAddress,
            configOld.safeLTV,
            configOld.maxLTV,
            configOld.liquidationLTV,
            configOld.bountyFeeRate,
            config.safeLTV,
            config.maxLTV,
            config.liquidationLTV,
            config.bountyFeeRate
        );
    }

    function approveForRouter(
        address _assetAddress
    ) external onlyAddressTimelockManager {
        require(
            assetToPool[_assetAddress] != address(0),
            "CoreSetting/unsupported-asset"
        );
        _approveForRouter(_assetAddress);
    }

    function _approveForRouter(address _assetAddress) internal {
        IERC20Upgradeable(_assetAddress).safeApprove(
            routerAddress,
            type(uint256).max
        );
        emit ApprovedForRouter(msg.sender, _assetAddress, routerAddress);
    }
}
