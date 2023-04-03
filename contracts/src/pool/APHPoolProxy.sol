// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./PoolBaseFunc.sol";

/**
 @dev Contract to delegate call to PoolBorrowing.sol and PoolLending.sol(Implementation contract).
 */
contract APHPoolProxy is PoolBaseFunc {
    function activateRank(uint256 nftId) external returns (uint8 newRank) {
        bytes memory data = abi.encodeWithSignature(
            "activateRank(uint256)",
            nftId
        );

        data = _delegateCall(poolLendingAddress, data);
        newRank = abi.decode(data, (uint8));
    }

    function deposit(
        uint256 nftId,
        uint256 depositAmount
    )
        external
        payable
        returns (uint256 mintedP, uint256 mintedItp, uint256 mintedIfp)
    {
        bytes memory data = abi.encodeWithSignature(
            "deposit(uint256,uint256)",
            nftId,
            depositAmount
        );

        data = _delegateCall(poolLendingAddress, data);
        (mintedP, mintedItp, mintedIfp) = abi.decode(
            data,
            (uint256, uint256, uint256)
        );
    }

    function withdraw(
        uint256 nftId,
        uint256 withdrawAmount
    ) external returns (WithdrawResult memory result) {
        bytes memory data = abi.encodeWithSignature(
            "withdraw(uint256,uint256)",
            nftId,
            withdrawAmount
        );

        data = _delegateCall(poolLendingAddress, data);
        result = abi.decode(data, (WithdrawResult));
    }

    function claimAllInterest(
        uint256 nftId
    ) external returns (WithdrawResult memory result) {
        bytes memory data = abi.encodeWithSignature(
            "claimAllInterest(uint256)",
            nftId
        );

        data = _delegateCall(poolLendingAddress, data);
        result = abi.decode(data, (WithdrawResult));
    }

    function claimTokenInterest(
        uint256 nftId,
        uint256 claimAmount
    ) external returns (WithdrawResult memory result) {
        bytes memory data = abi.encodeWithSignature(
            "claimTokenInterest(uint256,uint256)",
            nftId,
            claimAmount
        );

        data = _delegateCall(poolLendingAddress, data);
        result = abi.decode(data, (WithdrawResult));
    }

    function claimForwInterest(
        uint256 nftId,
        uint256 claimAmount
    ) external returns (WithdrawResult memory result) {
        bytes memory data = abi.encodeWithSignature(
            "claimForwInterest(uint256,uint256)",
            nftId,
            claimAmount
        );

        data = _delegateCall(poolLendingAddress, data);
        result = abi.decode(data, (WithdrawResult));
    }

    function borrow(
        uint256 loanId,
        uint256 nftId,
        uint256 borrowAmount,
        uint256 collateralSentAmount,
        address collateralTokenAddress
    ) external payable returns (CoreBase.Loan memory loan) {
        bytes memory data = abi.encodeWithSignature(
            "borrow(uint256,uint256,uint256,uint256,address)",
            loanId,
            nftId,
            borrowAmount,
            collateralSentAmount,
            collateralTokenAddress
        );

        data = _delegateCall(poolBorrowingAddress, data);
        loan = abi.decode(data, (CoreBase.Loan));
    }

    function addLoss(uint256 lossAmount) external {
        bytes memory data = abi.encodeWithSignature(
            "addLoss(uint256)",
            lossAmount
        );

        _delegateCall(poolBorrowingAddress, data);
    }

    function _delegateCall(
        address targetAddress,
        bytes memory input
    ) internal returns (bytes memory) {
        require(targetAddress != address(0), "Zero_Address targetAddress");

        (bool success, bytes memory data) = targetAddress.delegatecall(input);
        if (!success) {
            if (data.length == 0) revert();
            assembly {
                revert(add(32, data), mload(data))
            }
        }
        return data;
    }
}
