// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../externalContract/openzeppelin/non-upgradeable/ERC721Enumerable.sol";
import "../../externalContract/openzeppelin/non-upgradeable/ERC721Pausable.sol";
import "../../externalContract/openzeppelin/non-upgradeable/Counters.sol";
import "../../externalContract/modify/non-upgradeable/ManagerTimelock.sol";

contract Membership is ERC721Enumerable, ERC721Pausable, ManagerTimelock {
    using Counters for Counters.Counter; //                                             // Using library Couter

    Counters.Counter private _tokenIdTracker; //                                        // _tokenIdTracker is represent current nftId that not equal zero
    string private _baseTokenURI; //                                                    // BaseURL of Membership contract
    mapping(address => uint256) private _defaultMembership; //                          // Mapping user address with default NFTId

    address public currentPool; //                                                       // Address of staking pool that use for staking now
    address[] private _poolList = [address(0)]; //                                       // Array collect all address of staking pool
    mapping(address => uint256) private _poolIndex; //                                   // mapping pool address with pool index
    mapping(address => mapping(uint256 => uint8)) private _poolMembershipRanks; //       // mapping staking pool address and NFTId to get user rank

    event SetNewPool(address indexed sender, address newPool);
    event SetBaseURI(address indexed sender, string baseTokenURI);
    event SetDefaultMembership(address indexed sender, uint256 tokenId);
    event UpdateRank(address indexed sender, uint256 tokenId, uint8 newRank);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _tokenIdTracker.increment();
        noTimelockManager = msg.sender;
        configTimelockManager = msg.sender;
        addressTimelockManager = msg.sender;

        emit TransferNoTimelockManager(address(0), noTimelockManager);
        emit TransferConfigTimelockManager(address(0), configTimelockManager);
        emit TransferAddressTimelockManager(address(0), addressTimelockManager);
    }

    /**
      @dev Function for set new staking pool
     */
    function setNewPool(
        address newPool
    ) external onlyAddressTimelockManager whenNotPaused {
        currentPool = newPool;
        _poolIndex[newPool] = _poolList.length;
        _poolList.push(newPool);

        emit SetNewPool(msg.sender, newPool);
    }

    /**
      @dev Function for set new BaseURL
     */
    function setBaseURI(
        string memory baseTokenURI
    ) external onlyConfigTimelockManager whenNotPaused {
        _baseTokenURI = baseTokenURI;

        emit SetBaseURI(msg.sender, baseTokenURI);
    }

    /**
      @dev Function for set default membership nft for each user
     */
    function setDefaultMembership(uint256 tokenId) external whenNotPaused {
        require(
            msg.sender == ownerOf(tokenId),
            "Membership/permission-denied-for-set-default-membership"
        );
        _defaultMembership[msg.sender] = tokenId;

        emit SetDefaultMembership(msg.sender, tokenId);
    }

    /**
      @dev Function to get previus staking pool

      NOTE: poolList Array start at index 1
     */
    function getPreviousPool() external view returns (address) {
        require(_poolList.length > 1, "pool list length = 0");
        if (_poolList.length > 1) {
            return _poolList[_poolList.length - 2];
        } else {
            return address(0);
        }
    }

    /**
      @dev Function for get default membership nft of user
     */
    function getDefaultMembership(
        address account
    ) external view returns (uint256) {
        return _defaultMembership[account];
    }

    /**
      @dev Function for get poolList array
     */
    function getPoolLists() external view returns (address[] memory) {
        return _poolList;
    }

    /**
      @dev Function for get user rank by nft on current staking pool
     */
    function getRank(uint256 tokenId) external view returns (uint8) {
        return _poolMembershipRanks[currentPool][tokenId];
    }

    /**
      @dev Function for get user rank by nft on each staking pool
     */
    function getRank(
        address pool,
        uint256 tokenId
    ) external view returns (uint8) {
        return _poolMembershipRanks[pool][tokenId];
    }

    /**
      @dev Function for mint NFT of memberhip

      NOTE: This Function auto set default nft if user don't have nft
     */
    function mint() external whenNotPaused returns (uint256) {
        require(
            msg.sender == tx.origin,
            "Membership/do-not-support-smart-contract"
        );

        uint256 tokenId = _tokenIdTracker.current();
        _safeMint(msg.sender, tokenId);
        _setFirstOwnedDefaultMembership(msg.sender, tokenId);
        _tokenIdTracker.increment();
        return tokenId;
    }

    /**
      @dev Function for update user rank

      NOTE: Function allow only staking pool for call
     */
    function updateRank(uint256 tokenId, uint8 newRank) external whenNotPaused {
        require(
            _poolIndex[msg.sender] != 0,
            "Membership/sender-is-not-stake-pool-contract"
        );
        _poolMembershipRanks[msg.sender][tokenId] = newRank;

        emit UpdateRank(msg.sender, tokenId, newRank);
    }

    /**
      @dev Function check user who is origin calling is owner of nft

      NOTE: NFTId is zero it's mean getDefault of user NFTId
     */
    function usableTokenId(
        address owner,
        uint256 tokenId
    ) external view returns (uint256) {
        return _usableTokenId(owner, tokenId);
    }

    /**
      @dev Function this contract is support input interface(Id)
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function pause() external onlyNoTimelockManager {
        _pause();
    }

    function unpause() external onlyNoTimelockManager {
        _unpause();
    }

    // internal function

    function _usableTokenId(
        address owner,
        uint256 tokenId
    ) internal view returns (uint256) {
        require(owner == tx.origin, "Membership/do-not-support-smart-contract");
        if (tokenId == 0) {
            tokenId = _defaultMembership[owner];
            require(
                tokenId != 0,
                "Membership/do-not-owned-any-membership-card"
            );
        } else {
            require(
                ownerOf(tokenId) == owner,
                "Membership/caller-is-not-card-owner"
            );
        }
        return tokenId;
    }

    function _setFirstOwnedDefaultMembership(
        address account,
        uint256 tokenId
    ) internal {
        if (balanceOf(account) == 1) {
            _defaultMembership[account] = tokenId;
        }
    }

    // override functions
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
      @dev Function use for update state after transfer NFT
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._afterTokenTransfer(from, to, tokenId);
        if (from != address(0)) {
            if (balanceOf(from) == 0) {
                _defaultMembership[from] = 0;
            } else if (tokenId == _defaultMembership[from]) {
                _defaultMembership[from] = tokenOfOwnerByIndex(from, 0);
            }
        }
        _setFirstOwnedDefaultMembership(to, tokenId);
    }
}
