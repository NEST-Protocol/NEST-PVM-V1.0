// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";

import "./interfaces/INestVault.sol";
import "./interfaces/INestFutures3.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Nest futures with dynamic miu
contract NestFutures3 is NestFrequentlyUsed, INestFutures3 {

    int constant MIU_DECIMALS = 1e12;
    int constant MIU_LAMBDA = 0.02e12;

    // TODO: SigmaSQ is no use?
    // TODO: Add balanceOf method
    // TODO: Add view method to get miu
    // TODO: Add method to check liquidate information
    // TODO: Place orders to global array √
    // TODO: Modify NestFutures2, _queryOracle use price in NestFutures3, and remove useless method in NestFutures2
    // TODO: Add new proxy contract for NestFutures3
    // TODO: Need make sure each tokenIndex(eth&btc) in NestFutures2 is equals to channelIndex in NestFutures3

    // TODO: Will not support order1, need notify users @KT
    // TODO: μ is a very important information for user, it should be shown for user @KT
    // TODO: Ask KT, wll, and lyk to open some orders in NestFutures2 on bsc test net before deploy testing contract
    // TODO: After this update, limit order and stop order in v2 will not support, buy2, add2, setStopPrice 
    //       in NestFutures2 will be removed, New limit order will not executed. @KT, @wll
    // TODO: Min value of Liquidate line of NestFutures2 is updated from 10nest to 15nest

    // TASK:
    // 1. Develop new futures contract: NestFutures3
    // 2. Develop new futures proxy contract: NestFuturesProxy
    // 3. Remove buy2, add2, setStopPrice from NestFutures2
    // 4. Update _queryPrice in NestFutures2, to query price from 

    /// @dev Order structure
    struct Order {
        // Address index of owner
        uint32 owner;
        // Base price of this order, encoded with encodeFloat56()
        uint56 basePrice;
        // Balance of this order, 4 decimals
        uint48 balance;
        // TODO: Not used
        // Open block of this order
        uint32 baseBlock;
        // TODO: Remove?
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
    // @param equivalents Price array, one to one with pairs
    function directPost(uint period, uint[3] calldata /*equivalents*/) external {
        // TODO: Restore this code
        //require(msg.sender == DIRECT_POSTER, "NF:not directPoster");

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
    function valueOf(uint orderIndex, uint oraclePrice) external view returns (uint value) {
        Order memory order = _orders[orderIndex];
        TradeChannel memory channel = _channels[uint(order.channelIndex)];
        
        // 2. Calculate Pt by μ from last order
        uint Lp = uint(channel.Lp);
        uint Sp = uint(channel.Sp);
        if (Lp + Sp > 0) {
            // μ is not saved, and calculate it by Lp and Sp always
            // TODO: Confirm unit of miu
            int miu = (int(Lp) - int(Sp)) * MIU_LAMBDA / 86400 / int(Lp + Sp);
            // TODO: Check truncation
            channel.Pt = int56(
                int(channel.Pt) + 
                miu * int((block.number - uint(channel.bn)) * CommonLib.BLOCK_TIME / 1000)
            );
        }

        // μt = P1 - P0
        int miuT = int(channel.Pt) - int(order.Pt);

        value = _valueOf(
            miuT,
            uint(order.balance) * CommonLib.NEST_UNIT, 
            CommonLib.decodeFloat(uint(order.basePrice)),
            oraclePrice,
            order.orientation,
            uint(order.lever)
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
    ) external payable override {
        // 1. Check arguments
        require(amount > CommonLib.FUTURES_NEST_LB && amount < 0x1000000000000, "NF:amount invalid");
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
        if (Lp + Sp > 0) 
        {
            // μ is not saved, and calculate it by Lp and Sp always
            // TODO: Confirm unit of miu
            int miu = (int(Lp) - int(Sp)) * MIU_LAMBDA / 86400 / int(Lp + Sp);
            // TODO: Check truncation
            channel.Pt = int56(
                int(channel.Pt) + 
                miu * int((block.number - uint(channel.bn)) * CommonLib.BLOCK_TIME / 1000)
            );
        }

        // 4. Update Lp and Sp, for calculate next μ
        // Lp and Sp are add(sub) with original bond
        // When buy, Lp(Sp) += lever * amount
        // When sell(liquidate), Lp(Sp) -= lever * amount
        // Original bond not include service fee
        // Long
        if (orientation) {
            // TODO: Check truncation
            channel.Lp = uint56(Lp + amount * uint(lever));
        }
        // Short
        else {
            // TODO: Check truncation
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
            CommonLib.encodeFloat56(_queryPrice(channelIndex)),
            // balance
            uint48(amount),
            // baseBlock
            uint32(block.number),
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
        // TODO: Confirm the logic of add
        // 1. Check arguments
        require(amount > CommonLib.FUTURES_NEST_LB, "NF:amount invalid");

        // 2. Load the order
        Order memory order = _orders[orderIndex];
        uint channelIndex = uint(order.channelIndex);
        TradeChannel memory channel = _channels[channelIndex];
        
        uint balance = uint(order.balance);
        require(balance > 0, "NF:order cleared");
        require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");

        // 3. Calculate miuT
        int miuT = int(channel.Pt);
        {
            // Calculate Pt by μ from last order
            uint Lp = uint(channel.Lp);
            uint Sp = uint(channel.Sp);
            if (Lp + Sp > 0) {
                // μ is not saved, and calculate it by Lp and Sp always
                // TODO: Confirm unit of miu
                int miu = (int(Lp) - int(Sp)) * MIU_LAMBDA / 86400 / int(Lp + Sp);
                miuT = miuT + miu * int((block.number - uint(channel.bn)) * CommonLib.BLOCK_TIME / 1000);
            }

            // μt = P1 - P0
            miuT -= int(order.Pt);
            
            // // TODO: Move to balanceOf
            // if (order.orientation) {
            //     if (miuT < 0) miuT = 0;
            // } else {
            //     if (miuT > 0) miuT = 0;
            // }
        }

        // When add, first calculate balance of the order same as sell (include miu),
        // Then add amount to the balance, and update to order,
        // Only update balance of the order, 
        // Pt of the order, and global Lp, Sp, Pt, miu not update
        // 3. Query oracle price
        // TODO: Optimize code
        uint oraclePrice = _queryPrice(channelIndex);
        uint newBalance = _valueOf(
            miuT, 
            balance * CommonLib.NEST_UNIT,
            CommonLib.decodeFloat(order.basePrice),
            oraclePrice,
            order.orientation,
            order.lever
        ) / CommonLib.NEST_UNIT + amount;
        require(newBalance < 0x1000000000000, "NF:balance too big");

        // 4. Update order
        order.balance = uint48(newBalance);
        //order.baseBlock = uint32(block.number);
        _orders[orderIndex] = order;

        // 5. Transfer NEST from user
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_VAULT_ADDRESS, 
            amount * CommonLib.NEST_UNIT * (1 ether + CommonLib.FEE_RATE * uint(order.lever)) / 1 ether
        );

        // 6. Emit event
        emit Add(orderIndex, amount, msg.sender);
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
        uint Lp = uint(channel.Lp);
        uint Sp = uint(channel.Sp);
        if (Lp + Sp > 0) {
            // μ is not saved, and calculate it by Lp and Sp always
            // TODO: Confirm unit of miu
            int miu = (int(Lp) - int(Sp)) * MIU_LAMBDA / 86400 / int(Lp + Sp);
            // TODO: Check truncation
            channel.Pt = int56(
                int(channel.Pt) + 
                miu * int((block.number - uint(channel.bn)) * CommonLib.BLOCK_TIME / 1000)
            );
        }

        // μt = P1 - P0
        int miuT = int(channel.Pt) - int(order.Pt);
        
        // 3. Update Lp and Sp, for calculate next μ
        // Lp and Sp are add(sub) with original bond
        // When buy, Lp(Sp) += lever * amount
        // When sell(liquidate), Lp(Sp) -= lever * amount
        // Original bond not include service fee
        // Long
        if (order.orientation) {
            channel.Lp = uint56(Lp - balance * lever);
            if (miuT < 0) miuT = 0;
        } 
        // Short
        else {
            channel.Sp = uint56(Sp - balance * lever);
            if (miuT > 0) miuT = 0;
        }
        // 4. Update parameter for channel
        channel.bn = uint32(block.number);
        _channels[channelIndex] = channel;

        // 5. Query oracle price
        uint oraclePrice = _queryPrice(channelIndex);

        // 6. Update order
        order.balance = uint48(0);
        _orders[orderIndex] = order;

        // 7. Transfer NEST to user
        uint value = _valueOf(
            miuT,
            // balance
            balance * CommonLib.NEST_UNIT, 
            // basePrice
            basePrice, 
            // baseBlock
            //uint(order.baseBlock),
            // oraclePrice
            oraclePrice, 
            // ORIENTATION
            order.orientation, 
            // LEVER
            lever
        );
        
        uint fee = balance * CommonLib.NEST_UNIT * lever * oraclePrice / basePrice * CommonLib.FEE_RATE / 1 ether;
        // If value grater than fee, deduct and transfer NEST to owner
        if (value > fee) {
            INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, value - fee);
        }

        // 8. Emit event
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
            uint balance = uint(order.balance);
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
                        // TODO: Confirm unit of miu
                        int miu = (int(Lp) - int(Sp)) * MIU_LAMBDA / 86400 / int(Lp + Sp);
                        // TODO: Check truncation
                        channel.Pt = int56(
                            int(channel.Pt) + 
                            miu * int((block.number - uint(channel.bn)) * CommonLib.BLOCK_TIME / 1000)
                        );
                    }
                }

                // μt = P1 - P0
                int miuT = int(channel.Pt) - int(order.Pt);

                // 3. Calculate order value
                uint basePrice = CommonLib.decodeFloat(order.basePrice);
                uint value = _valueOf(
                    // tokenConfig
                    miuT,
                    // balance
                    // TODO: Need multiply with CommonLib.NEST_UNIT
                    balance * CommonLib.NEST_UNIT, 
                    // basePrice
                    basePrice, 
                    // baseBlock
                    //uint(order.baseBlock),
                    // oraclePrice
                    oraclePrice, 
                    // ORIENTATION
                    order.orientation, 
                    // LEVER
                    lever
                );

                // 4. Liquidate logic
                // TODO: The liquidate condition need update
                // lever is great than 1, and balance less than a regular value, can be liquidated
                // the regular value is: Max(M0 * L * St / S0 * c, a) | expired
                // the regular value is: Max(M0 * L * St / S0 * c + a, M0 * L * 0.5%)
                balance = balance * CommonLib.NEST_UNIT * lever;
                if (value < balance * 5 / 1000 ||
                    value < balance * oraclePrice / basePrice * CommonLib.FEE_RATE / 1 ether
                            + CommonLib.MIN_FUTURE_VALUE
                ) {
                    if (order.orientation) {
                        // TODO: Optimize code
                        channel.Lp = uint56(uint(channel.Lp) - balance / CommonLib.NEST_UNIT);
                    } else {
                        // TODO: Optimize code
                        channel.Sp = uint56(uint(channel.Sp) - balance / CommonLib.NEST_UNIT);
                    }

                    // TODO: Use this code
                    // Clear all data of order, use this code next time
                    // assembly {
                    //     mstore(0, _orders.slot)
                    //     sstore(add(keccak256(0, 0x20), index), 0)
                    // }
                    
                    // Clear balance
                    order.balance = uint48(0);
                    // Clear baseBlock
                    order.baseBlock = uint32(0);
                    // Update order
                    _orders[index] = order;

                    // Add reward
                    reward += value;

                    // Emit liquidate event
                    emit Liquidate(index, msg.sender, value);
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
        // TODO: This may be 0, or negative!
        return uint((miuT * 0x10000000000000000) / MIU_DECIMALS + 0x10000000000000000);
    }

    // Calculate net worth
    function _valueOf(
        int miuT,
        uint balance,
        uint basePrice,
        uint oraclePrice, 
        bool ORIENTATION, 
        uint LEVER
    ) internal pure returns (uint) {
        if (balance > 0) {
            uint left;
            uint right;
            uint base = LEVER * balance * oraclePrice / basePrice;
            // Long
            if (ORIENTATION) {
                left = balance + (miuT > 0 ? base * 0x10000000000000000 / _expMiuT(miuT) : base);
                right = balance * LEVER;
            } 
            // Short
            else {
                left = balance * (1 + LEVER);
                right = miuT < 0 ? base * 0x10000000000000000 / _expMiuT(miuT) : base;
            }

            if (left > right) {
                balance = left - right;
            } else {
                balance = 0;
            }
        }

        return balance;
    }

    // Query price
    function _queryPrice(uint channelIndex) internal view returns (uint oraclePrice) {
        // Query price from oracle
        (uint period, uint height, uint price) = _decodePrice(_lastPrices, channelIndex);
        require(block.number < height + period, "NF:price expired");
        oraclePrice = CommonLib.toUSDTPrice(price);
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
            // baseBlock
            order.baseBlock,
            // lever
            order.lever,
            // orientation
            order.orientation,
            // basePrice
            CommonLib.decodeFloat(order.basePrice),
            // Pt
            order.Pt
        );
    }
}
