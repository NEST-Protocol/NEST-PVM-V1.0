// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";
import "./libs/PancakeLibrary.sol";

import "./interfaces/ICommonGovernance.sol";
import "./interfaces/INestFutures5.sol";
import "./interfaces/IPancakePair.sol";

import "./common/CommonBase.sol";

/// @dev Nest futures with responsive
contract NestFutures5V1 is CommonBase, INestFutures5 {

    /// @dev Order for view methods
    struct OfflineOrder {
        // Owner of this order
        address owner;
        // Balance of this order, 4 decimals
        uint40 balance;
        // Index of target channel, support eth, btc and bnb
        uint8 channelIndex;
        // Leverage of this order
        uint8 lever;
        // Orientation of this order, long or short
        bool orientation;
        // Base price of this order
        uint basePrice;
        uint40 fee;
        // Stop price for trigger sell, encoded by encodeFloat40()
        uint stopProfitPrice;         // 56
        // Stop price for trigger sell, encoded by encodeFloat40()
        uint stopLossPrice;           // 56
    }

    struct ExecuteItem {
        uint orderIndex;
        uint executePrice;
        uint operation;
    }

    // Number of channels
    uint constant CHANNEL_COUNT = 7;

    // Service fee for buy, sell, add and liquidate
    uint constant FEE_RATE = 0.0005 ether;
    
    // Status of order
    uint constant S_CLEARED         = 0x00;
    uint constant S_BUY_REQUEST     = 0x01;
    uint constant S_NORMAL          = 0x02;
    uint constant S_SELL_REQUEST    = 0x03;
    uint constant S_LIMIT_REQUEST   = 0x04;
    uint constant S_CANCELED        = 0xFF;

    uint constant OP_SELL           = 0x01;
    uint constant OP_LIQUIDATE      = 0x02;

    // Array of orders
    Order[] _orders;
    mapping(address=>uint) _balances;

    // TODO:
    // Address of direct poster
    // address constant DIRECT_POSTER = 0x06Ca5C8eFf273009C94D963e0AB8A8B9b09082eF;  // bsc_main
    // address constant DIRECT_POSTER = 0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681;  // bsc_test
    // address constant USDT_TOKEN_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;
    // address constant NEST_USDT_PAIR_ADDRESS = 0x04fF0eA8a05F1c75557981e9303568F043B88b4C;
    address NEST_TOKEN_ADDRESS;
    address DIRECT_POSTER;
    address NEST_USDT_PAIR_ADDRESS;
    address USDT_TOKEN_ADDRESS;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param governance INestGovernance implementation contract address
    function update(address governance) external onlyGovernance {
        NEST_TOKEN_ADDRESS = ICommonGovernance(governance).checkAddress("nest.app.nest");
        DIRECT_POSTER = ICommonGovernance(governance).checkAddress("nest.app.directPoster");
        NEST_USDT_PAIR_ADDRESS = ICommonGovernance(governance).checkAddress("pancake.pair.nestusdt");
        USDT_TOKEN_ADDRESS = ICommonGovernance(governance).checkAddress("common.token.usdt");
    }

    constructor() {
    }

    function deposits(address target) external view returns (uint) {
        return _balances[target];
    }

    function deposit(uint amount) external {
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), amount);
        _balances[msg.sender] += amount;
    }

    function swapAndDeposit(
        uint usdtAmount,
        uint minNestAmount
    ) external returns (uint nestAmount) {
        // 1. Swap with NEST-USDT pair at pancake
        nestAmount = _swapUsdtForNest(usdtAmount, minNestAmount, address(this));
        _balances[msg.sender] += nestAmount;
    }

    function withdraw(uint amount) external {
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, msg.sender, amount);
        _balances[msg.sender] -= amount;
    }

    function submit(OfflineOrder[] calldata offlineOrders) external {
        require(msg.sender == DIRECT_POSTER, "NF:not executor");

        for (uint i = 0; i < offlineOrders.length; ++i) {
            OfflineOrder memory offlineOrder = offlineOrders[i];
            address owner = offlineOrder.owner;
            uint cost = (uint(offlineOrder.balance) + uint(offlineOrder.fee)) * CommonLib.NEST_UNIT;
            if (_balances[owner] < cost) {
                continue;
            }
            _balances[owner] -= cost; 
            _orders.push(Order(
                // Address of owner
                //address owner;
                owner,
                // Status of order
                //uint8 status;
                uint8(S_NORMAL),
                // Index of target channel, support eth, btc and bnb
                //uint8 channelIndex;
                offlineOrder.channelIndex,
                // Leverage of this order
                //uint8 lever;
                offlineOrder.lever,
                // Block number of this order opened
                //uint32 openBlock;
                uint32(block.number),
                // Base price of this order, encoded with encodeFloat40()
                //uint40 basePrice;
                CommonLib.encodeFloat40(offlineOrder.basePrice),
                
                // Balance of this order, 4 decimals
                //uint40 balance;
                offlineOrder.balance,
                // Append amount of this order
                //uint40 appends;
                uint40(0),
                // Service fee, 4 decimals
                //uint40 fee;
                offlineOrder.fee,

                // Orientation of this order, long or short
                //bool orientation;
                offlineOrder.orientation,

                // Stop price for trigger sell, encoded by encodeFloat40()
                //uint40 stopProfitPrice;
                CommonLib.encodeFloat40(offlineOrder.stopProfitPrice),
                // Stop price for trigger sell, encoded by encodeFloat40()
                //uint40 stopLossPrice;
                CommonLib.encodeFloat40(offlineOrder.stopLossPrice)
            ));
        }
    }

    /// @dev Execute
    /// @param items Array of ExecuteItems
    function execute(ExecuteItem[] calldata items) external {
        require(msg.sender == DIRECT_POSTER, "NF:not directPoster");
        
        // Total reward of liquidation
        uint reward = 0;
        uint orderIndex = 0;

        for (uint i = 0; i < items.length; ++i) {

            // 0. Load Order
            ExecuteItem memory item = items[i];
            Order memory order = _orders[item.orderIndex];
            uint status = uint(order.status);
            if (status != S_NORMAL) {
                continue;
            }
            uint balance = uint(order.balance);
            uint oraclePrice = item.executePrice;
            uint operation = item.operation;

            // 2. Execute sell request
            if (operation == OP_SELL) {
                // Calculate value and update Order
                (uint value, uint fee) = _valueOf(order, oraclePrice);
                emit Sell(orderIndex, balance, order.owner, value);

                // Clear second slot of order
                order.balance = uint40(0);
                order.appends = uint40(0);
                order.fee = uint40(0);
                // In order to revert gas, set all status of order in second slot to 0
                order.orientation = false;
                order.stopProfitPrice = uint40(0);
                order.stopLossPrice = uint40(0);

                order.status = uint8(S_CLEARED);

                // Transfer NEST to user
                // If value grater than fee, deduct and transfer NEST to owner
                if (value > fee) {
                    unchecked {
                        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, order.owner, value - fee);
                    }
                }
            }
            // Normal, Liquidate or stop
            else if (operation == OP_LIQUIDATE) {
                if (balance == 0) {
                    continue;
                }
                (uint value, uint fee) = _valueOf(order, oraclePrice);
                // 4. Liquidate
                if (uint(order.lever) > 1) {
                    // Liquidate logic
                    // lever is great than 1, and balance less than a regular value, can be liquidated
                    // the regular value is: Max(M0 * L * St / S0 * c, a) | expired
                    // the regular value is: Max(M0 * L * St / S0 * c + a, M0 * L * 0.5%) | expired
                    // the regular value is: Max(M0 * L * St / S0 * c + a, M0 * L * 1%)
                    unchecked {
                        if (value < balance * CommonLib.NEST_UNIT * uint(order.lever) / 100 || 
                            value < fee + CommonLib.MIN_FUTURE_VALUE) {
                            // Clear all data of order, use this code next time
                            assembly {
                                mstore(0, _orders.slot)
                                let offset := add(keccak256(0, 0x20), shl(1, orderIndex))
                                // Each Order take 2 slots
                                sstore(offset, 0)
                                sstore(add(offset, 1), 0)
                            }
                            
                            // Add reward
                            reward += value;

                            // Emit liquidate event
                            emit Liquidate(orderIndex, order.owner, value);
                            continue;
                        }
                    }
                }
            }

            _orders[orderIndex] = order;
        }

        if (reward > 0) {
            TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, msg.sender, reward);
        }
    }

    /// @dev Returns the current value of target order
    /// @param orderIndex Index of order
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    function balanceOf(uint orderIndex, uint oraclePrice) external view override returns (uint value) {
        (value,) = _valueOf(_orders[orderIndex], oraclePrice);
    }

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
    ) external view override returns (OrderView[] memory orderArray) {
        unchecked {
            orderArray = new OrderView[](count);
            // Calculate search region
            Order[] storage orders = _orders;

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
            //uint ownerIndex = _accountMapping[owner];
            for (uint index = 0; index < count && start > end;) {
                Order memory order = orders[--start];
                if (order.owner == owner) {
                    orderArray[index++] = _toOrderView(order, start);
                }
            }
        }
    }

    /// @dev List orders
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function list(uint offset, uint count, uint order) external view override returns (OrderView[] memory orderArray) {
        unchecked {
            // Load orders
            Order[] storage orders = _orders;
            // Create result array
            orderArray = new OrderView[](count);
            uint length = orders.length;
            uint i = 0;

            // Reverse order
            if (order == 0) {
                uint index = length - offset;
                uint end = index > count ? index - count : 0;
                while (index > end) {
                    Order memory o = orders[--index];
                    orderArray[i++] = _toOrderView(o, index);
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
                    orderArray[i++] = _toOrderView(orders[index], index);
                    ++index;
                }
            }
        }
    }

    /// @dev Update limitPrice for Order
    /// @param orderIndex Index of Order
    /// @param limitPrice Limit price for trigger buy
    function updateLimitPrice(uint orderIndex, uint limitPrice) external override {
        // Load Order
        Order memory order = _orders[orderIndex];

        // Must owner
        require(order.owner == msg.sender, "NF:not owner");
        // Only for limit request
        require(uint(order.status) == S_LIMIT_REQUEST, "NF:status error");
        
        // Update limitPrice
        _orders[orderIndex].basePrice = CommonLib.encodeFloat40(limitPrice);
    }

    /// @dev Update stopPrice for Order
    /// @param orderIndex Index of target Order
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function updateStopPrice(uint orderIndex, uint stopProfitPrice, uint stopLossPrice) external override {
        // Load Order
        Order memory order = _orders[orderIndex];

        // Must owner
        require(order.owner == msg.sender, "NF:not owner");

        // Update stopPrice
        // When user updateStopPrice, stopProfitPrice and stopLossPrice are not 0 general, so we don't consider 0
        order.stopProfitPrice = CommonLib.encodeFloat40(stopProfitPrice);
        order.stopLossPrice   = CommonLib.encodeFloat40(stopLossPrice  );

        // Update Order
        _orders[orderIndex] = order;
    }

    /// @dev Append buy
    /// @param orderIndex Index of target order
    /// @param amount Amount of paid NEST
    function add(uint orderIndex, uint amount) external payable override {
        // 1. Check arguments
        require(amount < 0x10000000000, "NF:amount invalid");
        require(uint(_orders[orderIndex].status) == S_NORMAL, "NF:status error");
        _orders[orderIndex].appends += uint40(amount);

        // 2. Emit event
        emit Add(orderIndex, amount, msg.sender);

        // 3. Transfer NEST from user
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            address(this), 
            amount * CommonLib.NEST_UNIT
        );
    }

    // Swap USDT to NEST
    function _swapUsdtForNest(uint usdtAmount, uint minNestAmount, address to) internal returns (uint amountOut) {
        // 1. Calculate out nestAmount
        // Confirm token0 address
        (address token0,) = PancakeLibrary.sortTokens(USDT_TOKEN_ADDRESS, NEST_TOKEN_ADDRESS);
        // Get reserves of token0 and token1
        (uint  reserve0, uint  reserve1,) = IPancakePair(NEST_USDT_PAIR_ADDRESS).getReserves();
        // Determine reverseIn and reserveOut based on the token0 address
        (uint reserveIn, uint reserveOut) = USDT_TOKEN_ADDRESS == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        // Calculate out amount
        amountOut = PancakeLibrary.getAmountOut(usdtAmount, reserveIn, reserveOut);
        require(amountOut > minNestAmount, 'NF:INSUFFICIENT_OUTPUT_AMOUNT');

        // 2. Swap with NEST-USDT pair at pancake
        TransferHelper.safeTransferFrom(
            USDT_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_USDT_PAIR_ADDRESS, 
            usdtAmount
        );
        (uint amount0Out, uint amount1Out) = USDT_TOKEN_ADDRESS == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        IPancakePair(NEST_USDT_PAIR_ADDRESS).swap(amount0Out, amount1Out, to, new bytes(0)); 
    }

    // Calculate e^μT
    function _expMiuT(int miuT) internal pure returns (uint) {
        // return _toUInt(ABDKMath64x64.exp(
        //     _toInt128((orientation ? MIU_LONG : MIU_SHORT) * (block.number - baseBlock) * BLOCK_TIME)
        // ));

        // Using approximate algorithm: x*(1+rt)
        // This may be 0, or negative!
        int v = (miuT * 0x10000000000000000) / 1e12 + 0x10000000000000000;
        if (v < 1) return 1;
        return uint(v);
    }

    // Calculate net worth
    function _valueOf(
        Order memory order, 
        uint oraclePrice
    ) internal view returns (uint value, uint fee) {
        value = uint(order.balance) * CommonLib.NEST_UNIT;
        uint lever = uint(order.lever);
        uint base = value * lever * oraclePrice / CommonLib.decodeFloat(uint(order.basePrice));
        uint negative;

        assembly {
            fee := div(mul(base, FEE_RATE), 1000000000000000000)
        }

        uint miu = uint(order.channelIndex) < 2 ? 3.472e3 : 5.787e3;

        // Long
        if (order.orientation) {
            base = base * 1 ether / _impactCostRatio(base);
            negative = value * lever;
            value = value + base * 0x10000000000000000 / _expMiuT(
                int((block.number - uint(order.openBlock)) * CommonLib.BLOCK_TIME / 1000 * miu)
            )  + uint(order.appends) * CommonLib.NEST_UNIT;
        } 
        // Short
        else {
            base = base * _impactCostRatio(base) / 1 ether;
            negative = base * 0x10000000000000000 / _expMiuT(
                -int((block.number - uint(order.openBlock)) * CommonLib.BLOCK_TIME / 1000 * miu)
            ) ;
            value = value * (1 + lever) + uint(order.appends) * CommonLib.NEST_UNIT;
        }

        assembly {
            switch gt(value, negative) 
            case true { value := sub(value, negative) }
            case false { value := 0 }
        }
    }

    // Impact cost, plus one, 18 decimals
    function _impactCostRatio(uint vol) internal pure returns (uint C) {
        // vol is 18 decimals value of NEST, multiply with max lever 50, and suppose St/S0 can be reach 1e10, 
        // it also letter than 1e30, so 5.556e7 * vol, is impossible be overflow
        unchecked { 
            C = 5.556e7 * vol / 1 ether +  1.0004444 ether; 
        }
    }

    // Convert Order to OrderView
    function _toOrderView(Order memory order, uint index) internal pure returns (OrderView memory v) {
        v = OrderView(
            // index
            uint32(index),
            // owner
            order.owner,
            // balance
            order.balance,
            // channelIndex
            order.channelIndex,
            // lever
            order.lever,
            // appends
            order.appends,
            // orientation
            order.orientation,
            // basePrice
            CommonLib.decodeFloat(order.basePrice),
            
            order.openBlock,
            order.status,
            order.fee,
            CommonLib.decodeFloat(order.stopProfitPrice),
            CommonLib.decodeFloat(order.stopLossPrice)
        );
    }
}
