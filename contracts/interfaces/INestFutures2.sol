// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for Futures
interface INestFutures2 {

    /// @dev Order structure
    struct Order {
        uint32 owner;
        uint64 basePrice;
        uint64 balance;
        uint32 baseBlock;
        uint16 tokenIndex;
        uint8 lever;
        bool orientation;
    }
    
    /// @dev Buy order event
    /// @param index Index of order
    /// @param nestAmount Amount of paid NEST
    /// @param owner The owner of order
    event Buy2(
        uint index,
        uint nestAmount,
        address owner
    );

    /// @dev Sell order event
    /// @param index Index of order
    /// @param amount Amount to sell
    /// @param owner The owner of order
    /// @param value Amount of NEST obtained
    event Sell2(
        uint index,
        uint amount,
        address owner,
        uint value
    );

    /// @dev Liquidate order event
    /// @param index Index of order
    /// @param sender Address of sender
    /// @param reward Liquidation reward
    event Liquidate2(
        uint index,
        address sender,
        uint reward
    );

    /// @dev Returns the current value of target address in the specified order
    /// @param index Index of order
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    function balanceOf2(uint index, uint oraclePrice) external view returns (uint);

    /// @dev Find the orders of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given owner address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return orderArray Matched orders
    function find2(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (Order[] memory orderArray);

    /// @dev List orders
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function list2(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (Order[] memory orderArray);

    /// @dev Buy order direct
    /// @param tokenIndex Index of token
    /// @param lever Lever of order
    /// @param orientation true: call, false: put
    /// @param nestAmount Amount of paid NEST
    function buy2(uint16 tokenIndex, uint8 lever, bool orientation, uint nestAmount) external payable;

    /// @dev Sell order
    /// @param index Index of order
    /// @param amount Amount to sell
    function sell2(uint index, uint amount) external payable;

    /// @dev Liquidate order
    /// @param indices Target order indices
    function liquidate2(uint[] calldata indices) external payable;
}
