// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestFuturesWithPrice.sol";
import "./interfaces/INestVault.sol";
import "./interfaces/INestFutures2.sol";

import "./custom/NestFrequentlyUsed.sol";

import "./NestFutures2.sol";

/// @dev Futures
contract NestFuturesProxy is NestFrequentlyUsed {
    
    uint constant S_EXECUTED = 0;
    uint constant S_NORMAL = 1;
    uint constant S_CANCELED = 2;
    uint constant S_WAITING = 3;

    // Limit order
    struct LimitOrder {
        address owner;
        uint16 tokenIndex;
        uint8 lever;
        bool orientation;
        uint64 balance;
        uint64 fee;
        uint64 limitPrice;
        uint32 stopOrderIndex;
        // 0: executed, 1: normal, 2: canceled
        uint8 status;
    }

    // Stop order
    struct StopOrder {
        address owner;
        uint32 orderIndex;
        // 0: executed, 1: normal, 3: waiting for limit
        uint8 status;
        //uint64 takeProfitPrice;
        //uint64 stopLossPrice;
        uint64 stopPrice;
        uint64 fee;
    }

    LimitOrder[] _limitOrders;

    StopOrder[] _stopOrders;

    address _nestFutures;

    modifier onlyMaintains {
        // TODO:
        //require(msg.sender == "");
        _;
    }

    // Create limit order, for everyone
    function newLimitOrder(uint16 tokenIndex, uint8 lever, bool orientation, uint amount, uint limitPrice) external {

        uint fee = amount * 2 / 1000;
        _limitOrders.push(LimitOrder(
            msg.sender,
            tokenIndex,
            lever,
            orientation,
            uint64(amount),
            uint64(fee),
            uint64(limitPrice),
            0,
            uint8(S_NORMAL)
        ));

        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), amount + fee);
    }

    // Create limit order with stop order, for everyone
    function newLimitOrderWithStop(
        uint16 tokenIndex, 
        uint8 lever, 
        bool orientation, 
        uint amount, 
        uint limitPrice,
        uint stopPrice
    ) external {
        uint limitFee = amount * 2 / 1000;
        uint stopFee = amount * 2 / 1000;

        _limitOrders.push(LimitOrder(
            msg.sender,
            tokenIndex,
            lever,
            orientation,
            uint64(amount),
            uint64(limitFee),
            uint64(limitPrice),
            // TODO: first index is 0
            uint32(_stopOrders.length),
            uint8(S_NORMAL)
        ));

        _stopOrders.push(StopOrder(msg.sender, 0, uint8(S_WAITING), uint64(stopPrice), uint64(stopFee)));

        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), amount + limitFee + stopFee);
    }

    // Create stop order, for everyone
    function newStopOrder(uint32 orderIndex, uint stopPrice) external {
        (address owner, uint balance) = NestFutures2(_nestFutures).getOrder(orderIndex);
        require(owner == msg.sender, "NFP:not owner");
        uint stopFee = balance * 2 / 1000;
        _stopOrders.push(StopOrder(msg.sender, orderIndex, uint8(S_NORMAL), uint64(stopPrice), uint64(stopFee)));
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), stopFee);
    }

    // Update stop order, for everyone
    function updateStopOrder(uint32 stopOrderIndex, uint stopPrice) external {
        StopOrder memory order = _stopOrders[stopOrderIndex];
        require(order.owner == msg.sender, "NFP:not owner");
        order.stopPrice = uint64(stopPrice);
        _stopOrders[stopOrderIndex] = order;
    }

    // Cancel limit order, for everyone
    function cancelLimitOrder(uint index) external {
        LimitOrder memory order = _limitOrders[index];
        require(uint(order.status) == S_NORMAL, "NFP:order can't be canceled");
        uint nestAmount = order.balance + order.fee;
        if (order.stopOrderIndex > 0 && order.status == S_WAITING) {
            require(uint(_stopOrders[order.stopOrderIndex].status) == S_WAITING, "NFP:status error");
            _stopOrders[order.stopOrderIndex].status = uint8(S_CANCELED);
            nestAmount += _stopOrders[order.stopOrderIndex].fee;
        }
        order.status = uint8(S_CANCELED);
        _limitOrders[index] = order;
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, msg.sender, nestAmount);
    }

    // Execute limit order, only maintains account
    function executeLimitOrder(uint[] calldata indices) external onlyMaintains {
        address futures = _nestFutures;
        uint totalNest = 0;
        for (uint i = indices.length; i > 0;) {
            uint index = indices[--i];
            LimitOrder memory order = _limitOrders[index];
            if (uint(order.status) == S_NORMAL) {
                uint orderIndex = NestFutures2(futures).proxyBuy2(
                    order.owner, 
                    order.tokenIndex, 
                    order.lever, 
                    order.orientation, 
                    order.balance
                );
                totalNest += order.balance;

                order.status = uint8(S_EXECUTED);
                _limitOrders[index] = order;
                
                if (order.stopOrderIndex > 0 && order.status == S_WAITING) {
                    require(uint(_stopOrders[order.stopOrderIndex].status) == S_WAITING, "NFP:status error");
                    _stopOrders[order.stopOrderIndex].orderIndex = uint32(orderIndex);
                    _stopOrders[order.stopOrderIndex].status = uint8(S_NORMAL);
                }
            }
        }

        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, NEST_VAULT_ADDRESS, totalNest);
    }

    // Execute stop order, only maintains account
    function executeStopOrder(uint[] calldata indices) external onlyMaintains {
        address futures = _nestFutures;
        for (uint i = indices.length; i > 0;) {
            uint index = indices[--i];
            StopOrder memory order = _stopOrders[index];
            if (uint(order.status) == S_NORMAL) {
                order.status == uint8(S_EXECUTED);
                NestFutures2(futures).proxySell2(order.orderIndex);
            }
        }
    }
}
