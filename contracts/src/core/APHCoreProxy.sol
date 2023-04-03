// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "./CoreBaseFunc.sol";

/**
 @dev Contract to delegate call to CoreBorrowing.sol(Implementation contract).
 */
contract APHCoreProxy is CoreBaseFunc {
    // CoreBorrowing

    function borrow(
        uint256 loanId,
        uint256 nftId,
        uint256 borrowAmount,
        address borrowTokenAddress,
        uint256 collateralSentAmount,
        address collateralTokenAddress,
        uint256 newOwedPerDay,
        uint256 interestRate
    ) external returns (Loan memory loan) {
        bytes memory data = abi.encodeWithSignature(
            "borrow(uint256,uint256,uint256,address,uint256,address,uint256,uint256)",
            loanId,
            nftId,
            borrowAmount,
            borrowTokenAddress,
            collateralSentAmount,
            collateralTokenAddress,
            newOwedPerDay,
            interestRate
        );

        data = _delegateCall(coreBorrowingAddress, data);
        loan = abi.decode(data, (Loan));
    }

    function repay(
        uint256 loanId,
        uint256 nftId,
        uint256 repayAmount,
        bool isOnlyInterest
    ) external payable returns (uint256 borrowPaid, uint256 interestPaid) {
        bytes memory data = abi.encodeWithSignature(
            "repay(uint256,uint256,uint256,bool)",
            loanId,
            nftId,
            repayAmount,
            isOnlyInterest
        );

        data = _delegateCall(coreBorrowingAddress, data);
        (borrowPaid, interestPaid) = abi.decode(data, (uint256, uint256));
    }

    function adjustCollateral(
        uint256 loanId,
        uint256 nftId,
        uint256 collateralAdjustAmount,
        bool isAdd
    ) external payable returns (Loan memory loan) {
        bytes memory data = abi.encodeWithSignature(
            "adjustCollateral(uint256,uint256,uint256,bool)",
            loanId,
            nftId,
            collateralAdjustAmount,
            isAdd
        );

        data = _delegateCall(coreBorrowingAddress, data);
        loan = abi.decode(data, (Loan));
    }

    function rollover(
        uint256 loanId,
        uint256 nftId
    ) external returns (uint256 delayInterest, uint256 bountyReward) {
        bytes memory data = abi.encodeWithSignature(
            "rollover(uint256,uint256)",
            loanId,
            nftId
        );

        data = _delegateCall(coreBorrowingAddress, data);
        (delayInterest, bountyReward) = abi.decode(data, (uint256, uint256));
    }

    function liquidate(
        uint256 loanId,
        uint256 nftId
    )
        external
        returns (
            uint256 repayBorrow,
            uint256 repayInterest,
            uint256 bountyReward,
            uint256 backToUser
        )
    {
        bytes memory data = abi.encodeWithSignature(
            "liquidate(uint256,uint256)",
            loanId,
            nftId
        );

        data = _delegateCall(coreBorrowingAddress, data);
        (repayBorrow, repayInterest, bountyReward, backToUser) = abi.decode(
            data,
            (uint256, uint256, uint256, uint256)
        );
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
