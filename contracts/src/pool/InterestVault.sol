// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../externalContract/openzeppelin/non-upgradeable/Ownable.sol";
import "../../externalContract/openzeppelin/non-upgradeable/IERC20.sol";
import "../../externalContract/openzeppelin/non-upgradeable/SafeERC20.sol";
import "../../externalContract/modify/non-upgradeable/SelectorPausable.sol";
import "../../externalContract/modify/non-upgradeable/ManagerTimelock.sol";

import "./event/InterestVaultEvent.sol";

contract InterestVault is
    InterestVaultEvent,
    Ownable,
    SelectorPausable,
    ManagerTimelock
{
    using SafeERC20 for IERC20;

    // NOTE: manager is owner account, owner is pool
    uint256 public claimableTokenInterest;
    uint256 public heldTokenInterest;
    uint256 public actualTokenInterestProfit;
    uint256 public claimableForwInterest;
    uint256 public cumulativeTokenInterestProfit;

    address public tokenAddress;
    address public forwAddress;
    address public protocolAddress;

    modifier onlyProtocol() {
        require(
            msg.sender == protocolAddress,
            "InterestVault/permission-denied"
        );
        _;
    }

    constructor(
        address _token,
        address _forw,
        address _protocol,
        address _initialManager
    ) {
        tokenAddress = _token;
        forwAddress = _forw;
        protocolAddress = _protocol;
        noTimelockManager = _initialManager;
        addressTimelockManager = _initialManager;
        uint256 approveAmount = type(uint256).max;
        _ownerApprove(msg.sender, approveAmount, approveAmount);

        emit SetTokenAddress(msg.sender, address(0), tokenAddress);
        emit SetForwAddress(msg.sender, address(0), forwAddress);
        emit SetProtocolAddress(msg.sender, address(0), protocolAddress);
        emit TransferNoTimelockManager(address(0), noTimelockManager);
        emit TransferAddressTimelockManager(address(0), addressTimelockManager);
    }

    // pause / unPause
    function pause(bytes4 _func) external onlyNoTimelockManager {
        require(_func != bytes4(0), "InterestVault/msg.sig-func-is-zero");
        _pause(_func);
    }

    function unPause(bytes4 _func) external onlyNoTimelockManager {
        require(_func != bytes4(0), "InterestVault/msg.sig-func-is-zero");
        _unpause(_func);
    }

    function setForwAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = forwAddress;
        forwAddress = _address;

        emit SetForwAddress(msg.sender, oldAddress, forwAddress);
    }

    function setTokenAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = tokenAddress;
        tokenAddress = _address;

        emit SetTokenAddress(msg.sender, oldAddress, tokenAddress);
    }

    function setProtocolAddress(
        address _address
    ) external onlyAddressTimelockManager {
        address oldAddress = protocolAddress;
        protocolAddress = _address;

        emit SetProtocolAddress(msg.sender, oldAddress, protocolAddress);
    }

    /**
      @dev Function call by owner (APHPool) for allowing it to transfer token from InterestVault
     */
    function ownerApprove(
        address _pool,
        uint256 tokenApproveAmount,
        uint256 forwApproveAmount
    ) external onlyAddressTimelockManager {
        _ownerApprove(_pool, tokenApproveAmount, forwApproveAmount);
    }

    /**
      @dev Function to settle value of claimable token interest, held token interest
            and claimable forw interest
            Called by APHCore (proxy)
     */
    function settleInterest(
        uint256 _claimableTokenInterest,
        uint256 _heldTokenInterest,
        uint256 _claimableForwInterest
    ) external onlyProtocol {
        _settleInterest(
            _claimableTokenInterest,
            _heldTokenInterest,
            _claimableForwInterest
        );
    }

    /**
      @dev Function to subtract token interest value, calculated from APHPool, and add actual profit
            Called by APHPool (proxy)
     */
    function withdrawTokenInterest(
        uint256 claimable,
        uint256 bonus,
        uint256 profit
    ) external onlyOwner {
        _withdrawTokenInterest(claimable, bonus, profit);
    }

    /**
      @dev Function to subtract forw interest value, calculated from APHPool
            Called by APHPool (proxy)
     */
    function withdrawForwInterest(uint256 claimAmount) external onlyOwner {
        _withdrawForwInterest(claimAmount);
    }

    /**
      @dev Function to withdraw token actual profit. Called by owner account
     */
    function withdrawActualProfit()
        external
        onlyNoTimelockManager
        returns (uint256)
    {
        return _withdrawActualProfit();
    }

    function getTotalTokenInterest() external view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getTotalForwInterest() external view returns (uint256) {
        return IERC20(forwAddress).balanceOf(address(this));
    }

    // Internal
    // `receiver` is for later use (event)
    function _ownerApprove(
        address _pool,
        uint256 _tokenApproveAmount,
        uint256 _forwApproveAmount
    ) internal {
        IERC20(tokenAddress).safeIncreaseAllowance(_pool, _tokenApproveAmount);
        IERC20(forwAddress).safeIncreaseAllowance(_pool, _forwApproveAmount);

        emit OwnerApprove(
            msg.sender,
            tokenAddress,
            forwAddress,
            _tokenApproveAmount,
            _forwApproveAmount,
            _pool
        );
    }

    function _settleInterest(
        uint256 _claimableTokenInterest,
        uint256 _heldTokenInterest,
        uint256 _claimableForwInterest
    ) internal {
        claimableTokenInterest += _claimableTokenInterest;
        heldTokenInterest += _heldTokenInterest;
        claimableForwInterest += _claimableForwInterest;

        emit SettleInterest(
            msg.sender,
            claimableTokenInterest,
            heldTokenInterest,
            claimableForwInterest
        );
    }

    function _withdrawTokenInterest(
        uint256 claimable,
        uint256 bonus,
        uint256 profit
    ) internal {
        claimableTokenInterest -= claimable;
        heldTokenInterest -= bonus + profit;
        actualTokenInterestProfit += profit;
        cumulativeTokenInterestProfit += profit;

        emit WithdrawTokenInterest(msg.sender, claimable, bonus, profit);
    }

    function _withdrawForwInterest(uint256 claimable) internal {
        claimableForwInterest -= claimable;

        emit WithdrawForwInterest(msg.sender, claimable);
    }

    function _withdrawActualProfit() internal returns (uint256) {
        uint256 tempInterestProfit = actualTokenInterestProfit;
        actualTokenInterestProfit = 0;

        IERC20(tokenAddress).safeTransfer(
            noTimelockManager,
            tempInterestProfit
        );

        emit WithdrawActualProfit(msg.sender, tempInterestProfit);
        return tempInterestProfit;
    }
}
