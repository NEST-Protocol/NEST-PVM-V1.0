// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestVault.sol";

import "./NestFutures2_Simple.sol";

/// @dev Nest futures without merger
contract NestFutures3 is NestFutures2_Simple {

    // TODO: SigmaSQ is no use?
    // TODO: Add view method to get miu

    // Global parameter for trade channel
    struct ChannelParameter {
        uint56 sigmaSQ;
        uint56 Lp;
        uint56 Sp;
        int56 Pt;
        uint32 ts;
    }

    /// @dev Order structure
    struct Order3 {
        // Address index of owner
        uint32 owner;
        // Base price of this order, encoded with encodeFloat56()
        uint56 basePrice;
        // Balance of this order, 4 decimals
        uint48 balance;
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

    // TODO: Place orders to global array

    // Trade channel
    struct TradeChannel {
        Order3[] orders;
        ChannelParameter parameter;
    }

    // Trade channel array
    TradeChannel[] _channels;

    constructor() {
    }

    function openChannel() external onlyGovernance {
        _channels.push();
    }

    function getChannelParameter(uint channelIndex) external view 
    returns (uint sigmaSQ, uint Lp, uint Sp, int Pt, uint ts) {
        ChannelParameter memory parameter = _channels[channelIndex].parameter;
        return (
            uint(parameter.sigmaSQ), 
            uint(parameter.Lp), 
            uint(parameter.Sp), 
            int(parameter.Pt), 
            uint(parameter.ts)
        );
    }

    /// @dev Buy futures
    /// @param channelIndex Index of target channel
    /// @param lever Lever of order
    /// @param orientation true: long, false: short
    /// @param amount Amount of paid NEST, 4 decimals
    function buy3(
        uint16 channelIndex, 
        uint8 lever, 
        bool orientation, 
        uint amount
    ) external payable {
        require(amount > CommonLib.FUTURES_NEST_LB && amount < 0x1000000000000, "NF:amount invalid");
        // TODO: To confirm range of lever
        require(lever > 0 && lever < 30, "NF:lever not allowed");

        // Load target channel
        // channelIndex is increase from 0, if channelIndex out of range, means target channel not exist
        TradeChannel storage channel = _channels[channelIndex];
        ChannelParameter memory parameter = channel.parameter;

        // Lp和Sp都是按照初始保证金相加减
        // 买入时加上初始保证金*杠杆倍数
        // 卖出时减去初始保证金*杠杆倍数
        // 初始保证金不包括手续费

        // 顺序：单子出现以后，先更新P（用上一个μ) 。再更新Sp，Lp，根据新的Sp，Lp计算新的一个μ。最后调用Pt的开仓关仓差额计算持仓费。
        // 第一笔交易P0必然是0，可以理解为之前的mu也是0

        // TODO: μ is a very important information for user, it should be shown for user
        // Update Pt
        uint Lp = uint(parameter.Lp);
        uint Sp = uint(parameter.Sp);

        if (Lp + Sp > 0) 
        {
            // TODO: Confirm unit of miu
            int miu = (int(Lp) - int(Sp)) * 0.02e12 / 86400 / int(Lp + Sp);
            // TODO: Check truncation
            parameter.Pt = int56(int(parameter.Pt) + miu * int(block.timestamp - uint(parameter.ts)));
        }

        // Long
        if (orientation) {
            // TODO: Check truncation
            parameter.Lp = uint56(Lp + amount * uint(lever));
        }
        // Short
        else {
            // TODO: Check truncation
            parameter.Sp = uint56(Sp + amount * uint(lever));
        }

        parameter.ts = uint32(block.timestamp);
        channel.parameter = parameter;

        // 1. Emit event
        emit Buy2(channel.orders.length, amount, msg.sender);

        // 2. Create order
        channel.orders.push(Order3(
            // owner
            uint32(_addressIndex(msg.sender)),
            // basePrice
            // Query oraclePrice
            // TODO: Rewrite queryPrice function
            CommonLib.encodeFloat56(_queryPrice3(channelIndex)),
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
            parameter.Pt
        ));

        // 4. Transfer NEST from user
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_VAULT_ADDRESS, 
            amount * CommonLib.NEST_UNIT * (1 ether + CommonLib.FEE_RATE * uint(lever)) / 1 ether
        );
    }

    // /// @dev Append buy
    // /// @param channelIndex Index of target channel
    // /// @param orderIndex Index of target order
    // /// @param amount Amount of paid NEST
    // function add3(uint channelIndex, uint orderIndex, uint amount) external payable override {
        
    //     // TODO: Confirm the logic of add
    //     require(amount > CommonLib.FUTURES_NEST_LB, "NF:amount invalid");

    //     TradeChannel storage channel = _channels[channelIndex];
    //     Trade
    //     // 1. Load the order
    //     Order memory order = _orders[index];

    //     uint basePrice = CommonLib.decodeFloat(order.basePrice);
    //     uint balance = uint(order.balance);
    //     uint newBalance = balance + amount;

    //     require(balance > 0, "NF:order cleared");
    //     require(newBalance < 0x1000000000000, "NF:balance too big");
    //     require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");

    //     // 2. Query oracle price
    //     TokenConfig memory tokenConfig = _tokenConfigs[uint(order.tokenIndex)];
    //     uint oraclePrice = _queryPrice(tokenConfig);

    //     // 3. Update order
    //     // Merger price
    //     order.basePrice = CommonLib.encodeFloat56(newBalance * oraclePrice * basePrice / (
    //         basePrice * amount + (balance << 64) * oraclePrice / _expMiuT(
    //             uint(order.orientation ? tokenConfig.miuLong : tokenConfig.miuShort), 
    //             uint(order.baseBlock)
    //         )
    //     ));
    //     order.balance = uint48(newBalance);
    //     order.baseBlock = uint32(block.number);
    //     _orders[index] = order;

    //     // 4. Transfer NEST from user
    //     TransferHelper.safeTransferFrom(
    //         NEST_TOKEN_ADDRESS, 
    //         msg.sender, 
    //         NEST_VAULT_ADDRESS, 
    //         amount * CommonLib.NEST_UNIT * (1 ether + CommonLib.FEE_RATE * uint(order.lever)) / 1 ether
    //     );

    //     // 5. Emit event
    //     emit Buy2(index, amount, msg.sender);
    // }

    /// @dev Sell order
    /// @param channelIndex Index of target channel
    /// @param orderIndex Index of order
    function sell3(uint channelIndex, uint orderIndex) external payable {
        // 1. Load the order
        TradeChannel storage channel = _channels[channelIndex];
        ChannelParameter memory parameter = channel.parameter;
        Order3 memory order = channel.orders[orderIndex];
        
        require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");

        uint basePrice = CommonLib.decodeFloat(uint(order.basePrice));
        uint balance = uint(order.balance);
        uint lever = uint(order.lever);

        // 2. Query oracle price
        uint oraclePrice = _queryPrice3(channelIndex);

        // 3. Update order
        order.balance = uint48(0);
        channel.orders[orderIndex] = order;

        // 顺序：单子出现以后，先更新P（用上一个μ) 。再更新Sp，Lp，根据新的Sp，Lp计算新的一个μ。最后调用Pt的开仓关仓差额计算持仓费。
        // 第一笔交易P0必然是0，可以理解为之前的mu也是0
        uint Lp = uint(parameter.Lp);
        uint Sp = uint(parameter.Sp);
        if (Lp + Sp > 0) {
            int miu = (int(Lp) - int(Sp)) * 0.02e12 / 86400 / int(Lp + Sp);
            parameter.Pt = int56(int(parameter.Pt) + miu * int(block.timestamp - uint(parameter.ts)));
        }
        int miuT = int(parameter.Pt) - int(order.Pt);
        
        // Long
        if (order.orientation) {
            parameter.Lp = uint56(Lp - balance * lever);
            if (miuT < 0) miuT = 0;
        } 
        // Short
        else {
            parameter.Sp = uint56(Sp - balance * lever);
            if (miuT > 0) miuT = 0;
        }

        parameter.ts = uint32(block.timestamp);
        channel.parameter = parameter;

        // 4. Transfer NEST to user
        uint value = _balanceOf3(
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

        // 5. Emit event
        //emit Sell2(index, balance, msg.sender, value);
    }

    // /// @dev Liquidate order
    // /// @param indices Target order indices
    // function liquidate3(uint[] calldata indices) external payable override {
    //     uint reward = 0;
    //     uint oraclePrice = 0;
    //     uint tokenIndex = 0x10000;
    //     TokenConfig memory tokenConfig;
        
    //     // 1. Loop and liquidate
    //     for (uint i = indices.length; i > 0;) {
    //         uint index = indices[--i];
    //         Order memory order = _orders[index];

    //         uint lever = uint(order.lever);
    //         uint balance = uint(order.balance) * CommonLib.NEST_UNIT;
    //         if (lever > 1 && balance > 0) {
    //             // If tokenIndex is not same with previous, need load new tokenConfig and query oracle
    //             // At first, tokenIndex is 0x10000, this is impossible the same with current tokenIndex
    //             if (tokenIndex != uint(order.tokenIndex)) {
    //                 tokenIndex = uint(order.tokenIndex);
    //                 tokenConfig = _tokenConfigs[tokenIndex];
    //                 oraclePrice = _queryPrice(tokenConfig);
    //                 //require(oraclePrice > 0, "NF:price error");
    //             }

    //             // 3. Calculate order value
    //             uint basePrice = CommonLib.decodeFloat(order.basePrice);
    //             uint value = _balanceOf(
    //                 // tokenConfig
    //                 tokenConfig,
    //                 // balance
    //                 balance, 
    //                 // basePrice
    //                 basePrice, 
    //                 // baseBlock
    //                 uint(order.baseBlock),
    //                 // oraclePrice
    //                 oraclePrice, 
    //                 // ORIENTATION
    //                 order.orientation, 
    //                 // LEVER
    //                 lever
    //             );

    //             // 4. Liquidate logic
    //             // lever is great than 1, and balance less than a regular value, can be liquidated
    //             // the regular value is: Max(M0 * L * St / S0 * c, a)
    //             if (value < CommonLib.MIN_FUTURE_VALUE || 
    //                 value < balance * lever * oraclePrice / basePrice * CommonLib.FEE_RATE / 1 ether) {

    //                 // Clear all data of order, use this code next time
    //                 // assembly {
    //                 //     mstore(0, _orders.slot)
    //                 //     sstore(add(keccak256(0, 0x20), index), 0)
    //                 // }
                    
    //                 // Clear balance
    //                 order.balance = uint48(0);
    //                 // Clear baseBlock
    //                 order.baseBlock = uint32(0);
    //                 // Update order
    //                 _orders[index] = order;

    //                 // Add reward
    //                 reward += value;

    //                 // Emit liquidate event
    //                 emit Liquidate2(index, msg.sender, value);
    //             }
    //         }
    //     }

    //     // 6. Transfer NEST to user
    //     if (reward > 0) {
    //         INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, reward);
    //     }
    // }

    // /// @dev Buy from NestFuturesPRoxy
    // /// @param tokenIndex Index of token
    // /// @param lever Lever of order
    // /// @param orientation true: call, false: put
    // /// @param amount Amount of paid NEST, 4 decimals
    // /// @param stopPrice Stop price for stop order
    // function proxyBuy3(
    //     address owner, 
    //     uint16 tokenIndex, 
    //     uint8 lever, 
    //     bool orientation, 
    //     uint48 amount,
    //     uint56 stopPrice
    // ) external payable onlyProxy {
    //     // 1. Emit event
    //     emit Buy2(_orders.length, uint(amount), owner);

    //     // 2. Create order
    //     _orders.push(Order(
    //         // owner
    //         uint32(_addressIndex(owner)),
    //         // basePrice
    //         // Query oraclePrice
    //         CommonLib.encodeFloat56(_queryPrice(_tokenConfigs[tokenIndex])),
    //         // balance
    //         amount,
    //         // baseBlock
    //         uint32(block.number),
    //         // tokenIndex
    //         tokenIndex,
    //         // lever
    //         lever,
    //         // orientation
    //         orientation,
    //         // stopPrice
    //         stopPrice
    //     ));
    // }
    
    // // Convert Order to OrderView
    // function _toOrderView3(Order memory order, uint index) internal view returns (OrderView memory v) {
    //     v = OrderView(
    //         // index
    //         uint32(index),
    //         // owner
    //         _accounts[uint(order.owner)],
    //         // balance
    //         order.balance,
    //         // tokenIndex
    //         order.tokenIndex,
    //         // baseBlock
    //         order.baseBlock,
    //         // lever
    //         order.lever,
    //         // orientation
    //         order.orientation,
    //         // basePrice
    //         CommonLib.decodeFloat(order.basePrice),
    //         // stopPrice
    //         CommonLib.decodeFloat(order.stopPrice)
    //     );
    // }

    // Query price
    function _queryPrice3(uint channelIndex) internal view returns (uint oraclePrice) {
        // Query price from oracle
        (uint period, uint height, uint price) = _decodePrice(_lastPrices, channelIndex);
        require(block.number < height + period, "NFWP:price expired");
        oraclePrice = CommonLib.toUSDTPrice(price);
    }

    // Calculate net worth
    function _balanceOf3(
        int miuT,
        uint balance,
        uint basePrice,
        uint oraclePrice, 
        bool ORIENTATION, 
        uint LEVER
    ) internal view returns (uint) {

        if (balance > 0) {
            uint left;
            uint right;
            // Call
            if (ORIENTATION) {
                left = balance + (LEVER << 64) * balance * oraclePrice / basePrice
                        / _expMiuT3(miuT);
                right = balance * LEVER;
            } 
            // Put
            else {
                left = balance * (1 + LEVER);
                right = (LEVER << 64) * balance * oraclePrice / basePrice 
                        / _expMiuT3(miuT);
            }

            if (left > right) {
                balance = left - right;
            } else {
                balance = 0;
            }
        }

        return balance;
    }

    // Calculate e^μT
    function _expMiuT3(int miuT) internal view returns (uint) {
        // return _toUInt(ABDKMath64x64.exp(
        //     _toInt128((orientation ? MIU_LONG : MIU_SHORT) * (block.number - baseBlock) * BLOCK_TIME)
        // ));

        // Using approximate algorithm: x*(1+rt)
        return uint((miuT * 0x10000000000000000) / 1e12 + 0x10000000000000000);
    }

    uint _lastPrices;

    /// @dev Direct post price
    /// @param period Term of validity
    // @param equivalents Price array, one to one with pairs
    function directPost3(uint period, uint[3] calldata /*equivalents*/) external {
        //require(msg.sender == DIRECT_POSTER, "NFWP:not directPoster");

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
    function lastPrice(uint channelIndex) external view returns (uint period, uint height, uint price) {
        (period, height, price) = _decodePrice(_lastPrices, channelIndex);
    }
}
