// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";

import "./interfaces/INestVault.sol";
import "./interfaces/INestFutures3.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Nest futures with dynamic miu
contract NestFutures3 is NestFrequentlyUsed, INestFutures3 {

    // TODO: SigmaSQ is no use? √
    // TODO: Add valueOf method √
    // TODO: Add view method to get miu √
    // TODO: Add method to check liquidate information ×
    // TODO: Place orders to global array √
    // TODO: Modify NestFutures2, _queryOracle use price in NestFutures3, and remove useless method in NestFutures2 √
    // TODO: Add new proxy contract for NestFutures3 √
    // TODO: Need make sure each tokenIndex(eth&btc) in NestFutures2 is equals to channelIndex in NestFutures3 √
    // TODO: Add a field at Order to store appended amount, Correct logic of add(), sell(), liquidate, valueOf() √

    // TODO: Will not support order1, need notify users @KT ×
    // TODO: μ is a very important information for user, it should be shown for user @KT √
    // TODO: Ask KT, wll, and lyk to open some orders in NestFutures2 on bsc test net before deploy testing contract √
    // TODO: After this update, limit order and stop order in v2 will not support, buy2, add2, setStopPrice 
    //       in NestFutures2 will be removed, New limit order will not executed. @KT, @wll
    // TODO: Min value of Liquidate line of NestFutures2 is updated from 10nest to 15nest
    // TODO: The order data will cleared when liquidate, notify @wll

    // TASK:
    // 1. Develop new futures contract: NestFutures3 √
    // 2. Develop new futures proxy contract: NestFuturesProxy √
    // 3. Remove buy2, add2, setStopPrice from NestFutures2
    // 4. Update _queryPrice in NestFutures2, to query price from NestFutures3 √

    /// @dev Order structure
    struct Order {
        // Address index of owner
        uint32 owner;
        // Base price of this order, encoded with encodeFloat56()
        uint56 basePrice;
        // Balance of this order, 4 decimals
        uint40 balance;
        // Append amount of this order
        uint40 appends;
        // Index of target channel, support eth, btc and bnb
        uint16 channelIndex;
        // Leverage of this order
        uint8 lever;
        // Orientation of this order, long or short
        bool orientation;
        // Pt, use this to calculate miuT
        int56 Pt;
    }

    // Registered account address mapping
    mapping(address=>uint) _accountMapping;

    // Registered accounts
    address[] _accounts;

    // Global parameters for trade channel
    TradeChannel[] _channels;

    // Array of orders
    Order[] _orders;

    // The prices of (eth, btc and bnb) posted by directPost() method is stored in this field
    // Bits explain: period(16)|height(48)|price3(64)|price2(64)|price1(64)
    uint _lastPrices;
    
    // Address of direct poster
    // TODO:
    //address constant DIRECT_POSTER = 0x06Ca5C8eFf273009C94D963e0AB8A8B9b09082eF;
    //address constant DIRECT_POSTER = 0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681;
    // Direct poster
    address DIRECT_POSTER;
    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        DIRECT_POSTER = INestGovernance(newGovernance).checkAddress("nest.app.directPoster");
    }

    constructor() {
    }
    
    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) public override {
        super.initialize(governance);
        _accounts.push();
    }

    /// @dev Direct post price
    /// @param period Term of validity
    // @param prices Price array, direct price, eth&btc&bnb, eg: 1700e18, 25000e18, 300e18
    // Please note that the price is no longer relative to 2000 USD
    function post(uint period, uint[3] calldata /*prices*/) external {
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

    /// @dev List prices
    /// @param channelIndex index of target channel
    function lastPrice(uint channelIndex) external view override returns (uint period, uint height, uint price) {
        (period, height, price) = _decodePrice(_lastPrices, channelIndex);
    }

    /// @dev Open a new trade channel
    /// @param channelIndex Index of target channel
    function openChannel(uint channelIndex) external onlyGovernance {
        require(channelIndex == _channels.length, "NF:index error");
        _channels.push();
    }

    /// @dev Get channel information
    /// @param channelIndex Index of target channel
    function getChannel(uint channelIndex) external view override returns (TradeChannel memory channel) {
        channel = _channels[channelIndex];
    }

    /// @dev Returns the current value of target order
    /// @param orderIndex Index of order
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    function balanceOf(uint orderIndex, uint oraclePrice) external view returns (uint value) {
        Order memory order = _orders[orderIndex];
        TradeChannel memory channel = _channels[uint(order.channelIndex)];
        
        // 2. Calculate Pt by μ from last order
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

        value = _valueOf(
            // μt = P1 - P0
            int(channel.Pt) - int(order.Pt),
            uint(order.balance) * CommonLib.NEST_UNIT, 
            CommonLib.decodeFloat(uint(order.basePrice)),
            oraclePrice,
            order.orientation,
            uint(order.lever),
            uint(order.appends)
        );
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
        uint ownerIndex = _accountMapping[owner];
        for (uint index = 0; index < count && start > end;) {
            Order memory order = orders[--start];
            if (uint(order.owner) == ownerIndex) {
                orderArray[index++] = _toOrderView(order, start);
            }
        }
    }

    /// @dev List orders
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function list(uint offset, uint count, uint order) external view override returns (OrderView[] memory orderArray) {
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
    ) public payable override {
        // 1. Check arguments
        require(amount > CommonLib.FUTURES_NEST_LB && amount < 0x10000000000, "NF:amount invalid");
        require(lever > CommonLib.LEVER_LB && lever < CommonLib.LEVER_RB, "NF:lever not allowed");

        // 2. Load target channel
        // channelIndex is increase from 0, if channelIndex out of range, means target channel not exist
        TradeChannel memory channel = _channels[channelIndex];

        // When order operating, update Pt first (use last miu), 
        // Then update Sp and Lp (μ can be calculate by Lp and Sp), 
        // Use the last calculated Pt for order
        // 3. Calculate Pt by μ from last order
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

        // 4. Update Lp and Sp, for calculate next μ
        // Lp and Sp are add(sub) with original bond
        // When buy, Lp(Sp) += lever * amount
        // When sell(liquidate), Lp(Sp) -= lever * amount
        // Original bond not include service fee

        // Lp ans Sp are 56-bits unsigned integer, defined as 4 decimals, which representable range is
        // [0, 7205759403792.7935], total supply of NEST is 10000000000, with max leverage 50, the 
        // maximum value is 500000000000, Lp ans Sp is impossible to reach 7205759403792.7935,
        // so we don't check truncation here
        if (orientation) {
            channel.Lp = uint56(Lp + amount * uint(lever));
        }
        else {
            channel.Sp = uint56(Sp + amount * uint(lever));
        }

        // 5. Update parameter for channel
        channel.bn = uint32(block.number);
        _channels[channelIndex] = channel;

        // 6. Emit event
        emit Buy(_orders.length, amount, msg.sender);

        // 7. Create order
        _orders.push(Order(
            // owner
            uint32(_addressIndex(msg.sender)),
            // basePrice
            // Query oraclePrice
            // TODO: Rewrite queryPrice function
            CommonLib.encodeFloat56(_lastPrice(channelIndex)),
            // balance
            uint40(amount),
            // append
            uint40(0),
            // channelIndex
            channelIndex,
            // lever
            lever,
            // orientation
            orientation,
            // Pt
            channel.Pt
        ));

        // 8. Transfer NEST from user
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_VAULT_ADDRESS, 
            amount * CommonLib.NEST_UNIT * (1 ether + CommonLib.FEE_RATE * uint(lever)) / 1 ether
        );
    }

    /// @dev Append buy
    /// @param orderIndex Index of target order
    /// @param amount Amount of paid NEST
    function add(uint orderIndex, uint amount) external payable override {
        // 1. Check arguments
        require(amount < 0x10000000000, "NF:amount invalid");
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

    /// @dev Sell order
    /// @param orderIndex Index of order
    function sell(uint orderIndex) external payable override {
        // 1. Load the order
        Order memory order = _orders[orderIndex];
        uint channelIndex = uint(order.channelIndex);
        TradeChannel memory channel = _channels[channelIndex];
        require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");
        uint basePrice = CommonLib.decodeFloat(uint(order.basePrice));
        uint balance = uint(order.balance);
        uint lever = uint(order.lever);

        // When order operating, update Pt first (use last miu), then update Sp and Lp, 
        // Use the last calculated Pt for order

        // 2. Calculate Pt by μ from last order
        {
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
            
            // 3. Update Lp and Sp, for calculate next μ
            // Lp and Sp are add(sub) with original bond
            // When buy, Lp(Sp) += lever * amount
            // When sell(liquidate), Lp(Sp) -= lever * amount
            // Original bond not include service fee

            // Lp ans Sp are 56-bits unsigned integer, defined as 4 decimals, which representable range is
            // [0, 7205759403792.7935], total supply of NEST is 10000000000, with max leverage 50, the 
            // maximum value is 500000000000, Lp ans Sp is impossible to reach 7205759403792.7935,
            // so we don't check truncation here
            if (order.orientation) {
                channel.Lp = uint56(Lp - balance * lever);
            }
            else {
                channel.Sp = uint56(Sp - balance * lever);
            }
                    
            // 4. Update parameter for channel
            channel.bn = uint32(block.number);
            _channels[channelIndex] = channel;
        }

        // 5. Query oracle price
        uint oraclePrice = _lastPrice(channelIndex);

        // 6. Calculate value of order
        uint value = _valueOf(
            // μt = P1 - P0
            int(channel.Pt) - int(order.Pt),
            // balance
            balance * CommonLib.NEST_UNIT, 
            // basePrice
            basePrice, 
            // oraclePrice
            oraclePrice, 
            // ORIENTATION
            order.orientation, 
            // LEVER
            lever,
            uint(order.appends)
        );

        // 7. Update order
        order.balance = uint40(0);
        order.appends = uint40(0);
        _orders[orderIndex] = order;

        // 8. Transfer NEST to user
        uint fee = balance * CommonLib.NEST_UNIT * lever * oraclePrice / basePrice * CommonLib.FEE_RATE / 1 ether;
        // If value grater than fee, deduct and transfer NEST to owner
        if (value > fee) {
            INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, value - fee);
        }

        // 9. Emit event
        emit Sell(orderIndex, balance, msg.sender, value);
    }

    /// @dev Liquidate order
    /// @param indices Target order indices
    function liquidate(uint[] calldata indices) external payable override {
        uint reward = 0;
        uint oraclePrice = 0;
        uint channelIndex = 0x10000;
        TradeChannel memory channel;
        
        // 1. Loop and liquidate
        for (uint i = indices.length; i > 0;) {
            uint index = indices[--i];
            Order memory order = _orders[index];

            uint lever = uint(order.lever);
            uint balance = uint(order.balance) * CommonLib.NEST_UNIT * lever;
            if (lever > 1 && balance > 0) {
                // If channelIndex is not same with previous, need load new channel and query oracle
                // At first, channelIndex is 0x10000, this is impossible the same with current channelIndex
                if (channelIndex != uint(order.channelIndex)) {
                    // Update previous channel
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

                // 3. Calculate order value
                uint basePrice = CommonLib.decodeFloat(order.basePrice);
                uint value = _valueOf(
                    // μt = P1 - P0
                    int(channel.Pt) - int(order.Pt),
                    // balance
                    balance / lever, 
                    // basePrice
                    basePrice, 
                    // oraclePrice
                    oraclePrice, 
                    // ORIENTATION
                    order.orientation, 
                    // LEVER
                    lever,
                    uint(order.appends)
                );

                // 4. Liquidate logic
                // lever is great than 1, and balance less than a regular value, can be liquidated
                // the regular value is: Max(M0 * L * St / S0 * c, a) | expired
                // the regular value is: Max(M0 * L * St / S0 * c + a, M0 * L * 0.5%)
                if (value < balance / 200 ||
                    value < balance * oraclePrice / basePrice * CommonLib.FEE_RATE / 1 ether
                            + CommonLib.MIN_FUTURE_VALUE
                ) {
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
                        channel.Lp = uint56(uint(channel.Lp) - balance / CommonLib.NEST_UNIT);
                    } else {
                        channel.Sp = uint56(uint(channel.Sp) - balance / CommonLib.NEST_UNIT);
                    }

                    // Clear all data of order, use this code next time
                    assembly {
                        mstore(0, _orders.slot)
                        sstore(add(keccak256(0, 0x20), index), 0)
                    }
                    
                    // // Clear balance
                    // order.balance = uint40(0);
                    // order.appends = uint40(0);
                    // // Update order
                    // _orders[index] = order;

                    // Add reward
                    reward += value;

                    // Emit liquidate event
                    emit Liquidate(index, msg.sender, value);
                }
            }
        }

        // Update last channel
        if (channelIndex < 0x10000) {
            channel.bn = uint32(block.number);
            _channels[channelIndex] = channel;
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
        // TODO: This may be 0, or negative!
        int v = (miuT * 0x10000000000000000) / 1e12 + 0x10000000000000000;
        if (v < 1) return 1;
        return uint(v);
    }

    // Calculate net worth
    function _valueOf(
        int miuT,
        uint balance,
        uint basePrice,
        uint oraclePrice, 
        bool ORIENTATION, 
        uint LEVER,
        uint appends
    ) internal pure returns (uint) {
        uint left;
        uint right;
        uint base = LEVER * balance * oraclePrice / basePrice;
        // Long
        if (ORIENTATION) {
            left = balance + (miuT > 0 ? base * 0x10000000000000000 / _expMiuT(miuT) : base) 
                 + appends * CommonLib.NEST_UNIT;
            right = balance * LEVER;
        } 
        // Short
        else {
            left = balance * (1 + LEVER) + appends * CommonLib.NEST_UNIT;
            right = miuT < 0 ? base * 0x10000000000000000 / _expMiuT(miuT) : base;
        }

        if (left > right) {
            balance = left - right;
        } else {
            balance = 0;
        }

        return balance;
    }

    // Query price
    function _lastPrice(uint channelIndex) internal view returns (uint oraclePrice) {
        // Query price from oracle
        (uint period, uint height, uint price) = _decodePrice(_lastPrices, channelIndex);
        require(block.number < height + period, "NF:price expired");
        oraclePrice = price;
    }

    // Decode composed price
    function _decodePrice(uint rawPrice, uint pairIndex) internal pure returns (uint period, uint height, uint price) {
        return (
            rawPrice >> 240,
            (rawPrice >> 192) & 0xFFFFFFFFFFFF,
            CommonLib.decodeFloat(uint64(rawPrice >> (pairIndex << 6)))
        );
    }

    /// @dev Gets the index number of the specified address. If it does not exist, register
    /// @param addr Destination address
    /// @return The index number of the specified address
    function _addressIndex(address addr) internal returns (uint) {
        uint index = _accountMapping[addr];
        if (index == 0) {
            // If it exceeds the maximum number that 32 bits can store, you can't continue to register a new account.
            // If you need to support a new account, you need to update the contract
            require((_accountMapping[addr] = index = _accounts.length) < 0x100000000, "NO:!accounts");
            _accounts.push(addr);
        }

        return index;
    }
    
    // Convert Order to OrderView
    function _toOrderView(Order memory order, uint index) internal view returns (OrderView memory v) {
        v = OrderView(
            // index
            uint32(index),
            // owner
            _accounts[uint(order.owner)],
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
            // Pt
            order.Pt
        );
    }
}
