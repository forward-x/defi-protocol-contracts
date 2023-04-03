// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./PoolBaseFunc.sol";
import "./event/PoolSettingEvent.sol";
import "../../interfaces/IAPHCoreSetting.sol";

contract PoolSetting is PoolBaseFunc, PoolSettingEvent {
    function setBorrowInterestParams(
        uint256[] memory _rates,
        uint256[] memory _utils,
        uint256 _targetSupply
    ) external onlyConfigTimelockManager {
        require(_rates.length == _utils.length, "PoolSetting/length-not-equal");
        require(_rates.length <= 10, "PoolSetting/length-too-high");
        require(_utils[0] == 0, "PoolSetting/invalid-first-util");
        require(
            _utils[_utils.length - 1] == WEI_PERCENT_UNIT,
            "PoolSetting/invalid-last-util"
        );

        for (uint256 i = 1; i < _rates.length; i++) {
            require(_rates[i - 1] <= _rates[i], "PoolSetting/invalid-rate");
            require(_utils[i - 1] < _utils[i], "PoolSetting/invalid-util");
        }

        for (uint256 i = 0; i < _rates.length; i++) {
            rates[i] = _rates[i];
            utils[i] = _utils[i];
        }
        targetSupply = _targetSupply;
        utilsLen = _utils.length;

        emit SetBorrowInterestParams(msg.sender, _rates, _utils, targetSupply);
    }

    function setupLoanConfig(
        address _collateralTokenAddress,
        uint256 _safeLTV,
        uint256 _maxLTV,
        uint256 _liqLTV,
        uint256 _bountyFeeRate
    ) external onlyConfigTimelockManager {
        require(
            _safeLTV < _maxLTV &&
                _maxLTV < _liqLTV &&
                _liqLTV < WEI_PERCENT_UNIT,
            "PoolSetting/invalid-loan-config"
        );

        require(
            _bountyFeeRate <= WEI_PERCENT_UNIT,
            "CoreSetting/_bountyFeeRate-too-high"
        );

        IAPHCoreSetting(coreAddress).setupLoanConfig(
            tokenAddress,
            _collateralTokenAddress,
            _safeLTV,
            _maxLTV,
            _liqLTV,
            _bountyFeeRate
        );

        emit SetLoanConfig(
            msg.sender,
            _collateralTokenAddress,
            _safeLTV,
            _maxLTV,
            _liqLTV,
            _bountyFeeRate
        );
    }

    function setPoolLendingAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = poolLendingAddress;
        poolLendingAddress = _address;

        emit SetPoolLendingAddress(msg.sender, oldAddress, _address);
    }

    function setPoolBorrowingAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = poolBorrowingAddress;
        poolBorrowingAddress = _address;

        emit SetPoolBorrowingAddress(msg.sender, oldAddress, _address);
    }

    function setWETHHandler(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = wethHandler;
        wethHandler = _address;

        emit SetWETHHandler(msg.sender, oldAddress, _address);
    }

    function setMembershipAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = membershipAddress;
        membershipAddress = _address;

        emit SetMembershipAddress(msg.sender, oldAddress, _address);
    }
}
