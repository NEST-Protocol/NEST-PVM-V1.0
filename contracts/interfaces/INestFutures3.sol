// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Nest futures without merger
interface INestFutures3 {

    /// @dev Order for view methods
    struct OrderView {
        // Index of this order
        uint32 index;
        // Owner of this order
        address owner;
        // Balance of this order, 4 decimals
        uint48 balance;
        // Index of target channel, support eth, btc and bnb
        uint16 channelIndex;
        // Open block of this order
        uint32 baseBlock;
        // Leverage of this order
        uint8 lever;
        // Orientation of this order, long or short
        bool orientation;
        // Base price of this order
        uint basePrice;
        // Pt, use this to calculate miuT
        int Pt;
    }

    // Global parameter for trade channel
    struct TradeChannel {
        uint56 Lp;
        uint56 Sp;
        uint32 ts;
        int56 Pt;
    }

    /// @dev Buy order event
    /// @param index Index of order
    /// @param nestAmount Amount of paid NEST, 4 decimals
    /// @param owner The owner of order
    event Buy(
        uint index,
        uint nestAmount,
        address owner
    );

    /// @dev Add order event
    /// @param index Index of order
    /// @param amount Amount to sell, 4 decimals
    /// @param owner The owner of order
    event Add(
        uint index,
        uint amount,
        address owner
    );

    /// @dev Sell order event
    /// @param index Index of order
    /// @param amount Amount to sell, 4 decimals
    /// @param owner The owner of order
    /// @param value Amount of NEST obtained
    event Sell(
        uint index,
        uint amount,
        address owner,
        uint value
    );

    /// @dev Liquidate order event
    /// @param index Index of order
    /// @param sender Address of sender
    /// @param reward Liquidation reward
    event Liquidate(
        uint index,
        address sender,
        uint reward
    );

    function getChannel(uint channelIndex) external view returns (TradeChannel memory channel);

    /// @dev Buy futures
    /// @param channelIndex Index of target channel
    /// @param lever Lever of order
    /// @param orientation true: long, false: short
    /// @param amount Amount of paid NEST, 4 decimals
    function buy(
        uint16 channelIndex, 
        uint8 lever, 
        bool orientation, 
        uint amount
    ) external payable;

    /// @dev Append buy
    /// @param orderIndex Index of target order
    /// @param amount Amount of paid NEST
    function add(uint orderIndex, uint amount) external payable;

    /// @dev Sell order
    /// @param orderIndex Index of order
    function sell(uint orderIndex) external payable;

    /// @dev Liquidate order
    /// @param indices Target order indices
    function liquidate(uint[] calldata indices) external payable;

    /// @dev Find the orders of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given owner address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return orderArray Matched orders
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (OrderView[] memory orderArray);

    /// @dev List orders
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function list(uint offset, uint count, uint order) external view returns (OrderView[] memory orderArray);

    /// @dev List prices
    /// @param channelIndex index of target channel
    function lastPrice(uint channelIndex) external view returns (uint period, uint height, uint price);
}
