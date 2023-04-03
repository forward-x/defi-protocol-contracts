// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../externalContract/openzeppelin/non-upgradeable/IERC721Enumerable.sol";

interface IMembership is IERC721Enumerable {
    // External functions

    function getDefaultMembership(address owner) external view returns (uint256);

    function setDefaultMembership(uint256 tokenId) external;

    // function setNewPool(address newPool) external;

    function getPoolLists() external view returns (address[] memory);

    function mint() external returns (uint256);

    // function setBaseURI(string memory baseTokenURI) external;

    function updateRank(uint256 tokenId, uint8 newRank) external;

    function usableTokenId(address owner, uint256 tokenId) external view returns (uint256);

    function getRank(uint256 tokenId) external view returns (uint8);

    function getRank(address pool, uint256 tokenId) external view returns (uint8);

    function currentPool() external view returns (address);

    function ownerOf(uint256) external view override returns (address);

    function getPreviousPool() external view returns (address);

    function setNewPool(address newPool) external;
}
