// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";
import "./libs/PancakeLibrary.sol";

import "./interfaces/INestTrustFutures.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IPancakeFactory.sol";

import "./NestFutures3V3.sol";

/// @dev Futures proxy
contract NestTrustFuturesV3 is NestFutures3V3, INestTrustFutures {

    // Status of limit order: executed
    uint constant S_EXECUTED = 0;

    // Status of limit order: normal
    uint constant S_NORMAL = 1;
    
    // Status of limit order: canceled
    uint constant S_CANCELED = 2;

    // TrustOrder, include limit order and stop order
    struct TrustOrder {
        // Index of target Order
        uint32 orderIndex;              // 32
        // Balance of nest, 4 decimals
        uint40 balance;                 // 48
        // Service fee, 4 decimals
        uint40 fee;                     // 48
        // Stop price for trigger sell, encoded by encodeFloat56()
        uint56 stopProfitPrice;         // 56
        // Stop price for trigger sell, encoded by encodeFloat56()
        uint56 stopLossPrice;           // 56
        // Status of order, 0: executed, 1: normal, 2: canceled
        uint8 status;                   // 8
    }

    // Array of TrustOrders
    TrustOrder[] _trustOrders;

    // TODO:
    //address constant MAINTAINS_ADDRESS = 0x029972C516c4F248c5B066DA07DbAC955bbb5E7F;
    address MAINTAINS_ADDRESS;
    address NEST_USDT_PAIR_ADDRESS;
    address USDT_TOKEN_ADDRESS;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        MAINTAINS_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.maintains");
        NEST_USDT_PAIR_ADDRESS = INestGovernance(newGovernance).checkAddress("pancake.pair.nestusdt");
        USDT_TOKEN_ADDRESS = INestGovernance(newGovernance).checkAddress("common.token.usdt");
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
        unchecked {
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
        unchecked {
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
        // 1. Create TrustOrder
        uint fee = _newTrustOrder(channelIndex, lever, orientation, amount, limitPrice, stopProfitPrice, stopLossPrice);

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
        uint channelIndex, 
        uint lever, 
        bool orientation, 
        uint amount,
        uint stopProfitPrice, 
        uint stopLossPrice
    ) external payable override {
        _trustOrders.push(TrustOrder(
            uint32(_buy(channelIndex, lever, orientation, amount)),
            uint40(0),
            uint40(0),
            // When user newStopOrder, stopProfitPrice and stopLossPrice are not 0 general, so we don't consider 0
            CommonLib.encodeFloat56(stopProfitPrice),
            CommonLib.encodeFloat56(stopLossPrice),
            uint8(S_EXECUTED)
        ));
        // Transfer NEST from user
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_VAULT_ADDRESS, 
            amount * CommonLib.NEST_UNIT * (1 ether + FEE_RATE * lever) / 1 ether
        );
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
        uint index = 0;
        uint i = trustOrderIndices.length << 5;
        while (i > 0) { 
            // Load TrustOrder and Order
            // uint index = trustOrderIndices[--i];
            assembly {
                i := sub(i, 0x20)
                index := calldataload(add(trustOrderIndices.offset, i))
            }

            TrustOrder memory trustOrder = _trustOrders[index];
            // Check status
            require(trustOrder.status == uint8(S_NORMAL), "NF:status error");
            uint orderIndex = uint(trustOrder.orderIndex);
            Order memory order = _orders[orderIndex];

            if (channelIndex != uint(order.channelIndex)) {
                // If channelIndex is not same with previous, need load new channel and query oracle
                // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                if (channelIndex < 0x10000) {
                    _channels[channelIndex] = channel;
                }
                // Load current channel
                channelIndex = uint(order.channelIndex);
                oraclePrice = _lastPrice(channelIndex);
                channel = _updateChannel(channelIndex, oraclePrice);
            }

            uint balance = uint(trustOrder.balance);
            totalNest += (balance + uint(trustOrder.fee));

            // Update Order: basePrice, baseBlock, balance, Pt
            order.basePrice = CommonLib.encodeFloat56(oraclePrice);
            order.balance = uint40(balance);
            order.Pt = order.orientation ? channel.PtL : channel.PtS;

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
                address owner = _accounts[uint(order.owner)];

                if (channelIndex != uint(order.channelIndex)) {
                    // If channelIndex is not same with previous, need load new channel and query oracle
                    // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                    if (channelIndex < 0x10000) {
                        _channels[channelIndex] = channel;
                    }
                    // Load current channel
                    channelIndex = uint(order.channelIndex);
                    oraclePrice = _lastPrice(channelIndex);
                    channel = _updateChannel(channelIndex, oraclePrice);
                }

                (uint value, uint fee) = _valueOf(channel, order, oraclePrice);

                order.balance = uint40(0);
                order.appends = uint40(0);
                _orders[uint(trustOrder.orderIndex)] = order;

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

    // function buyWithUsdt(
    //     uint usdtAmount,
    //     uint channelIndex,
    //     uint lever,
    //     bool orientation,
    //     uint minAmount,
    //     uint stopProfitPrice,
    //     uint stopLossPrice
    // ) external {
    //     address[] memory path = new address[](2);
    //     path[0] = USDT_TOKEN_ADDRESS;
    //     path[1] = NEST_TOKEN_ADDRESS;

    //     TransferHelper.safeTransferFrom(USDT_TOKEN_ADDRESS, msg.sender, address(this), usdtAmount);
    //     SimpleERC20(USDT_TOKEN_ADDRESS).approve(PANCAKE_ROUTER_ADDRESS, usdtAmount);
    //     uint[] memory amounts = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS).swapExactTokensForTokens(
    //         usdtAmount,
    //         minAmount,
    //         path,
    //         address(this),
    //         block.timestamp
    //     );

    //     uint amount = amounts[amounts.length - 1];
    //     require(amount > minAmount, 'NF:INSUFFICIENT_OUTPUT_AMOUNT');
    //     uint orderIndex = _buy(
    //         channelIndex, 
    //         lever, 
    //         orientation, 
    //         amount * 1 ether / (1 ether + FEE_RATE * lever) / CommonLib.NEST_UNIT
    //     );
    //     if (stopProfitPrice > 0 || stopLossPrice > 0) {
    //         _trustOrders.push(TrustOrder(
    //             uint32(orderIndex),
    //             uint40(0),
    //             uint40(0),
    //             CommonLib.encodeFloat56(stopProfitPrice),
    //             CommonLib.encodeFloat56(stopLossPrice),
    //             uint8(S_EXECUTED)
    //         ));
    //     }
    //     TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, NEST_VAULT_ADDRESS, amount);
    // }

    /// @dev Buy futures use USDT
    /// @param usdtAmount Amount of paid USDT, 18 decimals
    /// @param minNestAmount Minimal amount of  NEST, 18 decimals
    /// @param channelIndex Index of target channel
    /// @param lever Lever of order
    /// @param orientation true: long, false: short
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function buyWithUsdt(
        uint usdtAmount,
        uint minNestAmount,
        uint channelIndex,
        uint lever,
        bool orientation,
        uint stopProfitPrice,
        uint stopLossPrice
    ) external {
        // 1. Swap with NEST-USDT pair at pancake
        uint nestAmount = _swapUsdtForNest(usdtAmount, minNestAmount, NEST_VAULT_ADDRESS);

        // 2. Create buy order
        uint orderIndex = _buy(
            channelIndex, 
            lever, 
            orientation, 
            nestAmount * 1 ether / (1 ether + FEE_RATE * lever) / CommonLib.NEST_UNIT
        );
        
        // 3. Create stop order
        if (stopProfitPrice > 0 || stopLossPrice > 0) {
            _trustOrders.push(TrustOrder(
                uint32(orderIndex),
                uint40(0),
                uint40(0),
                CommonLib.encodeFloat56(stopProfitPrice),
                CommonLib.encodeFloat56(stopLossPrice),
                uint8(S_EXECUTED)
            ));
        }
    }

    /// @dev Create TrustOrder use USDT, for everyone
    /// @param usdtAmount Amount of paid USDT, 18 decimals
    /// @param minNestAmount Minimal amount of  NEST, 18 decimals
    /// @param channelIndex Index of target trade channel, support eth, btc and bnb
    /// @param lever Leverage of this order
    /// @param orientation Orientation of this order, long or short
    /// @param limitPrice Limit price for trigger buy
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function newTrustOrderWithUsdt(
        uint usdtAmount,
        uint minNestAmount, 
        uint16 channelIndex, 
        uint8 lever, 
        bool orientation, 
        uint limitPrice,
        uint stopProfitPrice,
        uint stopLossPrice
    ) external {
        // 1. Swap with NEST-USDT pair at pancake
        uint nestAmount = _swapUsdtForNest(usdtAmount, minNestAmount, address(this));

        // 2. Create TrustOrder
        _newTrustOrder(
            channelIndex,
            lever,
            orientation,
            (nestAmount / CommonLib.NEST_UNIT - CommonLib.EXECUTE_FEE) * 1 ether / (1 ether + FEE_RATE * uint(lever)),
            limitPrice,
            stopProfitPrice,
            stopLossPrice
        );
    }

    // Swap USDT to NEST
    function _swapUsdtForNest(uint usdtAmount, uint minNestAmount, address to) internal returns (uint nestAmount) {
        // 1. Calculate out nestAmount
        (address token0,) = PancakeLibrary.sortTokens(USDT_TOKEN_ADDRESS, NEST_TOKEN_ADDRESS);
        (uint reserveIn, uint reserveOut,) = IPancakePair(NEST_USDT_PAIR_ADDRESS).getReserves();
        (reserveIn, reserveOut) = USDT_TOKEN_ADDRESS == token0 ? (reserveIn, reserveOut) : (reserveOut, reserveIn);
        nestAmount = PancakeLibrary.getAmountOut(usdtAmount, reserveIn, reserveOut);
        require(nestAmount > minNestAmount, 'NF:INSUFFICIENT_OUTPUT_AMOUNT');

        // 2. Swap with NEST-USDT pair at pancake
        TransferHelper.safeTransferFrom(
            USDT_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_USDT_PAIR_ADDRESS, 
            usdtAmount
        );
        IPancakePair(NEST_USDT_PAIR_ADDRESS).swap(0, nestAmount, to, new bytes(0)); 
    }


    // Create TrustOrder
    function _newTrustOrder(
        uint16 channelIndex, 
        uint8 lever, 
        bool orientation, 
        uint amount, 
        uint limitPrice,
        uint stopProfitPrice,
        uint stopLossPrice
    ) internal returns (uint fee) {
        // 1. Check arguments
        require(amount > CommonLib.FUTURES_NEST_LB && amount < 0x10000000000, "NF:amount invalid");
        require(lever > CommonLib.LEVER_LB && lever < CommonLib.LEVER_RB, "NF:lever not allowed");
        
        // 2. Service fee, 4 decimals
        fee = amount * FEE_RATE * uint(lever) / 1 ether;

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
    }

    // Convert TrustOrder to TrustOrderView
    function _toTrustOrderView(
        TrustOrder memory trustOrder, 
        uint index
    ) internal view returns (TrustOrderView memory v) {
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
