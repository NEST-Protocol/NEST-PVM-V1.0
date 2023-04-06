// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Nest futures with responsive
interface INestFutures4 {
    
    /// @dev Order structure
    struct Order {
        // Address of owner
        address owner;
        // Status of order
        uint8 status;
        // Index of target channel, support eth, btc and bnb
        uint8 channelIndex;
        // Leverage of this order
        uint8 lever;
        // Block number of this order opened
        uint32 openBlock;
        // Base price of this order, encoded with encodeFloat40()
        uint40 basePrice;
        
        // Balance of this order, 4 decimals
        uint40 balance;
        // Append amount of this order
        uint40 appends;
        // Service fee, 4 decimals
        uint40 fee;                     // 48
        // Orientation of this order, long or short
        bool orientation;

        // Stop price for trigger sell, encoded by encodeFloat40()
        uint40 stopProfitPrice;         // 56
        // Stop price for trigger sell, encoded by encodeFloat40()
        uint40 stopLossPrice;           // 56
    }

    /// @dev Order for view methods
    struct OrderView {
        // Index of this order
        uint32 index;
        // Owner of this order
        address owner;
        // Balance of this order, 4 decimals
        uint40 balance;
        // Index of target channel, support eth, btc and bnb
        uint8 channelIndex;
        // Leverage of this order
        uint8 lever;
        // Append amount of this order
        uint40 appends;
        // Orientation of this order, long or short
        bool orientation;
        // Base price of this order
        uint basePrice;

        // Block number of this order opened
        uint32 openBlock;
        // Status of order
        uint8 status;
        
        uint40 fee;
        // Stop price for trigger sell
        uint stopProfitPrice;         // 56
        // Stop price for trigger sell
        uint stopLossPrice;           // 56
    }

    /// @dev Buy request event
    /// @param index Index of order
    /// @param amount Amount of paid NEST, 4 decimals
    /// @param owner The owner of order
    event BuyRequest(
        uint index,
        uint amount,
        address owner
    );

    // /// @dev Sell order event
    // /// @param index Index of order
    // /// @param amount Amount to sell, 4 decimals
    // /// @param owner The owner of order
    // event SellRequest(
    //     uint index,
    //     uint amount,
    //     address owner
    // );

    /// @dev Buy order event
    /// @param orderIndex Index of order
    /// @param amount Amount of paid NEST, 4 decimals
    /// @param owner The owner of order
    event Buy(
        uint orderIndex,
        uint amount,
        address owner
    );

    /// @dev Revert order event
    /// @param orderIndex Index of order
    /// @param amount Amount of paid NEST, 4 decimals
    /// @param owner The owner of order
    event Revert(
        uint orderIndex,
        uint amount,
        address owner
    );

    /// @dev Add order event
    /// @param orderIndex Index of order
    /// @param amount Amount to sell, 4 decimals
    /// @param owner The owner of order
    event Add(
        uint orderIndex,
        uint amount,
        address owner
    );

    /// @dev Sell order event
    /// @param orderIndex Index of order
    /// @param amount Amount to sell, 4 decimals
    /// @param owner The owner of order
    /// @param value Amount of NEST obtained
    event Sell(
        uint orderIndex,
        uint amount,
        address owner,
        uint value
    );

    /// @dev Liquidate order event
    /// @param orderIndex Index of order
    /// @param owner Address of owner
    /// @param reward Liquidation reward
    event Liquidate(
        uint orderIndex,
        address owner,
        uint reward
    );

    /// @dev Returns the current value of target order
    /// @param orderIndex Index of order
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    function balanceOf(uint orderIndex, uint oraclePrice) external view returns (uint value);
    
    /// @dev Create buy futures request
    /// @param channelIndex Index of target channel
    /// @param lever Lever of order
    /// @param orientation true: long, false: short
    /// @param amount Amount of paid NEST, 4 decimals
    /// @param basePrice Target price of this order, if limit is true, means limit price, or means open price
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function newBuyRequest(
        uint channelIndex, 
        uint lever, 
        bool orientation, 
        uint amount,
        uint basePrice,
        bool limit,
        uint stopProfitPrice,
        uint stopLossPrice
    ) external payable;

    /// @dev Buy futures use USDT
    /// @param usdtAmount Amount of paid USDT, 18 decimals
    /// @param minNestAmount Minimal amount of  NEST, 18 decimals
    /// @param channelIndex Index of target channel
    /// @param lever Lever of order
    /// @param orientation true: long, false: short
    /// @param basePrice Target price of this order, if limit is true, means limit price, or means open price
    /// @param limit True means this is a limit order
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function newBuyRequestWithUsdt(
        uint usdtAmount,
        uint minNestAmount,
        uint channelIndex,
        uint lever,
        bool orientation,
        uint basePrice,
        bool limit,
        uint stopProfitPrice,
        uint stopLossPrice
    ) external payable;

    /// @dev Cancel buy request
    /// @param orderIndex Index of target order
    function cancelBuyRequest(uint orderIndex) external;

    /// @dev Update limitPrice for Order
    /// @param orderIndex Index of Order
    /// @param limitPrice Limit price for trigger buy
    function updateLimitPrice(uint orderIndex, uint limitPrice) external;

    /// @dev Update stopPrice for Order
    /// @param orderIndex Index of target Order
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function updateStopPrice(uint orderIndex, uint stopProfitPrice, uint stopLossPrice) external;

    /// @dev Append buy
    /// @param orderIndex Index of target order
    /// @param amount Amount of paid NEST
    function add(uint orderIndex, uint amount) external payable;

    /// @dev Create sell futures request
    /// @param orderIndex Index of order
    function newSellRequest(uint orderIndex) external payable;

    // /// @dev Liquidate order
    // /// @param indices Target order indices
    // function liquidate(uint[] calldata indices) external payable;

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

    // /// @dev List prices
    // /// @param channelIndex index of target channel
    // function lastPrice(uint channelIndex) external view returns (uint period, uint height, uint price);
}