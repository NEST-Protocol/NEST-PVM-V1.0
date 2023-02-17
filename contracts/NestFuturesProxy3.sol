// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";

import "./interfaces/INestFutures2.sol";

import "./NestFutures3.sol";

/// @dev Futures proxy
contract NestFuturesProxy3 is NestFutures3 {

    // Status of limit order: executed
    uint constant S_EXECUTED = 0;
    // Status of limit order: normal
    uint constant S_NORMAL = 1;
    // Status of limit order: canceled
    uint constant S_CANCELED = 2;

    // TrustOrder, include limit order and stop order
    struct TrustOrder {
        uint32 orderIndex;            // 32
        //uint56 limitPrice;          // 56
        //uint16 channelIndex;        // 16
        //uint8 lever;                // 8
        //bool orientation;           // 8
        uint48 balance;             // 48
        uint48 fee;                 // 48
        //uint48 limitFee;            // 48
        uint56 stopProfitPrice;     // 56
        uint56 stopLossPrice;       // 56
        uint8 status;               // 8
    }

    // Array of TrustOrders
    TrustOrder[] _trustOrders;

    address constant MAINTAINS_ADDRESS = 0x029972C516c4F248c5B066DA07DbAC955bbb5E7F;

    modifier onlyMaintains {
        require(msg.sender == MAINTAINS_ADDRESS, "NFP:not maintains");
        _;
    }

    constructor() {

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
    ) external {
        // 1. Check arguments
        require(amount > CommonLib.FUTURES_NEST_LB && amount < 0x1000000000000, "NF:amount invalid");
        require(lever > CommonLib.LEVER_LB && lever < CommonLib.LEVER_RB, "NF:lever not allowed");
        
        // 2. Service fee, 4 decimals
        uint fee = amount * CommonLib.FEE_RATE * uint(lever) / 1 ether;

        // 3. Create TrustOrder
        _trustOrders.push(TrustOrder(
            // orderIndex
            uint32(_orders.length),
            // balance
            uint48(amount),
            // fee
            uint48(fee),
            // stopProfitPrice
            stopProfitPrice > 0 ? CommonLib.encodeFloat56(stopProfitPrice) : uint56(0),
            // stopLossPrice
            stopLossPrice > 0 ? CommonLib.encodeFloat56(stopLossPrice) : uint56(0),
            // status
            uint8(S_NORMAL)
        ));

        // 4. Create Order
        _orders.push(Order(
            // owner
            uint32(_addressIndex(msg.sender)),
            // basePrice
            // Query oraclePrice
            // TODO: Rewrite queryPrice function
            CommonLib.encodeFloat56(limitPrice),
            // balance
            uint48(0),
            // baseBlock
            uint32(block.number),
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
    function updateLimitPrice(uint trustOrderIndex, uint limitPrice) external {
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
    function changeStopPrice(uint trustOrderIndex, uint stopProfitPrice, uint stopLossPrice) external {
        // Load TrustOrder
        TrustOrder memory trustOrder = _trustOrders[trustOrderIndex];

        // Check status
        // require(uint(trustOrder.status) != S_EXECUTED, "NF:");

        // Load Order
        //Order memory order = _orders[uint(trustOrder.orderIndex)];

        // Check owner
        require(msg.sender == _accounts[_orders[uint(trustOrder.orderIndex)].owner], "NF:not owner");

        // Update stopPrice
        trustOrder.stopProfitPrice = stopProfitPrice > 0 ? CommonLib.encodeFloat56(stopProfitPrice) : uint56(0);
        trustOrder.stopLossPrice   = stopLossPrice   > 0 ? CommonLib.encodeFloat56(stopLossPrice)   : uint56(0);

        _trustOrders[trustOrderIndex] = trustOrder;
    }

    /// @dev Create a new stop order for Order
    /// @param orderIndex Index of target Order
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function newStopOrder(uint orderIndex, uint stopProfitPrice, uint stopLossPrice) external {
        Order memory order = _orders[orderIndex];
        require(uint(order.balance) > 0, "NF:order cleared");
        require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");

        _trustOrders.push(TrustOrder(
            uint32(orderIndex),
            uint48(0),
            uint48(0),
            stopProfitPrice > 0 ? CommonLib.encodeFloat56(stopProfitPrice) : uint56(stopProfitPrice),
            stopLossPrice > 0 ? CommonLib.encodeFloat56(stopLossPrice) : uint56(stopLossPrice),
            uint8(S_EXECUTED)
        ));
    }

    /// @dev Cancel TrustOrder, for everyone
    /// @param trustOrderIndex Index of TrustOrder
    function cancelLimitOrder(uint trustOrderIndex) external {
        // Load TrustOrder
        TrustOrder memory trustOrder = _trustOrders[trustOrderIndex];
        // Check status
        require((trustOrder.status) == S_NORMAL, "NF:status error");
        // Check owner
        require(msg.sender == _accounts[uint(_orders[uint(trustOrder.orderIndex)].owner)], "NF:not owner");

        trustOrder.status = uint8(S_CANCELED);
        _trustOrders[trustOrderIndex] = trustOrder;

        TransferHelper.safeTransfer(
            NEST_TOKEN_ADDRESS,
            msg.sender,
            (uint(trustOrder.balance) + uint(trustOrder.fee) + CommonLib.EXECUTE_FEE) * CommonLib.NEST_UNIT
        );
    }

    /// @dev Execute limit order, only maintains account
    /// @param trustOrderIndices Array of TrustOrder index
    function executeLimitOrder(uint[] calldata trustOrderIndices) external onlyMaintains {
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
                oraclePrice = _queryPrice(channelIndex);
                channel = _channels[channelIndex];

                // Update Lp and Sp, for calculate next μ
                // Lp and Sp are add(sub) with original bond
                // When buy, Lp(Sp) += lever * amount
                // When sell(liquidate), Lp(Sp) -= lever * amount
                // Original bond not include service fee
                uint Lp = uint(channel.Lp);
                uint Sp = uint(channel.Sp);
                if (Lp + Sp > 0) {
                    // μ is not saved, and calculate it by Lp and Sp always
                    int miu = (int(Lp) - int(Sp)) * 0.02e12 / 86400 / int(Lp + Sp);
                    // TODO: Check truncation
                    channel.Pt = int56(
                        int(channel.Pt) + 
                        miu * int((block.number - uint(channel.bn)) * CommonLib.BLOCK_TIME / 1000)
                    );
                }
            }

            uint balance = uint(trustOrder.balance);
            uint lever = uint(order.lever);
            if (order.orientation) {
                channel.Lp = uint56(uint(channel.Lp) + balance * lever);
            } else {
                channel.Sp = uint56(uint(channel.Sp) + balance * lever);
            }
            totalNest += balance + uint(trustOrder.fee);

            // Update Order: basePrice, baseBlock, balance, Pt
            order.basePrice = CommonLib.encodeFloat56(oraclePrice);
            order.baseBlock = uint32(block.number);
            order.balance = uint48(balance);
            order.Pt = channel.Pt;

            // Update TrustOrder: balance, status
            trustOrder.balance = 0;
            trustOrder.status = uint8(S_EXECUTED);

            // Update TrustOrder and Order
            _trustOrders[index] = trustOrder;
            _orders[orderIndex] = order;
        }

        // TODO: Test if no this code
        // Update previous channel
        if (channelIndex < 0x10000) {
            channel.bn = uint32(block.number);
            _channels[channelIndex] = channel;
        }

        // Transfer NEST to NestVault
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, NEST_VAULT_ADDRESS, totalNest * CommonLib.NEST_UNIT);
    }

    /// @dev Execute stop order, only maintains account
    /// @param trustOrderIndices Array of TrustOrder index
    function executeStopOrder(uint[] calldata trustOrderIndices) external {
        uint executeFee = 0;
        uint oraclePrice = 0;
        uint channelIndex = 0x10000;
        TradeChannel memory channel;

        // 1. Loop and execute
        for (uint i = trustOrderIndices.length; i > 0;) {
            TrustOrder memory trustOrder = _trustOrders[trustOrderIndices[--i]];
            require(uint(trustOrder.status) == S_EXECUTED, "NF:status error");
            uint orderIndex = uint(trustOrder.orderIndex);
            Order memory order = _orders[orderIndex];
            uint balance = uint(order.balance);

            if (balance > 0) {
                uint lever = uint(order.lever);
                uint basePrice = CommonLib.decodeFloat(uint(order.basePrice));
                address owner = _accounts[uint(order.owner)];

                // TODO: To update the last channel
                if (channelIndex != uint(order.channelIndex)) {
                    // If channelIndex is not same with previous, need load new channel and query oracle
                    // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                    if (channelIndex < 0x10000) {
                        channel.bn = uint32(block.number);
                        _channels[channelIndex] = channel;
                    }
                    // Load current channel
                    channelIndex = uint(order.channelIndex);
                    oraclePrice = _queryPrice(channelIndex);
                    channel = _channels[channelIndex];

                    // Update Lp and Sp, for calculate next μ
                    // Lp and Sp are add(sub) with original bond
                    // When buy, Lp(Sp) += lever * amount
                    // When sell(liquidate), Lp(Sp) -= lever * amount
                    // Original bond not include service fee
                    uint Lp = uint(channel.Lp);
                    uint Sp = uint(channel.Sp);
                    if (Lp + Sp > 0) {
                        // μ is not saved, and calculate it by Lp and Sp always
                        int miu = (int(Lp) - int(Sp)) * 0.02e12 / 86400 / int(Lp + Sp);
                        // TODO: Check truncation
                        channel.Pt = int56(
                            int(channel.Pt) + 
                            miu * int((block.number - uint(channel.bn)) * CommonLib.BLOCK_TIME / 1000)
                        );
                    }
                }

                if (order.orientation) {
                    channel.Lp = uint56(uint(channel.Lp) - balance * lever);
                } else {
                    channel.Sp = uint56(uint(channel.Sp) - balance * lever);
                }

                order.balance = uint48(0);
                _orders[orderIndex] = order;

                uint value = _valueOf(
                    int(channel.Pt) - int(order.Pt),
                    balance * CommonLib.NEST_UNIT,
                    basePrice,
                    oraclePrice,
                    order.orientation,
                    lever
                );

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

                emit Sell(orderIndex, balance, owner, value);
            }
        }
        
        // TODO: Test if no this code
        // Update previous channel
        if (channelIndex < 0x10000) {
            channel.bn = uint32(block.number);
            _channels[channelIndex] = channel;
        }

        // Transfer EXECUTE_FEE to proxy address
        INestVault(NEST_VAULT_ADDRESS).transferTo(address(this), executeFee);
    }
}
