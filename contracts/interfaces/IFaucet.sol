// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

interface IFaucet {
    function setTokenRequestPerRound(address _tokenAddress, uint256 _amount) external;

    function setCooldown(uint256 _cooldown) external;

    function requestToken(address _tokenAddress) external;

    function getTokenBalance(address _tokenAddress) external view returns (uint256);

    function getAllBalance() external view returns (address[] memory, uint256[] memory);
}
