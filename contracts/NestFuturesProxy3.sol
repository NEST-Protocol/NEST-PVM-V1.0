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

    TrustOrder[] _trustOrders;

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
        require(lever > 0 && lever < 21, "NF:lever not allowed");
        
        // 2. Service fee, 4 decimals
        uint fee = amount * CommonLib.FEE_RATE * uint(lever) / 1 ether;

        _trustOrders.push(TrustOrder(
            uint32(_orders.length),
            uint48(amount),
            uint48(fee),
            CommonLib.encodeFloat56(stopProfitPrice),
            CommonLib.encodeFloat56(stopLossPrice),
            uint8(S_NORMAL)
        ));

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
    }

    function changeLimitPrice(uint trustOrderIndex, uint limitPrice) external {
        TrustOrder memory trustOrder = _trustOrders[trustOrderIndex];
        require(uint(trustOrder.status) == S_NORMAL);
        uint orderIndex = uint(trustOrder.orderIndex);
        Order memory order = _orders[orderIndex];
        require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");
        _orders[orderIndex].basePrice = CommonLib.encodeFloat56(limitPrice);
    }

    function changeStopPrice(uint trustOrderIndex, uint stopProfitPrice, uint stopLossPrice) external {

    }
}
