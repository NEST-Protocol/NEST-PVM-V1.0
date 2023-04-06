// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";
import "./libs/PancakeLibrary.sol";

import "./interfaces/INestVault.sol";
import "./interfaces/INestFutures4.sol";
import "./interfaces/IPancakePair.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Nest futures with dynamic miu
contract NestFutures4V3 is NestFrequentlyUsed, INestFutures4 {

    // Number of channels
    uint constant CHANNEL_COUNT = 3;

    // Service fee for buy, sell, add and liquidate
    uint constant FEE_RATE = 0.0005 ether;
    
    // Status of order
    uint constant S_CLEARED         = 0x00;
    uint constant S_BUY_REQUEST     = 0x01;
    uint constant S_NORMAL          = 0x02;
    uint constant S_SELL_REQUEST    = 0x03;
    uint constant S_LIMIT_REQUEST   = 0x04;
    uint constant S_CANCELED        = 0xFF;

    // Array of orders
    Order[] _orders;

    // TODO:
    // Address of direct poster
    // address constant DIRECT_POSTER = 0x06Ca5C8eFf273009C94D963e0AB8A8B9b09082eF;  // bsc_main
    // address constant DIRECT_POSTER = 0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681;  // bsc_test
    // address constant USDT_TOKEN_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;
    // address constant NEST_USDT_PAIR_ADDRESS = 0x04fF0eA8a05F1c75557981e9303568F043B88b4C;
    address DIRECT_POSTER;
    address NEST_USDT_PAIR_ADDRESS;
    address USDT_TOKEN_ADDRESS;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        DIRECT_POSTER = INestGovernance(newGovernance).checkAddress("nest.app.directPoster");
        NEST_USDT_PAIR_ADDRESS = INestGovernance(newGovernance).checkAddress("pancake.pair.nestusdt");
        USDT_TOKEN_ADDRESS = INestGovernance(newGovernance).checkAddress("common.token.usdt");
    }

    constructor() {
    }

    /// @dev Direct post price and execute
    // @param period Term of validity
    /// @param prices Price array, direct price, eth&btc&bnb, eg: 1700e18, 25000e18, 300e18
    /// Please note that the price is no longer relative to 2000 USD
    /// @param buyOrderIndices Indices of order to buy
    /// @param sellOrderIndices Indices of order to sell
    /// @param limitOrderIndices Indices of order to sell
    /// @param stopOrderIndices Indices of order to stop
    /// @param liquidateOrderIndices Indices of order to liquidate
    function execute(
        uint[CHANNEL_COUNT] calldata prices, 
        uint[] calldata buyOrderIndices, 
        uint[] calldata sellOrderIndices,
        uint[] calldata limitOrderIndices,
        uint[] calldata stopOrderIndices,
        uint[] calldata liquidateOrderIndices
    ) external {
        require(msg.sender == DIRECT_POSTER, "NF:not directPoster");

        // Execute buy orders
        _executeBuy(buyOrderIndices, prices);

        // Execute sell orders
        _executeSell(sellOrderIndices, prices);

        // Execute limit orders
        _executeLimit(limitOrderIndices, prices);

        // Execute stop orders
        _executeStop(stopOrderIndices, prices);

        // Liquidate
        _liquidate(liquidateOrderIndices, prices);
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

    /// @dev Create buy futures request
    /// @param channelIndex Index of target channel
    /// @param lever Lever of order
    /// @param orientation true: long, false: short
    /// @param amount Amount of paid NEST, 4 decimals
    /// @param basePrice Target price of this order, if limit is true, means limit price, or means open price
    /// @param limit True means this is a limit order
    /// @param stopProfitPrice If not 0, means this is a stop order
    /// @param stopLossPrice If not 0, means this is a stop order
    function newBuyRequest(
        uint channelIndex, 
        uint lever, 
        bool orientation, 
        uint amount,
        uint basePrice,
        bool limit,
        uint stopProfitPrice,
        uint stopLossPrice
    ) external payable override {
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_VAULT_ADDRESS, 
            (
                amount + 
                // Create buy request, returns fee(in 4 decimals)
                _buyRequest(channelIndex, lever, orientation, amount, basePrice, limit, stopProfitPrice, stopLossPrice)
            ) * CommonLib.NEST_UNIT + (limit ? CommonLib.EXECUTE_FEE_NEST : 0)
        );
    }

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
    ) external payable override {
        // 1. Swap with NEST-USDT pair at pancake
        uint nestAmount = _swapUsdtForNest(usdtAmount, minNestAmount, NEST_VAULT_ADDRESS);

        // 2. Create buy order
        _buyRequest(
            channelIndex, 
            lever, 
            orientation, 
            // Calculate amount of order
            (nestAmount - (limit ? CommonLib.EXECUTE_FEE_NEST : 0)) 
                * 1 ether / (1 ether + FEE_RATE * lever) / CommonLib.NEST_UNIT, 
            basePrice, 
            limit, 
            stopProfitPrice, 
            stopLossPrice
        );
    }

    /// @dev Cancel buy request
    /// @param orderIndex Index of target order
    function cancelBuyRequest(uint orderIndex) external override {
        // Load Order
        Order memory order = _orders[orderIndex];
        uint status = uint(order.status);

        // Must owner
        require(order.owner == msg.sender, "NF:not owner");
        // Only for buy request or limit request
        require(status == S_BUY_REQUEST || status == S_LIMIT_REQUEST, "NF:status error");

        // Return NEST to owner
        INestVault(NEST_VAULT_ADDRESS).transferTo(
            msg.sender, 
            (
                // balance
                uint(order.balance) + 
                // fee
                uint(order.fee) + 
                // execute fee
                (status == S_LIMIT_REQUEST ? CommonLib.EXECUTE_FEE : 0)
            ) * CommonLib.NEST_UNIT
        );

        // Update Order
        order.balance = uint40(0);
        order.fee = uint40(0);
        order.status = uint8(S_CANCELED);
        _orders[orderIndex] = order;
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
            NEST_VAULT_ADDRESS, 
            amount * CommonLib.NEST_UNIT
        );
    }

    /// @dev Create sell futures request
    /// @param orderIndex Index of order
    function newSellRequest(uint orderIndex) external payable override {
        // Load Order
        Order memory order = _orders[orderIndex];

        // Must owner
        require(order.owner == msg.sender, "NF:not owner");

        // Only for normal order
        require(uint(order.status) == S_NORMAL, "NF:status error");

        // Update Order
        order.status = uint8(S_SELL_REQUEST);
        _orders[orderIndex] = order;

        //emit SellRequest(orderIndex, uint(order.balance), msg.sender);
    }

    /// @dev Buy futures request
    /// @param channelIndex Index of target channel
    /// @param lever Lever of order
    /// @param orientation true: long, false: short
    /// @param amount Amount of paid NEST, 4 decimals
    /// @param fee Fee of this order, 4 decimals
    /// @param basePrice Base price of this order
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function _buyRequest(
        uint channelIndex, 
        uint lever, 
        bool orientation, 
        uint amount,
        uint basePrice,
        bool limit,
        uint stopProfitPrice,
        uint stopLossPrice
    ) internal returns (uint fee) {
        // 1. Check arguments
        require(amount > CommonLib.FUTURES_NEST_LB && amount < 0x10000000000, "NF:amount invalid");
        require(lever > CommonLib.LEVER_LB && lever < CommonLib.LEVER_RB, "NF:lever not allowed");
        require(basePrice > 0, "NF:basePrice invalid");
        require(channelIndex < CHANNEL_COUNT, "NF:channel invalid");
        
        // 2. Emit event
        emit BuyRequest(_orders.length, amount, msg.sender);

        // 3. Create order
        fee = amount * lever * FEE_RATE / 1 ether;
        _orders.push(Order(
            // owner
            msg.sender,
            // status
            limit ? uint8(S_LIMIT_REQUEST) : uint8(S_BUY_REQUEST),
            // channelIndex
            uint8(channelIndex),
            // lever
            uint8(lever),
            // openBlock
            uint32(block.number),
            // basePrice
            // Query oraclePrice
            CommonLib.encodeFloat40(basePrice),

            // balance
            uint40(amount),
            // appends
            uint40(0),
            // fee
            uint40(fee),

            // orientation
            orientation,

            stopProfitPrice > 0 ? CommonLib.encodeFloat40(stopProfitPrice) : uint40(0),
            stopLossPrice > 0 ? CommonLib.encodeFloat40(stopLossPrice) : uint40(0)
        ));
    }

    // Execute buy orders
    function _executeBuy(uint[] calldata orderIndices, uint[CHANNEL_COUNT] calldata oraclePrices) internal {
        // Last price of current channel
        uint oraclePrice = 0;
        // Index of current channel
        uint channelIndex = 0x10000;

        uint orderIndex = 0;
        uint i = orderIndices.length << 5;
        while (i > 0) {
            assembly {
                i := sub(i, 0x20)
                orderIndex := calldataload(add(orderIndices.offset, i))
            }

            // Load Order
            Order memory order = _orders[orderIndex];
            if (uint(order.status) == S_BUY_REQUEST) {
                // If channelIndex is not same with previous, need load new channel and query oracle
                // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                if (channelIndex != uint(order.channelIndex)) {
                    // Load current channel
                    channelIndex = uint(order.channelIndex);
                    oraclePrice = oraclePrices[channelIndex];
                    //oraclePrice = CommonLib.decodeFloat(CommonLib.encodeFloat40(oraclePrices[channelIndex]));
                }
                uint basePrice = CommonLib.decodeFloat(uint(order.basePrice));
                uint balance = uint(order.balance);

                if (order.orientation ? basePrice < oraclePrice : basePrice > oraclePrice) {
                    emit Revert(orderIndex, balance, order.owner);

                    INestVault(NEST_VAULT_ADDRESS).transferTo(
                        order.owner, 
                        (balance + uint(order.fee)) * CommonLib.NEST_UNIT
                    );

                    order.status = uint8(S_CANCELED);
                } else {
                    emit Buy(orderIndex, balance, order.owner);

                    uint impactCostRatio = _impactCostRatio(balance * uint(order.lever) * CommonLib.NEST_UNIT);
                    order.basePrice = CommonLib.encodeFloat40(
                        order.orientation 
                            ? oraclePrice * impactCostRatio / 1 ether
                            : oraclePrice * 1 ether / impactCostRatio
                    );
                    order.status = uint8(S_NORMAL);
                }

                _orders[orderIndex] = order;
            }
        }
    }
    
    // Execute sell orders
    function _executeSell(uint[] calldata orderIndices, uint[CHANNEL_COUNT] calldata oraclePrices) internal {
        // Last price of current channel
        uint oraclePrice = 0;
        // Index of current channel
        uint channelIndex = 0x10000;

        uint orderIndex = 0;
        uint i = orderIndices.length << 5;
        while (i > 0) {
            assembly {
                i := sub(i, 0x20)
                orderIndex := calldataload(add(orderIndices.offset, i))
            }

            // 1. Load Order
            Order memory order = _orders[orderIndex];
            if (uint(order.status) == S_SELL_REQUEST) {
                // 3. Update channel
                if (channelIndex != uint(order.channelIndex)) {
                    // If channelIndex is not same with previous, need load new channel and query oracle
                    // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                    // Load current channel
                    channelIndex = uint(order.channelIndex);
                    oraclePrice = oraclePrices[channelIndex];
                }

                // 4. Calculate value and update Order
                (uint value, uint fee) = _valueOf(order, oraclePrice);
                emit Sell(orderIndex, uint(order.balance), order.owner, value);

                //emit Sell(orderIndex, uint(order.balance), msg.sender, value);
                order.balance = uint40(0);
                order.appends = uint40(0);
                order.status = uint8(S_CLEARED);
                _orders[orderIndex] = order;

                // 5. Transfer NEST to user
                // If value grater than fee, deduct and transfer NEST to owner
                if (value > fee) {
                    INestVault(NEST_VAULT_ADDRESS).transferTo(order.owner, value - fee);
                }
            }
        }
    }

    /// @dev Execute limit order, only maintains account
    /// @param orderIndices Array of TrustOrder index
    function _executeLimit(uint[] calldata orderIndices, uint[CHANNEL_COUNT] calldata oraclePrices) internal {
        uint oraclePrice = 0;
        uint channelIndex = 0x10000;

        // 1. Loop and execute
        uint orderIndex = 0;
        uint i = orderIndices.length << 5;
        while (i > 0) { 
            assembly {
                i := sub(i, 0x20)
                orderIndex := calldataload(add(orderIndices.offset, i))
            }

            Order memory order = _orders[orderIndex];
            if (uint(order.status) == S_LIMIT_REQUEST) {
                if (channelIndex != uint(order.channelIndex)) {
                    // If channelIndex is not same with previous, need load new channel and query oracle
                    // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                    // Load current channel
                    channelIndex = uint(order.channelIndex);
                    oraclePrice = oraclePrices[channelIndex];
                }

                if (
                    order.orientation 
                    ? oraclePrice <= CommonLib.decodeFloat(uint(order.basePrice))
                    : oraclePrice >= CommonLib.decodeFloat(uint(order.basePrice))
                ) {
                    uint balance = uint(order.balance);
                    emit Buy(orderIndex, balance, order.owner);

                    // Update Order: basePrice, baseBlock, balance, Pt
                    order.basePrice = CommonLib.encodeFloat40(
                        order.orientation
                        ? oraclePrice * _impactCostRatio(balance * uint(order.lever) * CommonLib.NEST_UNIT) / 1 ether
                        : oraclePrice * 1 ether / _impactCostRatio(balance * uint(order.lever) * CommonLib.NEST_UNIT)
                    );
                    order.openBlock = uint32(block.number);
                    order.status = uint8(S_NORMAL);

                    // Update Order
                    _orders[orderIndex] = order;
                }
            }
        }
    }

    /// @dev Execute limit order, only maintains account
    /// @param orderIndices Array of TrustOrder index
    function _executeStop(uint[] calldata orderIndices, uint[CHANNEL_COUNT] calldata oraclePrices) internal {
        //uint executeFee = 0;
        uint oraclePrice = 0;
        uint channelIndex = 0x10000;

        // 1. Loop and execute
        uint orderIndex = 0;
        uint i = orderIndices.length << 5;
        while (i > 0) {
            assembly {
                i := sub(i, 0x20)
                orderIndex := calldataload(add(orderIndices.offset, i))
            }
            
            // 1. Load Order
            Order memory order = _orders[orderIndex];
            require(uint(order.status) == S_NORMAL, "NF:status error");
            uint balance = uint(order.balance);

            if (balance > 0) {
                if (channelIndex != uint(order.channelIndex)) {
                    // If channelIndex is not same with previous, need load new channel and query oracle
                    // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                    // Load current channel
                    channelIndex = uint(order.channelIndex);
                    oraclePrice = oraclePrices[channelIndex];
                }

                uint stopProfitPrice = CommonLib.decodeFloat(uint(order.stopProfitPrice));
                uint stopLossPrice   = CommonLib.decodeFloat(uint(order.stopLossPrice  ));
                if (
                    (stopProfitPrice == 0 && stopLossPrice == 0) || 
                    (
                        order.orientation
                            ? (oraclePrice < stopProfitPrice && oraclePrice > stopLossPrice)
                            : (oraclePrice > stopProfitPrice && oraclePrice < stopLossPrice)
                    )
                ) {
                    continue;
                }

                (uint value, uint fee) = _valueOf(order, oraclePrice);
                emit Sell(orderIndex, balance, order.owner, value);

                order.balance = uint40(0);
                order.appends = uint40(0);
                order.status = uint8(S_CLEARED);
                _orders[orderIndex] = order;

                // Newest value of order is greater than fee + EXECUTE_FEE, deduct and transfer NEST to owner
                if (value > fee + CommonLib.EXECUTE_FEE_NEST) {
                    INestVault(NEST_VAULT_ADDRESS).transferTo(order.owner, value - fee - CommonLib.EXECUTE_FEE_NEST);
                }
            }
        }
    }

    /// @dev Liquidate order
    /// @param orderIndices Target order indices
    function _liquidate(uint[] calldata orderIndices, uint[CHANNEL_COUNT] calldata oraclePrices) internal {
        // 0. Global variables
        // Total reward of this transaction
        uint reward = 0;
        // Last price of current channel
        uint oraclePrice = 0;
        // Index of current channel
        uint channelIndex = 0x10000;
        
        // 1. Loop and liquidate
        // Index of Order
        uint orderIndex = 0;
        uint i = orderIndices.length << 5;
        while (i > 0) {
            // 2. Load Order
            // uint orderIndex = indices[--i];
            assembly {
                i := sub(i, 0x20)
                orderIndex := calldataload(add(orderIndices.offset, i))
            }

            Order memory order = _orders[orderIndex];
            uint lever = uint(order.lever);
            uint balance = uint(order.balance) * CommonLib.NEST_UNIT * lever;
            if (lever > 1 && balance > 0 && uint(order.status) == S_NORMAL) {
                // 3. Load and update channel
                // If channelIndex is not same with previous, need load new channel and query oracle
                // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                if (channelIndex != uint(order.channelIndex)) {
                    // Load current channel
                    channelIndex = uint(order.channelIndex);
                    oraclePrice = oraclePrices[channelIndex];
                }

                // 4. Calculate order value
                (uint value, uint fee) = _valueOf(order, oraclePrice);

                // 5. Liquidate logic
                // lever is great than 1, and balance less than a regular value, can be liquidated
                // the regular value is: Max(M0 * L * St / S0 * c, a) | expired
                // the regular value is: Max(M0 * L * St / S0 * c + a, M0 * L * 0.5%) | expired
                // the regular value is: Max(M0 * L * St / S0 * c + a, M0 * L * 1%)
                unchecked {
                    if (value < balance / 100 || value < fee + CommonLib.MIN_FUTURE_VALUE) {
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
                    }
                }
            }
        }

        // 6. Transfer NEST to user
        if (reward > 0) {
            INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, reward);
        }
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

        // Long
        if (order.orientation) {
            base = base * 1 ether / _impactCostRatio(base);
            negative = value * lever;
            value = value + base * 0x10000000000000000 / _expMiuT(
                int((block.number - uint(order.openBlock)) * CommonLib.BLOCK_TIME / 1000 * 3.472e3)
            )  + uint(order.appends) * CommonLib.NEST_UNIT;
        } 
        // Short
        else {
            base = base * _impactCostRatio(base) / 1 ether;
            negative = base * 0x10000000000000000 / _expMiuT(
                -int((block.number - uint(order.openBlock)) * CommonLib.BLOCK_TIME / 1000 * 3.472e3)
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
        C = 5.556e7 * vol / 1 ether +  1.0004444 ether;
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
