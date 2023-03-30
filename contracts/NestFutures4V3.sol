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

    uint constant CHANNEL_COUNT = 3;
    // Service fee for buy, sell, add and liquidate
    uint constant FEE_RATE = 0.0005 ether;
    uint constant SLIDING_POINT = 0.0002 ether;
    
    uint constant S_CLEARED = 0x00;
    uint constant S_BUY_REQUEST = 0x01;
    uint constant S_NORMAL = 0x02;
    uint constant S_SELL_REQUEST = 0x03;
    uint constant S_LIMIT_REQUEST = 0x04;
    uint constant S_CANCELED = 0xFF;

    // Registered account address mapping
    mapping(address=>uint) _accountMapping;

    // Registered accounts
    address[] _accounts;

    // Array of orders
    Order[] _orders;

    // The prices of (eth, btc and bnb) posted by directPost() method is stored in this field
    // Bits explain: period(16)|height(48)|price3(64)|price2(64)|price1(64)
    uint _lastPrices;
    
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

    /// @dev Direct post price
    /// @param period Term of validity
    /// @param prices Price array, direct price, eth&btc&bnb, eg: 1700e18, 25000e18, 300e18
    /// Please note that the price is no longer relative to 2000 USD
    function post(
        uint period, 
        uint[CHANNEL_COUNT] calldata prices
    ) public {
        require(msg.sender == DIRECT_POSTER, "NF:not directPoster");
        assembly {
            // Encode value at position indicated by value to float
            function encode(value) -> v {
                v := 0
                // Load value from calldata
                // Encode logic
                for { value := calldataload(value) } gt(value, 0x3FFFFFFFFFFFFFF) { value := shr(4, value) } {
                    v := add(v, 1)
                }
                v := or(v, shl(6, value))
            }

            period := 
            or(
                or(
                    or(
                        or(
                            // period
                            shl(240, period), 
                            // block.number
                            shl(192, number())
                        ), 
                        // equivalents[2]
                        shl(128, encode(0x64))
                    ), 
                    // equivalents[1]
                    shl(64, encode(0x44))
                ), 
                // equivalents[0]
                encode(0x24)
            )
        }
        _lastPrices = period;
    }

    /// @dev Direct post price and execute
    /// @param period Term of validity
    /// @param prices Price array, direct price, eth&btc&bnb, eg: 1700e18, 25000e18, 300e18
    /// Please note that the price is no longer relative to 2000 USD
    /// @param buyOrderIndices Indices of order to buy
    /// @param sellOrderIndices Indices of order to sell
    /// @param limitOrderIndices Indices of order to sell
    /// @param stopOrderIndices Indices of order to stop
    /// @param liquidateOrderIndices Indices of order to liquidate
    function execute(
        uint period, 
        uint[CHANNEL_COUNT] calldata prices, 
        uint[] calldata buyOrderIndices, 
        uint[] calldata sellOrderIndices,
        uint[] calldata limitOrderIndices,
        uint[] calldata stopOrderIndices,
        uint[] calldata liquidateOrderIndices
    ) external {
        // TODO: Check price
        post(period, prices);

        _executeBuy(buyOrderIndices, prices);
        _executeSell(sellOrderIndices, prices);
        _executeLimit(limitOrderIndices, prices);
        _executeStop(stopOrderIndices, prices);
        _liquidate(liquidateOrderIndices, prices);
    }

    /// @dev List prices
    /// @param channelIndex index of target channel
    function lastPrice(uint channelIndex) public view override returns (uint period, uint height, uint price) {
        // Bits explain: period(16)|height(48)|price3(64)|price2(64)|price1(64)
        uint rawPrice =_lastPrices;
        return (
            rawPrice >> 240,
            (rawPrice >> 192) & 0xFFFFFFFFFFFF,
            CommonLib.decodeFloat((rawPrice >> (channelIndex << 6)) & 0xFFFFFFFFFFFFFFFF)
        );
    }

    /// @dev Returns the current value of target order
    /// @param orderIndex Index of order
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    function balanceOf(uint orderIndex, uint oraclePrice) external view override returns (uint value) {
        Order memory order = _orders[orderIndex];
        (value,) = _valueOf(order, oraclePrice);
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
    ) external payable override {
        // Transfer NEST from user
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_VAULT_ADDRESS, 
            (
                amount + 
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
    ) external {
        // 1. Swap with NEST-USDT pair at pancake
        uint nestAmount = _swapUsdtForNest(usdtAmount, minNestAmount, NEST_VAULT_ADDRESS);

        // 2. Create buy order
        _buyRequest(
            channelIndex, 
            lever, 
            orientation, 
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
    function cancelBuyRequest(uint orderIndex) external {
        Order memory order = _orders[orderIndex];
        uint status = uint(order.status);
        require(order.owner == msg.sender, "NF:not owner");
        require(status == S_BUY_REQUEST || status == S_LIMIT_REQUEST, "NF:status error");
        INestVault(NEST_VAULT_ADDRESS).transferTo(
            msg.sender, 
            (
                uint(order.balance) + 
                uint(order.fee) + 
                (status == S_LIMIT_REQUEST ? CommonLib.EXECUTE_FEE : 0)
            ) * CommonLib.NEST_UNIT
        );

        order.balance = uint40(0);
        order.fee = uint40(0);
        order.status = uint8(S_CANCELED);
        _orders[orderIndex] = order;
    }

    /// @dev Update limitPrice for Order
    /// @param orderIndex Index of Order
    /// @param limitPrice Limit price for trigger buy
    function updateLimitPrice(uint orderIndex, uint limitPrice) external {
        Order memory order = _orders[orderIndex];
        require(uint(order.status) == S_LIMIT_REQUEST, "NF:status error");
        
        // Check owner
        require(order.owner == msg.sender, "NF:not owner");
        
        // Update limitPrice
        _orders[orderIndex].basePrice = CommonLib.encodeFloat56(limitPrice);
    }

    /// @dev Update stopPrice for Order
    /// @param orderIndex Index of target Order
    /// @param stopProfitPrice If not 0, will open a stop order
    /// @param stopLossPrice If not 0, will open a stop order
    function updateStopPrice(uint orderIndex, uint stopProfitPrice, uint stopLossPrice) external {
        // Load Order
        Order memory order = _orders[orderIndex];

        // Check owner
        require(msg.sender == order.owner, "NF:not owner");

        // Update stopPrice
        // When user updateStopPrice, stopProfitPrice and stopLossPrice are not 0 general, so we don't consider 0
        order.stopProfitPrice = CommonLib.encodeFloat56(stopProfitPrice);
        order.stopLossPrice   = CommonLib.encodeFloat56(stopLossPrice  );

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
        // 1. Load the order
        Order memory order = _orders[orderIndex];
        require(msg.sender == order.owner, "NF:not owner");
        require(uint(order.status) == S_NORMAL, "NF:status error");
        order.status = uint8(S_SELL_REQUEST);
        _orders[orderIndex] = order;

        emit SellRequest(orderIndex, uint(order.balance), msg.sender);
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
        uint index = 0;
        uint i = orderIndices.length << 5;
        while (i > 0) {
            // 2. Load Order
            // uint index = indices[--i];
            assembly {
                i := sub(i, 0x20)
                index := calldataload(add(orderIndices.offset, i))
            }

            Order memory order = _orders[index];
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
                            //mstore(0, _orders.slot)
                            //sstore(add(keccak256(0, 0x20), shl(1, index)), 0)
                            //sstore(add(keccak256(0, 0x20), add(1, shl(1, index))), 0)

                            // Each Order take 2 slots
                            mstore(0, _orders.slot)
                            let offset := add(keccak256(0, 0x20), shl(1, index))
                            sstore(offset, 0)
                            sstore(add(offset, 1), 0)
                        }
                        
                        // Add reward
                        reward += value;

                        // Emit liquidate event
                        emit Liquidate(index, msg.sender, value);
                    }
                }
            }
        }

        // 6. Transfer NEST to user
        if (reward > 0) {
            INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, reward);
        }
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

        // 2. Emit event
        emit BuyRequest(_orders.length, amount, msg.sender);

        // 3. Create order
        fee = amount * lever * FEE_RATE / 1 ether;
        _orders.push(Order(
            // owner
            msg.sender,
            // basePrice
            // Query oraclePrice
            CommonLib.encodeFloat56(basePrice),
            // balance
            uint40(amount),
            // append
            uint40(0),
            // channelIndex
            uint8(channelIndex),
            // lever
            uint8(lever),
            // orientation
            orientation,

            uint32(block.number),
            limit ? uint8(S_LIMIT_REQUEST) : uint8(S_BUY_REQUEST),

            uint40(fee),
            stopProfitPrice > 0 ? CommonLib.encodeFloat56(stopProfitPrice) : uint56(0),
            stopLossPrice > 0 ? CommonLib.encodeFloat56(stopLossPrice) : uint56(0)
        ));
    }

    // Execute buy orders
    function _executeBuy(uint[] calldata orderIndices, uint[CHANNEL_COUNT] calldata oraclePrices) internal {
        for (uint i = orderIndices.length; i > 0;) {
            uint orderIndex = orderIndices[--i];
            Order memory order = _orders[orderIndex];
            if (uint(order.status) == S_BUY_REQUEST) {
                // TODO: Optimize code
                uint oraclePrice = CommonLib.decodeFloat(CommonLib.encodeFloat56(oraclePrices[uint(order.channelIndex)]));
                uint basePrice = CommonLib.decodeFloat(uint(order.basePrice));
                if (order.orientation) {
                    if (basePrice >= oraclePrice/*&& basePrice <= oraclePrice * (1 ether + SLIDING_POINT) / 1 ether*/) {
                        order.basePrice = CommonLib.encodeFloat56(
                            basePrice * _impactCostRatio(
                                uint(order.balance) * 
                                uint(order.lever) * 
                                CommonLib.NEST_UNIT) / 1 ether
                        );
                        order.status = uint8(S_NORMAL);
                        // TODO: openBlock
                        //order.openBlock = uint32(block.number);
                    } else {
                        order.status = uint8(S_CANCELED);
                        // TODO: Store fee to order
                        uint fee = uint(order.balance) * uint(order.lever) * FEE_RATE / 1 ether;
                        INestVault(NEST_VAULT_ADDRESS).transferTo(
                            order.owner, 
                            (uint(order.balance) + fee) * CommonLib.NEST_UNIT
                        );
                    }
                } else {
                    if (basePrice <= oraclePrice/*&& basePrice >= oraclePrice * (1 ether - SLIDING_POINT) / 1 ether*/) {
                        order.basePrice = CommonLib.encodeFloat56(
                            basePrice *  1 ether / _impactCostRatio(
                                uint(order.balance) * 
                                uint(order.lever) * 
                                CommonLib.NEST_UNIT)
                        );
                        order.status = uint8(S_NORMAL);
                        // TODO: openBlock
                        //order.openBlock = uint32(block.number);
                    } else {
                        order.status = uint8(S_CANCELED);
                        // TODO: Store fee to order
                        uint fee = uint(order.balance) * uint(order.lever) * FEE_RATE / 1 ether;
                        INestVault(NEST_VAULT_ADDRESS).transferTo(
                            order.owner, 
                            (uint(order.balance) + fee) * CommonLib.NEST_UNIT
                        );
                    }
                }
            }
            _orders[orderIndex] = order;
        }
    }
    
    // Execute sell orders
    function _executeSell(uint[] calldata orderIndices, uint[CHANNEL_COUNT] calldata oraclePrices) internal {
        for (uint i = orderIndices.length; i > 0;) {
            uint orderIndex = orderIndices[--i];
            // 1. Load the order
            Order memory order = _orders[orderIndex];
            if (uint(order.status) == S_SELL_REQUEST) {
                //require(msg.sender == order.owner, "NF:not owner");
                //require(uint(order.status) == S_NORMAL, "NF:status error");

                // 2. Query price
                uint channelIndex = uint(order.channelIndex);
                uint oraclePrice = oraclePrices[channelIndex];

                // 3. Update channel

                // 4. Calculate value and update Order
                (uint value, uint fee) = _valueOf(order, oraclePrice);
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
        //uint totalNest = 0;
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

                uint balance = uint(order.balance);
                //totalNest += (balance + uint(order.fee));

                // TODO: Use oraclePrice or basePrice?
                // Update Order: basePrice, baseBlock, balance, Pt
                order.basePrice = CommonLib.encodeFloat56(
                    order.orientation
                    ? oraclePrice * _impactCostRatio(balance * uint(order.lever) * CommonLib.NEST_UNIT) / 1 ether
                    : oraclePrice * 1 ether / _impactCostRatio(balance * uint(order.lever) * CommonLib.NEST_UNIT)
                );
                order.balance = uint40(balance);
                order.openBlock = uint32(block.number);
                order.status = uint8(S_NORMAL);

                // Update Order
                _orders[orderIndex] = order;
            }
        }

        // Transfer NEST to NestVault
        //TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, NEST_VAULT_ADDRESS, totalNest * CommonLib.NEST_UNIT);
    }

    /// @dev Execute limit order, only maintains account
    /// @param orderIndices Array of TrustOrder index
    function _executeStop(uint[] calldata orderIndices, uint[CHANNEL_COUNT] calldata oraclePrices) internal {
        //uint executeFee = 0;
        uint oraclePrice = 0;
        uint channelIndex = 0x10000;

        // 1. Loop and execute
        for (uint i = orderIndices.length; i > 0;) {
            uint orderIndex = orderIndices[--i];
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

                (uint value, uint fee) = _valueOf(order, oraclePrice);

                order.balance = uint40(0);
                order.appends = uint40(0);
                order.status = uint8(S_CLEARED);
                _orders[orderIndex] = order;

                // Newest value of order is greater than fee + EXECUTE_FEE, deduct and transfer NEST to owner
                if (value > fee + CommonLib.EXECUTE_FEE_NEST) {
                    INestVault(NEST_VAULT_ADDRESS).transferTo(order.owner, value - fee - CommonLib.EXECUTE_FEE_NEST);
                }
                //executeFee += CommonLib.EXECUTE_FEE_NEST;

                //emit Sell(orderIndex, balance, order.owner, value);
            }
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
