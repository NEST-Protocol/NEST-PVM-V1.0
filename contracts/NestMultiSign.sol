// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/ABDKMath64x64.sol";
import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";

import "./custom/ChainParameter.sol";
import "./custom/NestFrequentlyUsed.sol";

import "hardhat/console.sol";

/// @dev NestMultiSign implementation
contract NestMultiSign {

    // Number of members
    uint constant M = 3;
    // Number of addresses per each account
    uint constant N = 3;

    struct Transaction {
        address tokenAddress;
        uint32 startBlock;
        uint32 executeBlock;
        uint32 signs;
        address to;
        uint96 value;
    }

    struct TransactionView {
        address tokenAddress;
        uint32 startBlock;
        uint32 executeBlock;
        // signs: 0 not sign, 1 signed, 2 rejected
        uint8[M] signs;
        address to;
        uint96 value;
    }

    address[M][N] _members;

    Transaction[] _transactions;

    constructor(address[M][N] memory members) {
        // TODO: check repeat
        _members = members;
    }

    // Only for test
    function modifyAddress(uint i, uint j, address newAddress) external /* onlyMember(i, j) */ {
        // TODO: check repeat
        _members[i][j] = newAddress;
    }

    /// @dev List transactions
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return transactionArray List of TransactionView
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (TransactionView[] memory transactionArray) {
        // Load mint requests
        Transaction[] storage transactions = _transactions;
        // Create result array
        transactionArray = new TransactionView[](count);
        uint length = transactions.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                transactionArray[i++] = _toTransactionView(transactions[--index]);
            }
        } 
        // Positive order
        else {
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                transactionArray[i++] = _toTransactionView(transactions[index++]);
            }
        }
    }

    function _toTransactionView(Transaction memory transaction) internal pure returns (TransactionView memory tv) {
        uint signs = uint(transaction.signs);
        uint8[M] memory signArray;
        for (uint i = 0; i < M; ++i) {
            uint sign = (signs >> (i << 3)) & 0xFF;
            if (sign == 0) signArray[i] = uint8(0); 
            else if (sign >= 0x80) signArray[i] = uint8(2); 
            else signArray[i] = uint8(1);
        }

        tv = TransactionView(
            transaction.tokenAddress,
            transaction.startBlock,
            transaction.executeBlock,
            signArray,
            transaction.to,
            transaction.value
        );
    }

    function getMember(uint i, uint j) external view returns (address member) {
        return _members[i][j];
    }

    function findMember(address target) external view returns (uint, uint) {
        for (uint i = 0; i < M; ++i) {
            for (uint j = 0; j < N; ++j) {
                if (_members[i][j] == target) {
                    return (i, j);
                }
            }
        }
        revert("NMS:member not found");
    }

    modifier onlyMember(uint i, uint j) {
        _checkMember(i, j);
        _;
    }

    function _checkMember(uint i, uint j) internal view {
        require(_members[i][j] == msg.sender, "NMS:member not found");
    }

    function newTransaction(uint i, uint j, address tokenAddress, address to, uint96 value) external onlyMember(i, j) {
        //(uint i, uint j) = _memberId(msg.sender);
        _transactions.push(Transaction(
            tokenAddress,
            uint32(block.number),
            uint32(0),
            uint32((1 << j) << (i << 3)),
            to,
            value
        ));
    }

    function signTransaction(uint i, uint j, uint index) external onlyMember(i, j) {
        _transactions[index].signs |= uint32((1 << j) << (i << 3));
    }

    function rejectTransaction(uint i, uint j, uint index) external onlyMember(i, j) {
        _transactions[index].signs |= uint32((1 << 7) << (i << 3));
    }

    function executeTransaction(uint i, uint j, uint index) external onlyMember(i, j) {
        //(uint i, uint j) = _memberId(msg.sender);
        Transaction memory tx = _transactions[index];
        require(tx.executeBlock == 0, "NMS:executed");
        uint signs = uint(tx.signs) | uint32((1 << j) << (i << 3));
        
        //console.log("%d", signs);
        for (uint k = 0; k < M; ++k) {
            uint sign = (signs >> (k << 3)) & 0xFF;
            //console.log("%d", (sign >> 7));
            require(sign > 0 && sign < 0x80, "NMS:not passed");
        }

        tx.signs = uint32(signs);
        tx.executeBlock = uint32(block.number);
        _transactions[index] = tx;

        if (tx.tokenAddress == address(0)) {
            payable(tx.to).transfer(tx.value);
        } else {
            TransferHelper.safeTransfer(tx.tokenAddress, tx.to, tx.value);
        }
    }

    receive() external payable { }
}
