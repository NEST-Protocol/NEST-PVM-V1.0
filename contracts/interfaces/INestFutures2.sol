// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for Futures
interface INestFutures2 {

    /// @dev Future2 structure
    struct Future2 {
        uint32 owner;
        uint64 basePrice;
        uint64 balance;
        uint32 baseBlock;
        uint16 tokenIndex;
        uint8 lever;
        bool orientation;
    }
    
    /// @dev Returns the current value of target address in the specified future
    /// @param index Index of future
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    function balanceOf2(uint index, uint oraclePrice) external view returns (uint);

    /// @dev Find the futures of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given owner address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return futureArray Matched futures
    function find2(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (Future2[] memory futureArray);

    /// @dev List futures
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of futures
    function list2(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (Future2[] memory futureArray);

    /// @dev Buy future direct
    /// @param tokenIndex Index of token
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @param nestAmount Amount of paid NEST
    function buy2(uint16 tokenIndex, uint8 lever, bool orientation, uint nestAmount) external payable;

    /// @dev Sell future
    /// @param index Index of future
    /// @param amount Amount to sell
    function sell2(uint index, uint amount) external payable;

    /// @dev Settle future
    /// @param indices Target future indices
    function liquidate2(uint[] calldata indices) external payable;
}
