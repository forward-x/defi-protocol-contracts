// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../interfaces/IMembership.sol";
import "../../externalContract/openzeppelin/non-upgradeable/Math.sol";
import "../../externalContract/openzeppelin/non-upgradeable/SafeERC20.sol";

import "./StakePoolBase.sol";

contract StakePool is StakePoolBase {
    using SafeERC20 for IERC20;

    /**
      @dev Modifier for check sender is new migration stakepool
     */
    modifier onlyNextPool() {
        require(
            msg.sender == nextPoolAddress,
            "StakePool/caller-is-not-nextStakePool"
        );
        _;
    }

    constructor(
        address _membershipAddress,
        address _stakeVaultAddress,
        address _forwAddress
    ) {
        membershipAddress = _membershipAddress;
        stakeVaultAddress = _stakeVaultAddress;
        forwAddress = _forwAddress;
        noTimelockManager = msg.sender;
        configTimelockManager = msg.sender;
        addressTimelockManager = msg.sender;
        emit TransferNoTimelockManager(address(0), noTimelockManager);
        emit TransferConfigTimelockManager(address(0), configTimelockManager);
        emit TransferAddressTimelockManager(address(0), addressTimelockManager);
    }

    event Stake(address indexed sender, uint256 indexed nftId, uint256 amount);
    event Unstake(
        address indexed sender,
        uint256 indexed nftId,
        uint256 amount
    );
    event DeprecateStakeInfo(address indexed sender, uint256 indexed nftId);
    event SetPoolStartTimestamp(
        address indexed sender,
        uint64 indexed timestamp
    );
    event SetNextPool(address indexed sender, address newPool);
    event SetSettleInterval(address indexed sender, uint256 interval);
    event SetRankInfo(
        address indexed sender,
        uint256[] interestBonusLending,
        uint256[] forwardBonusLending,
        uint256[] minimumStakeAmount,
        uint256[] maxLTVBonus,
        uint256[] tradingFee
    );

    // external function onlyOwner
    /**
      @dev Setter function for set new migration stakepool
     */
    function setNextPool(address _address) external onlyAddressTimelockManager {
        nextPoolAddress = _address;
        emit SetNextPool(msg.sender, _address);
    }

    /**
      @dev Setter function for set settleInterval
     */
    function setSettleInterval(
        uint256 interval
    ) external onlyConfigTimelockManager {
        settleInterval = interval;
        emit SetSettleInterval(msg.sender, interval);
    }

    /**
      @dev Setter function for set poolStartTimestamp
     */
    function setPoolStartTimestamp(
        uint64 timestamp
    ) external onlyConfigTimelockManager {
        require(poolStartTimestamp == 0, "StakePool/already-setted");
        if (timestamp == 0) {
            poolStartTimestamp = uint64(block.timestamp);
        } else {
            require(
                timestamp >= uint64(block.timestamp),
                "StakePool/timestamp-less-than-now"
            );
            poolStartTimestamp = timestamp;
        }
        emit SetPoolStartTimestamp(msg.sender, timestamp);
    }

    /**
      @dev Setter function for set rankInfos
     */
    function setRankInfo(
        uint256[] memory _interestBonusLending,
        uint256[] memory _forwardBonusLending,
        uint256[] memory _minimumStakeAmount,
        uint256[] memory _maxLTVBonus,
        uint256[] memory _tradingFee
    ) external onlyConfigTimelockManager {
        require(
            _interestBonusLending.length == _forwardBonusLending.length &&
                _forwardBonusLending.length == _minimumStakeAmount.length &&
                _forwardBonusLending.length == _maxLTVBonus.length &&
                _forwardBonusLending.length == _tradingFee.length,
            "input-does-not-have-same-length"
        );

        for (uint8 i = 0; i < _interestBonusLending.length; i++) {
            RankInfo memory rankInfo = RankInfo(
                _interestBonusLending[i],
                _forwardBonusLending[i],
                _minimumStakeAmount[i],
                _maxLTVBonus[i],
                _tradingFee[i]
            );
            rankInfos[i] = rankInfo;
        }
        rankLen = uint8(_interestBonusLending.length);

        emit SetRankInfo(
            msg.sender,
            _interestBonusLending,
            _forwardBonusLending,
            _minimumStakeAmount,
            _maxLTVBonus,
            _tradingFee
        );
    }

    /**
      @dev Deprecate stakeInfos of user
     */
    function deprecateStakeInfo(uint256 nftId) external onlyNextPool {
        totalStakeAmount -= stakeInfos[nftId].stakeBalance;
        stakeInfos[nftId] = stakeInfos[0];
        emit DeprecateStakeInfo(msg.sender, nftId);
    }

    /**
      @dev Use for pause some function
     */
    function pause(bytes4 _func) external onlyNoTimelockManager {
        require(_func != bytes4(0), "StakePool/msg.sig-func-is-zero");
        _pause(_func);
    }

    /**
      @dev Use for unpause some function
     */
    function unPause(bytes4 _func) external onlyNoTimelockManager {
        require(_func != bytes4(0), "StakePool/msg.sig-func-is-zero");
        _unpause(_func);
    }

    // external function
    /**
      @dev This function use for stake and stake more for get tier of membership in NFT
     */
    function stake(
        uint256 nftId,
        uint256 amount
    )
        external
        nonReentrant
        whenFuncNotPaused(msg.sig)
        returns (StakeInfo memory)
    {
        nftId = IMembership(membershipAddress).usableTokenId(msg.sender, nftId);
        return _stake(nftId, amount);
    }

    /**
      @dev This function use for unstake and update membership tier in NFT

      NOTE: Before withdraw this function is check claimAmount must be less than stake balance and less than or equal claimableAmount
     */
    function unstake(
        uint256 nftId,
        uint256 amount
    )
        external
        nonReentrant
        whenFuncNotPaused(msg.sig)
        returns (StakeInfo memory)
    {
        nftId = IMembership(membershipAddress).usableTokenId(msg.sender, nftId);
        return _unstake(nftId, amount);
    }

    /**
      @dev This function is use for get extra MaxLTV for user who is membership in the borrow function

      NOTE: User who is membership have maximum borrowable more than normal user
     */
    function getMaxLTVBonus(uint256 nftId) external view returns (uint256) {
        return
            rankInfos[
                IMembership(membershipAddress).getRank(address(this), nftId)
            ].maxLTVBonus;
    }

    /**
      @dev getter function that use for get status of staking of each user

      NOTE: stakeInfos is object that represent a status of staking of user
     */
    function getStakeInfo(
        uint256 nftId
    ) external view returns (StakeInfo memory) {
        return stakeInfos[nftId];
    }

    // internal function
    function _stake(
        uint256 nftId,
        uint256 amount
    ) internal returns (StakeInfo memory) {
        StakeInfo storage nftStakeInfo = stakeInfos[nftId];
        if (nftStakeInfo.startTimestamp == 0) {
            nftStakeInfo.startTimestamp = uint64(block.timestamp);
            nftStakeInfo.payPattern = new uint256[](4);
        }
        _settle(nftStakeInfo);

        nftStakeInfo.stakeBalance += amount;

        nftStakeInfo.endTimestamp =
            uint64(block.timestamp) -
            poolStartTimestamp +
            uint64(settleInterval * settlePeriod);
        nftStakeInfo.endTimestamp =
            nftStakeInfo.endTimestamp -
            (nftStakeInfo.endTimestamp % uint64(settleInterval)) +
            poolStartTimestamp;

        uint256 periodAmount = amount / settlePeriod;

        nftStakeInfo.payPattern[0] += periodAmount;
        nftStakeInfo.payPattern[1] += periodAmount;
        nftStakeInfo.payPattern[2] += periodAmount;
        nftStakeInfo.payPattern[3] += amount - (periodAmount * 3);

        _updateNFTRank(nftId);
        totalStakeAmount = totalStakeAmount + amount;
        IERC20(forwAddress).safeTransferFrom(
            IMembership(membershipAddress).ownerOf(nftId),
            stakeVaultAddress,
            amount
        );
        emit Stake(msg.sender, nftId, amount);
        return nftStakeInfo;
    }

    function _unstake(
        uint256 nftId,
        uint256 amount
    ) internal returns (StakeInfo memory) {
        StakeInfo storage nftStakeInfo = stakeInfos[nftId];
        _settle(nftStakeInfo);

        require(
            nftStakeInfo.stakeBalance >= amount,
            "StakePool/unstake-balance-is-insufficient"
        );
        if (nftStakeInfo.claimableAmount < amount) {
            amount = nftStakeInfo.claimableAmount;
        }
        nftStakeInfo.stakeBalance -= amount;
        nftStakeInfo.claimableAmount -= amount;

        _updateNFTRank(nftId);
        totalStakeAmount = totalStakeAmount - amount;
        IERC20(forwAddress).safeTransferFrom(
            stakeVaultAddress,
            msg.sender,
            amount
        );

        emit Unstake(msg.sender, nftId, amount);
        return nftStakeInfo;
    }

    /**
      @dev This function is internal function use for update claimable balance of user by payPattern
     */
    function _settle(StakeInfo storage stakeInfo) internal {
        require(
            uint64(block.timestamp) > poolStartTimestamp,
            "StakePool/this-is-pool-start-ts"
        );
        uint64 poolLastSettleTimestamp = _getPoolSettleTimestamp();

        if (stakeInfo.stakeBalance != 0) {
            uint256 I = Math.min(
                uint256(
                    (poolLastSettleTimestamp - stakeInfo.lastSettleTimestamp) /
                        uint256(settleInterval)
                ),
                settlePeriod
            );
            if (I != 0) {
                for (uint256 index = 0; index < I; index++) {
                    stakeInfo.claimableAmount += stakeInfo.payPattern[index];
                    stakeInfo.payPattern[index] = 0;
                }
            }

            for (uint256 i = 0; i < I; i++) {
                for (uint256 x = 0; x < stakeInfo.payPattern.length - 1; x++) {
                    stakeInfo.payPattern[x] = stakeInfo.payPattern[x + 1];
                }
                delete stakeInfo.payPattern[stakeInfo.payPattern.length - 1];
            }
        }
        stakeInfo.lastSettleTimestamp = poolLastSettleTimestamp;
    }

    /**
      @dev This function is internal function use for update rank of user NFT
     */
    function _updateNFTRank(
        uint256 nftId
    ) internal returns (uint8 currentRank) {
        uint256 stakeBalance = stakeInfos[nftId].stakeBalance;
        currentRank = IMembership(membershipAddress).getRank(
            address(this),
            nftId
        );

        for (uint8 i = rankLen - 1; i >= 0; i--) {
            if (stakeBalance >= rankInfos[i].minimumStakeAmount) {
                if (currentRank != i) {
                    currentRank = i;
                    IMembership(membershipAddress).updateRank(
                        nftId,
                        currentRank
                    );
                }
                return currentRank;
            }
        }
    }

    /**
      @dev This function is use for calculate lasttest update time of claimable
     */
    function _getPoolSettleTimestamp() internal view returns (uint64) {
        return
            uint64(
                block.timestamp -
                    ((block.timestamp - uint256(poolStartTimestamp)) %
                        settleInterval)
            );
    }
}
