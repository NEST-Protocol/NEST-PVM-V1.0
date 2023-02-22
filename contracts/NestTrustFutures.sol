// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";

import "./interfaces/INestTrustFutures.sol";

import "./NestFutures3.sol";

/// @dev Futures proxy
contract NestTrustFutures is NestFutures3, INestTrustFutures {

    // Status of limit order: executed
    uint constant S_EXECUTED = 0;

    // Status of limit order: normal
    uint constant S_NORMAL = 1;
    
    // Status of limit order: canceled
    uint constant S_CANCELED = 2;

    // TrustOrder, include limit order and stop order
    struct TrustOrder {
        uint32 orderIndex;              // 32
        uint40 balance;                 // 48
        uint40 fee;                     // 48
        uint56 stopProfitPrice;         // 56
        uint56 stopLossPrice;           // 56
        uint8 status;                   // 8
    }

    // Array of TrustOrders
    TrustOrder[] _trustOrders;

    // TODO: 
    // address constant MAINTAINS_ADDRESS = 0x029972C516c4F248c5B066DA07DbAC955bbb5E7F;
    address MAINTAINS_ADDRESS;
    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        MAINTAINS_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.maintains");
    }

    modifier onlyMaintains {
        require(msg.sender == MAINTAINS_ADDRESS, "NFP:not maintains");
        _;
    }

    constructor() {
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
    ) external view override returns (TrustOrderView[] memory orderArray) {
        orderArray = new TrustOrderView[](count);
        // Calculate search region
        TrustOrder[] storage orders = _trustOrders;

        // Loop from start to end
        uint end = 0;
        // start is 0 means Loop from the last item
        if (start == 0) {
            start = orders.length;
        }
        // start > maxFindCount, so end is not 0
        if (start > maxFindCount) {
            end = start - maxFindCount;
        }
        
        // Loop lookup to write qualified records to the buffer
        uint ownerIndex = _accountMapping[owner];
        for (uint index = 0; index < count && start > end;) {
            TrustOrder memory order = orders[--start];
            if (_orders[uint(order.orderIndex)].owner == ownerIndex) {
                orderArray[index++] = _toTrustOrderView(order, start);
            }
        }
    }

    /// @dev List TrustOrder
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function listTrustOrder(
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (TrustOrderView[] memory orderArray) {
        // Load orders
        TrustOrder[] storage orders = _trustOrders;
        // Create result array
        orderArray = new TrustOrderView[](count);
        uint length = orders.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                TrustOrder memory o = orders[--index];
                orderArray[i++] = _toTrustOrderView(o, index);
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
                orderArray[i++] = _toTrustOrderView(orders[index], index);
                ++index;
            }
        }
    }

    /// @dev Create TrustOrder, for everyone
    /// @param channelIndex Index of target trade channel, support eth, btc and bnb
    /// @param lever Leverage of this order
    /// @param orientation Orientation of this order, long or short
    /// @param amount Amount of buy order
    /// @param limitPrice Limit price for trigger buy
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function newTrustOrder(
        uint16 channelIndex, 
        uint8 lever, 
        bool orientation, 
        uint amount, 
        uint limitPrice,
        uint stopProfitPrice,
        uint stopLossPrice
    ) external override {
        // 1. Check arguments
        require(amount > CommonLib.FUTURES_NEST_LB && amount < 0x10000000000, "NF:amount invalid");
        require(lever > CommonLib.LEVER_LB && lever < CommonLib.LEVER_RB, "NF:lever not allowed");
        
        // 2. Service fee, 4 decimals
        uint fee = amount * CommonLib.FEE_RATE * uint(lever) / 1 ether;

        // 3. Create TrustOrder
        _trustOrders.push(TrustOrder(
            // orderIndex
            uint32(_orders.length),
            // balance
            uint40(amount),
            // fee
            uint40(fee),
            // stopProfitPrice
            stopProfitPrice > 0 ? CommonLib.encodeFloat56(stopProfitPrice) : uint56(0),
            // stopLossPrice
            stopLossPrice   > 0 ? CommonLib.encodeFloat56(stopLossPrice  ) : uint56(0),
            // status
            uint8(S_NORMAL)
        ));

        // 4. Create Order
        _orders.push(Order(
            // owner
            uint32(_addressIndex(msg.sender)),
            // basePrice
            // Query oraclePrice
            CommonLib.encodeFloat56(limitPrice),
            // balance
            uint40(0),
            // appends
            uint40(0),
            // channelIndex
            channelIndex,
            // lever
            lever,
            // orientation
            orientation,
            // Pt
            int56(0)
        ));

        // 5. Transfer NEST
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS,
            msg.sender, 
            address(this), 
            (amount + fee + CommonLib.EXECUTE_FEE) * CommonLib.NEST_UNIT
        );
    }

    /// @dev Update limitPrice for TrustOrder
    /// @param trustOrderIndex Index of TrustOrder
    /// @param limitPrice Limit price for trigger buy
    function updateLimitPrice(uint trustOrderIndex, uint limitPrice) external override {
        // Load TrustOrder
        TrustOrder memory trustOrder = _trustOrders[trustOrderIndex];

        // Check status
        require(uint(trustOrder.status) == S_NORMAL, "NF:status error");
        
        // Load Order
        uint orderIndex = uint(trustOrder.orderIndex);
        Order memory order = _orders[orderIndex];
        
        // Check owner
        require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");
        
        // Update limitPrice
        _orders[orderIndex].basePrice = CommonLib.encodeFloat56(limitPrice);
    }

    /// @dev Update stopPrice for TrustOrder
    /// @param trustOrderIndex Index of target TrustOrder
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function updateStopPrice(uint trustOrderIndex, uint stopProfitPrice, uint stopLossPrice) external override {
        // Load TrustOrder
        TrustOrder memory trustOrder = _trustOrders[trustOrderIndex];

        // Check status
        // require(uint(trustOrder.status) != S_EXECUTED, "NF:");

        // Load Order
        //Order memory order = _orders[uint(trustOrder.orderIndex)];

        // Check owner
        require(msg.sender == _accounts[_orders[uint(trustOrder.orderIndex)].owner], "NF:not owner");

        // Update stopPrice
        // When user updateStopPrice, stopProfitPrice and stopLossPrice are not 0 general, so we don't consider 0
        trustOrder.stopProfitPrice = CommonLib.encodeFloat56(stopProfitPrice);
        trustOrder.stopLossPrice   = CommonLib.encodeFloat56(stopLossPrice  );

        _trustOrders[trustOrderIndex] = trustOrder;
    }

    /// @dev Create a new stop order for Order
    /// @param orderIndex Index of target Order
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function newStopOrder(uint orderIndex, uint stopProfitPrice, uint stopLossPrice) public override {
        Order memory order = _orders[orderIndex];

        // The balance of the order is 0, means order cleared, or a LimitOrder haven't executed
        require(uint(order.balance) > 0, "NF:order cleared");
        require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");

        _trustOrders.push(TrustOrder(
            uint32(orderIndex),
            uint40(0),
            uint40(0),
            // When user newStopOrder, stopProfitPrice and stopLossPrice are not 0 general, so we don't consider 0
            CommonLib.encodeFloat56(stopProfitPrice),
            CommonLib.encodeFloat56(stopLossPrice),
            uint8(S_EXECUTED)
        ));
    }

    /// @dev Buy futures with StopOrder
    /// @param channelIndex Index of target channel
    /// @param lever Lever of order
    /// @param orientation true: long, false: short
    /// @param amount Amount of paid NEST, 4 decimals
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function buyWithStopOrder(
        uint16 channelIndex, 
        uint8 lever, 
        bool orientation, 
        uint amount,
        uint stopProfitPrice, 
        uint stopLossPrice
    ) external payable {
        buy(channelIndex, lever, orientation, amount);
        newStopOrder(_orders.length - 1, stopProfitPrice, stopLossPrice);
    }

    /// @dev Cancel TrustOrder, for everyone
    /// @param trustOrderIndex Index of TrustOrder
    function cancelLimitOrder(uint trustOrderIndex) external override {
        // Load TrustOrder
        TrustOrder memory trustOrder = _trustOrders[trustOrderIndex];
        // Check status
        require((trustOrder.status) == S_NORMAL, "NF:status error");
        // Check owner
        require(msg.sender == _accounts[uint(_orders[uint(trustOrder.orderIndex)].owner)], "NF:not owner");

        TransferHelper.safeTransfer(
            NEST_TOKEN_ADDRESS,
            msg.sender,
            (uint(trustOrder.balance) + uint(trustOrder.fee) + CommonLib.EXECUTE_FEE) * CommonLib.NEST_UNIT
        );

        trustOrder.balance = uint40(0);
        trustOrder.fee = uint40(0);
        trustOrder.status = uint8(S_CANCELED);
        _trustOrders[trustOrderIndex] = trustOrder;
    }

    /// @dev Execute limit order, only maintains account
    /// @param trustOrderIndices Array of TrustOrder index
    function executeLimitOrder(uint[] calldata trustOrderIndices) external override onlyMaintains {
        uint totalNest = 0;
        uint oraclePrice = 0;
        uint channelIndex = 0x10000;
        TradeChannel memory channel;

        // 1. Loop and execute
        for (uint i = trustOrderIndices.length; i > 0;) {
            // Load TrustOrder and Order
            uint index = trustOrderIndices[--i];
            TrustOrder memory trustOrder = _trustOrders[index];
            // Check status
            require(trustOrder.status == uint8(S_NORMAL), "NF:status error");
            uint orderIndex = uint(trustOrder.orderIndex);
            Order memory order = _orders[orderIndex];

            if (channelIndex != uint(order.channelIndex)) {
                // If channelIndex is not same with previous, need load new channel and query oracle
                // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                if (channelIndex < 0x10000) {
                    channel.bn = uint32(block.number);
                    _channels[channelIndex] = channel;
                }
                // Load current channel
                channelIndex = uint(order.channelIndex);
                oraclePrice = _lastPrice(channelIndex);
                channel = _channels[channelIndex];

                // Calculate Pt by μ from last order
                uint Lp = uint(channel.Lp);
                uint Sp = uint(channel.Sp);
                if (Lp + Sp > 0) {
                    // Pt is expressed as 56-bits integer, which 12 decimals, representable range is
                    // [-36028.797018963968, 36028.797018963967], assume the earn rate is 0.9% per day,
                    // and it continues 100 years, Pt may reach to 328.725, this is far less than 
                    // 36028.797018963967, so Pt is impossible out of [-36028.797018963968, 36028.797018963967].
                    // And even so, Pt is truncated, the consequences are not serious, so we don't check truncation
                    channel.Pt = int56(
                        int(channel.Pt) + 
                        // μ is not saved, and calculate it by Lp and Sp always
                        // 694444 = 0.02e12 / 86400 * CommonLib.BLOCK_TIME / 1000
                        694444 * (int(Lp) - int(Sp)) * int((block.number - uint(channel.bn))) / int(Lp + Sp)
                    );
                }
            }

            uint balance = uint(trustOrder.balance);
            uint lever = uint(order.lever);

            // Update Lp and Sp, for calculate next μ
            // Lp and Sp are add(sub) with original bond
            // When buy, Lp(Sp) += lever * amount
            // When sell(liquidate), Lp(Sp) -= lever * amount
            // Original bond not include service fee

            // Lp ans Sp are 56-bits unsigned integer, defined as 4 decimals, which representable range is
            // [0, 7205759403792.7935], total supply of NEST is 10000000000, with max leverage 50, the 
            // maximum value is 500000000000, Lp ans Sp is impossible to reach 7205759403792.7935,
            // so we don't check truncation here
            if (order.orientation) {
                channel.Lp = uint56(uint(channel.Lp) + balance * lever);
            } 
            else {
                channel.Sp = uint56(uint(channel.Sp) + balance * lever);
            }
            totalNest += balance + uint(trustOrder.fee);

            // Update Order: basePrice, baseBlock, balance, Pt
            order.basePrice = CommonLib.encodeFloat56(oraclePrice);
            order.balance = uint40(balance);
            order.Pt = channel.Pt;

            // Update TrustOrder: balance, status
            trustOrder.balance = uint40(0);
            trustOrder.fee = uint40(0);
            trustOrder.status = uint8(S_EXECUTED);

            // Update TrustOrder and Order
            _trustOrders[index] = trustOrder;
            _orders[orderIndex] = order;
        }

        // Update last channel
        if (channelIndex < 0x10000) {
            channel.bn = uint32(block.number);
            _channels[channelIndex] = channel;
        }

        // Transfer NEST to NestVault
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, NEST_VAULT_ADDRESS, totalNest * CommonLib.NEST_UNIT);
    }

    /// @dev Execute stop order, only maintains account
    /// @param trustOrderIndices Array of TrustOrder index
    function executeStopOrder(uint[] calldata trustOrderIndices) external override onlyMaintains {
        uint executeFee = 0;
        uint oraclePrice = 0;
        uint channelIndex = 0x10000;
        TradeChannel memory channel;

        // 1. Loop and execute
        for (uint i = trustOrderIndices.length; i > 0;) {
            TrustOrder memory trustOrder = _trustOrders[trustOrderIndices[--i]];
            require(uint(trustOrder.status) == S_EXECUTED, "NF:status error");
            Order memory order = _orders[uint(trustOrder.orderIndex)];
            uint balance = uint(order.balance);

            if (balance > 0) {
                uint lever = uint(order.lever);
                uint basePrice = CommonLib.decodeFloat(uint(order.basePrice));
                address owner = _accounts[uint(order.owner)];

                if (channelIndex != uint(order.channelIndex)) {
                    // If channelIndex is not same with previous, need load new channel and query oracle
                    // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                    if (channelIndex < 0x10000) {
                        channel.bn = uint32(block.number);
                        _channels[channelIndex] = channel;
                    }
                    // Load current channel
                    channelIndex = uint(order.channelIndex);
                    oraclePrice = _lastPrice(channelIndex);
                    channel = _channels[channelIndex];

                    // Calculate Pt by μ from last order
                    uint Lp = uint(channel.Lp);
                    uint Sp = uint(channel.Sp);
                    if (Lp + Sp > 0) {
                        // Pt is expressed as 56-bits integer, which 12 decimals, representable range is
                        // [-36028.797018963968, 36028.797018963967], assume the earn rate is 0.9% per day,
                        // and it continues 100 years, Pt may reach to 328.725, this is far less than 
                        // 36028.797018963967, so Pt is impossible out of [-36028.797018963968, 36028.797018963967].
                        // And even so, Pt is truncated, the consequences are not serious, so we don't check truncation
                        channel.Pt = int56(
                            int(channel.Pt) + 
                            // μ is not saved, and calculate it by Lp and Sp always
                            // 694444 = 0.02e12 / 86400 * CommonLib.BLOCK_TIME / 1000
                            694444 * (int(Lp) - int(Sp)) * int((block.number - uint(channel.bn))) / int(Lp + Sp)
                        );
                    }
                }

                // Update Lp and Sp, for calculate next μ
                // Lp and Sp are add(sub) with original bond
                // When buy, Lp(Sp) += lever * amount
                // When sell(liquidate), Lp(Sp) -= lever * amount
                // Original bond not include service fee

                // Lp ans Sp are 56-bits unsigned integer, defined as 4 decimals, which representable range is
                // [0, 7205759403792.7935], total supply of NEST is 10000000000, with max leverage 50, the 
                // maximum value is 500000000000, Lp ans Sp is impossible to reach 7205759403792.7935,
                // so we don't check truncation here
                if (order.orientation) {
                    channel.Lp = uint56(uint(channel.Lp) - balance * lever);
                } else {
                    channel.Sp = uint56(uint(channel.Sp) - balance * lever);
                }

                uint value = _valueOf(
                    int(channel.Pt) - int(order.Pt),
                    balance * CommonLib.NEST_UNIT,
                    basePrice,
                    oraclePrice,
                    order.orientation,
                    lever,
                    uint(order.appends)
                );

                order.balance = uint40(0);
                order.appends = uint40(0);
                _orders[uint(trustOrder.orderIndex)] = order;

                uint fee = balance 
                         * CommonLib.NEST_UNIT 
                         * lever 
                         * oraclePrice 
                         / basePrice 
                         * CommonLib.FEE_RATE 
                         / 1 ether;
                         
                // Newest value of order is greater than fee + EXECUTE_FEE, deduct and transfer NEST to owner
                if (value > fee + CommonLib.EXECUTE_FEE_NEST) {
                    INestVault(NEST_VAULT_ADDRESS).transferTo(owner, value - fee - CommonLib.EXECUTE_FEE_NEST);
                }
                executeFee += CommonLib.EXECUTE_FEE_NEST;

                emit Sell(uint(trustOrder.orderIndex), balance, owner, value);
            }
        }
        
        // Update last channel
        if (channelIndex < 0x10000) {
            channel.bn = uint32(block.number);
            _channels[channelIndex] = channel;
        }

        // Transfer EXECUTE_FEE to proxy address
        INestVault(NEST_VAULT_ADDRESS).transferTo(address(this), executeFee);
    }

    /// @dev Settle execute fee to MAINTAINS_ADDRESS
    /// @param value Value of total execute fee
    function settleExecuteFee(uint value) external onlyGovernance {
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, MAINTAINS_ADDRESS, value);
    }

    // Convert TrustOrder to TrustOrderView
    function _toTrustOrderView(TrustOrder memory trustOrder, uint index) internal view returns (TrustOrderView memory v) {
        Order memory order = _orders[uint(trustOrder.orderIndex)];
        v = TrustOrderView(
            // Index of this TrustOrder
            uint32(index),
            // Owner of this order
            _accounts[order.owner],
            // Index of target Order
            trustOrder.orderIndex,
            // Index of target channel, support eth(0), btc(1) and bnb(2)
            order.channelIndex,
            // Leverage of this order
            order.lever,
            // Orientation of this order, long or short
            order.orientation,

            // Limit price for trigger buy
            CommonLib.decodeFloat(order.basePrice),
            // Stop price for trigger sell
            CommonLib.decodeFloat(trustOrder.stopProfitPrice),
            CommonLib.decodeFloat(trustOrder.stopLossPrice),

            // Balance of nest, 4 decimals
            trustOrder.balance,
            // Service fee, 4 decimals
            trustOrder.fee,
            // Status of order, 0: executed, 1: normal, 2: canceled
            trustOrder.status
        );
    }
}
