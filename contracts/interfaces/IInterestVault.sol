// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

interface IInterestVault {
    function claimableTokenInterest() external view returns (uint256);

    function heldTokenInterest() external view returns (uint256);

    function actualTokenInterestProfit() external view returns (uint256);

    function claimableForwInterest() external view returns (uint256);

    function cumulativeTokenInterestProfit() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function forwAddress() external view returns (address);

    function protocolAddress() external view returns (address);

    function getTotalTokenInterest() external view returns (uint256);

    function getTotalForwInterest() external view returns (uint256);

    // exclusive functions
    function pause(bytes4 _func) external;

    function unPause(bytes4 _func) external;

    function setForwAddress(address _address) external;

    function setTokenAddress(address _address) external;

    function setProtocolAddress(address _address) external;

    function ownerApprove(address _pool) external;

    function settleInterest(
        uint256 _claimableTokenInterest,
        uint256 _heldTokenInterest,
        uint256 _claimableForwInterest
    ) external;

    function withdrawTokenInterest(
        uint256 claimable,
        uint256 bonus,
        uint256 profit
    ) external;

    function withdrawForwInterest(uint256 claimable) external;

    function withdrawActualProfit(address receiver) external returns (uint256);
}
