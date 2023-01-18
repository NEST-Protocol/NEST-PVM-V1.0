// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

/// @dev NestMultiSign implementation
contract NestMultiSign {

    // Passed Thresholds, max M
    uint constant P = 3;
    // Number of members, max 8
    uint constant M = 3;
    // Number of addresses per each account, max 3
    uint constant N = 3;

    // Transaction data structure
    struct Transaction {
        // Address of token to transfer
        address tokenAddress;
        // Transaction start block
        uint32 startBlock;
        // Transaction execute block
        uint32 executeBlock;
        // sign7(1+3)|sign6(1+3)|sign5(1+3)|sign4(1+3)|sign3(1+3)|sign2(1+3)|sign1(1+3)|sign0(1+3)
        uint32 signs;
        // Token receive address
        address to;
        // Transfer value
        uint96 value;
    }

    // Transaction information for view method
    struct TransactionView {
        // Index of transaction in _transactions
        uint32 index;
        // Address of token to transfer
        address tokenAddress;
        // Transaction start block
        uint32 startBlock;
        // Transaction execute block
        uint32 executeBlock;
        // Token receive address
        address to;
        // Transfer value
        uint96 value;
        // signs: 0 address means not signed
        address[M] signs;
    }

    // Members of this multi sign account
    address[N][M] _members;

    // Transaction array
    Transaction[] _transactions;

    // Only member is allowed
    modifier onlyMember(uint i, uint j) {
        require(_members[i][j] == msg.sender, "NMS:member not found");
        _;
    }

    /// @dev Ctor
    /// @param members Member array, stored by group, don't repeat
    constructor(address[N][M] memory members) {
        // TODO: check repeat
        _members = members;
    }

    /// @dev Get member at given position
    /// @param i Index of member
    /// @param j Index of address
    /// @return member Member at (i, j)
    /// @return m Number of members
    /// @return n Number of addresses per each account
    function getMember(uint i, uint j) external view returns (address member, uint m, uint n) {
        return (_members[i][j], M, N);
    }

    /// @dev Find member by target address
    /// @param target Target address
    /// @return Index of member
    /// @return Index of address
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
                --index;
                (transactionArray[i++] = _toTransactionView(transactions[index])).index = uint32(index);
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
                (transactionArray[i++] = _toTransactionView(transactions[index])).index = uint32(index);
                ++index;
            }
        }
    }

    /// @dev Start a new transaction
    /// @param i Index of member
    /// @param j Index of address
    /// @param tokenAddress Address of target token
    /// @param to Target address
    /// @param value Transaction amount
    function newTransaction(uint i, uint j, address tokenAddress, address to, uint96 value) external onlyMember(i, j) {
        _transactions.push(Transaction(
            tokenAddress,
            uint32(block.number),
            uint32(0),
            uint32((1 << j) << (i << 2)),
            to,
            value
        ));
    }

    /// @dev Sign transaction
    /// @param i Index of member
    /// @param j Index of address
    /// @param index Index of transaction
    function signTransaction(uint i, uint j, uint index) external onlyMember(i, j) {
        _transactions[index].signs |= uint32((1 << j) << (i << 2));
    }

    /// @dev Reject transaction
    /// @param i Index of member
    /// @param j Index of address
    /// @param index Index of transaction
    function rejectTransaction(uint i, uint j, uint index) external onlyMember(i, j) {
        _transactions[index].signs |= uint32((1 << 3) << (i << 2));
    }

    /// @dev Execute transaction
    /// @param i Index of member
    /// @param j Index of address
    /// @param index Index of transaction
    function executeTransaction(uint i, uint j, uint index) external onlyMember(i, j) {
        // Load transaction
        Transaction memory transaction = _transactions[index];
        // executeBlock == 0 means executed
        require(transaction.executeBlock == 0, "NMS:executed");
        // Load sign, and sign with current member
        uint signs = uint(transaction.signs) | ((1 << j) << (i << 2));
        
        // Count of signs
        uint p = 0;
        for (uint k = 0; k < M; ++k) {
            uint sign = (signs >> (k << 2)) & 0xF;
            if (sign > 0 && sign < 8) {
                ++p;
            }
        }
        require(p >= P, "NMS:not passed");

        // Update transaction
        transaction.signs = uint32(signs);
        transaction.executeBlock = uint32(block.number);
        _transactions[index] = transaction;

        uint value = uint(transaction.value);
        // Transfer eth
        if (transaction.tokenAddress == address(0)) {
            payable(transaction.to).transfer(value);
        } 
        // Modify member
        else if (transaction.tokenAddress == 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF) {
            _members[value >> 32][value & 0xFFFFFFFF] = transaction.to;
        }
        // Transfer token
        else {
            TransferHelper.safeTransfer(transaction.tokenAddress, transaction.to, value);
        }
    }

    // Convert to TransactionView
    function _toTransactionView(Transaction memory transaction) internal view returns (TransactionView memory tv) {
        // Resolve signs
        uint signs = uint(transaction.signs);
        address[M] memory signArray;
        for (uint k = 0; k < M; ++k) {
            uint sign = (signs >> (k << 2)) & 0xF;
            if (sign > 0 && sign < 8) {
                for (uint j = 0; j < N; ++j) {
                    if ((sign >> j) & 0x01 == 0x01) {
                        signArray[k] = _members[k][j];
                        break;
                    }
                }
            } else {
                signArray[k] = address(0); 
            }
        }

        tv = TransactionView(
            uint32(0),
            transaction.tokenAddress,
            transaction.startBlock,
            transaction.executeBlock,
            transaction.to,
            transaction.value,
            signArray
        );
    }

    // Support eth
    receive() external payable { }
}
