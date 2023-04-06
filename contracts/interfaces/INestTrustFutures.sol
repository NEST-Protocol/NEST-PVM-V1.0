// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Futures proxy
interface INestTrustFutures {

    /// @dev TrustOrder information for view methods
    struct TrustOrderView {
        // Index of this TrustOrder
        uint32 index;
        // Owner of this order
        address owner;
        // Index of target Order
        uint32 orderIndex;
        // Index of target channel, support eth(0), btc(1) and bnb(2)
        uint16 channelIndex;
        // Leverage of this order
        uint8 lever;
        // Orientation of this order, long or short
        bool orientation;

        // Limit price for trigger buy
        uint limitPrice;
        // Stop price for trigger sell
        uint stopProfitPrice;
        uint stopLossPrice;

        // Balance of nest, 4 decimals
        uint40 balance;
        // Service fee, 4 decimals
        uint40 fee;
        // Status of order, 0: executed, 1: normal, 2: canceled
        uint8 status;
    }
    
    /// @dev Find the orders of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given owner address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return orderArray Matched orders
    function findTrustOrder(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (TrustOrderView[] memory orderArray);

    /// @dev List TrustOrder
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function listTrustOrder(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (TrustOrderView[] memory orderArray);

    // /// @dev Create TrustOrder, for everyone
    // /// @param channelIndex Index of target trade channel, support eth, btc and bnb
    // /// @param lever Leverage of this order
    // /// @param orientation Orientation of this order, long or short
    // /// @param amount Amount of buy order
    // /// @param limitPrice Limit price for trigger buy
    // /// @param stopProfitPrice If not 0, will open a stop order
    // /// @param stopLossPrice If not 0, will open a stop order
    // function newTrustOrder(
    //     uint16 channelIndex, 
    //     uint8 lever, 
    //     bool orientation, 
    //     uint amount, 
    //     uint limitPrice,
    //     uint stopProfitPrice,
    //     uint stopLossPrice
    // ) external;

    /// @dev Update limitPrice for TrustOrder
    /// @param trustOrderIndex Index of TrustOrder
    /// @param limitPrice Limit price for trigger buy
    function updateLimitPrice(uint trustOrderIndex, uint limitPrice) external;

    /// @dev Update stopPrice for TrustOrder
    /// @param trustOrderIndex Index of target TrustOrder
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function updateStopPrice(uint trustOrderIndex, uint stopProfitPrice, uint stopLossPrice) external;

    /// @dev Create a new stop order for Order
    /// @param orderIndex Index of target Order
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function newStopOrder(uint orderIndex, uint stopProfitPrice, uint stopLossPrice) external;

    // /// @dev Buy futures with StopOrder
    // /// @param channelIndex Index of target channel
    // /// @param lever Lever of order
    // /// @param orientation true: long, false: short
    // /// @param amount Amount of paid NEST, 4 decimals
    // /// @param stopProfitPrice If not 0, will open a stop order
    // /// @param stopLossPrice If not 0, will open a stop order
    // function buyWithStopOrder(
    //     uint channelIndex, 
    //     uint lever, 
    //     bool orientation, 
    //     uint amount,
    //     uint stopProfitPrice, 
    //     uint stopLossPrice
    // ) external payable;
    
    /// @dev Cancel TrustOrder, for everyone
    /// @param trustOrderIndex Index of TrustOrder
    function cancelLimitOrder(uint trustOrderIndex) external;

    /// @dev Execute limit order, only maintains account
    /// @param trustOrderIndices Array of TrustOrder index
    function executeLimitOrder(uint[] calldata trustOrderIndices) external;

    /// @dev Execute stop order, only maintains account
    /// @param trustOrderIndices Array of TrustOrder index
    function executeStopOrder(uint[] calldata trustOrderIndices) external;
}
