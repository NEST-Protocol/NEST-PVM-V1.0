// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for NestProbability
interface INestProbability {

    // Roll dice44 information view
    struct DiceView44 {
        uint index;
        address owner;
        uint32 n;
        uint32 m;
        uint32 openBlock;
        uint gained;
    }

    /// @dev Find the dices44 of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return diceArray44 Matched dice44 array
    function find44(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (DiceView44[] memory diceArray44);

    /// @dev List dice44
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return diceArray44 Matched dice44 array
    function list44(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (DiceView44[] memory diceArray44);

    /// @dev Obtain the number of dices44 that have been opened
    /// @return Number of dices44 opened
    function getDiceCount44() external view returns (uint);

    /// @dev start a roll dice44
    /// @param n count of PRC
    /// @param m times, 4 decimals
    function roll44(uint n, uint m) external;

    /// @dev Claim gained DCU
    /// @param index index of bet
    function claim44(uint index) external;

    /// @dev Batch claim gained DCU
    /// @param indices Indices of bets
    function batchClaim44(uint[] calldata indices) external;
}
