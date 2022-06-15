// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./FortPRCToken.sol";

import "./DCU.sol";

/// @dev Guarantee
contract FortPRC is FortPRCToken {

    // Roll dice structure
    struct Dice {
        address owner;
        uint32 n;
        uint32 m;
        uint32 openBlock;
    }

    // Roll dice information view
    struct DiceView {
        uint index;
        address owner;
        uint32 n;
        uint32 m;
        uint32 openBlock;
        uint gained;
    }

    // The span from current block to hash block
    uint constant OPEN_BLOCK_SPAN = 1;
    // Times base, 4 decimals
    uint constant TIMES_BASE = 10000;
    // Max times, 100000.0000. [1.0000, 100000.0000]
    uint constant MAX_M = 100000 * TIMES_BASE;

    // Roll dice array
    Dice[] _dices;

    /// @dev Find the dices of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return diceArray Matched dice array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (DiceView[] memory diceArray) {
        diceArray = new DiceView[](count);
        // Calculate search region
        Dice[] storage dices = _dices;
        // Loop from start to end
        uint end = 0;
        // start is 0 means Loop from the last item
        if (start == 0) {
            start = dices.length;
        }
        if (start > maxFindCount) {
            end = start - maxFindCount;
        }
        
        // Loop lookup to write qualified records to the buffer
        for (uint index = 0; index < count && start > end;) {
            Dice memory dice = dices[--start];
            if (dice.owner == owner) {
                diceArray[index++] = _toDiceView(dice, start);
            }
        }
    }

    /// @dev List dice
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return diceArray Matched dice array
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (DiceView[] memory diceArray) {

        // Load dices
        Dice[] storage dices = _dices;
        // Create result array
        diceArray = new DiceView[](count);
        uint length = dices.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                Dice memory gi = dices[--index];
                diceArray[i++] = _toDiceView(gi, index);
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
                diceArray[i++] = _toDiceView(dices[index], index);
                ++index;
            }
        }
    }

    /// @dev Obtain the number of dices that have been opened
    /// @return Number of dices opened
    function getDiceCount() external view returns (uint) {
        return _dices.length;
    }

    // Calculate gained number of DCU
    function _gained(Dice memory dice, uint index) private view returns (uint gain) {
        uint hashBlock = uint(dice.openBlock) + OPEN_BLOCK_SPAN;
        require(block.number > hashBlock, "PRC:!hashBlock");
        uint hashValue = uint(blockhash(hashBlock));
        if (hashValue > 0) {
            hashValue = uint(keccak256(abi.encodePacked(hashValue, index)));
            if (hashValue % uint(dice.m) < TIMES_BASE) {
                gain = uint(dice.n) * uint(dice.m) * 1 ether / TIMES_BASE;
            }
        }
    }

    // Convert Dice to DiceView
    function _toDiceView(Dice memory dice, uint index) private view returns (DiceView memory div) {
        div = DiceView(
            index,
            dice.owner,
            dice.n,
            dice.m,
            dice.openBlock,
            block.number > uint(dice.openBlock) + OPEN_BLOCK_SPAN ? _gained(dice, index) : 0
        );
    }
}
