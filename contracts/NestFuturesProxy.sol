// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";

import "./interfaces/INestFuturesWithPrice.sol";
import "./interfaces/INestVault.sol";
import "./interfaces/INestFutures2.sol";

import "./custom/NestFrequentlyUsed.sol";

import "./NestFutures2.sol";

/// @dev Futures
contract NestFuturesProxy is NestFrequentlyUsed {
    
    // Status of limit order: executed
    uint constant S_EXECUTED = 0;
    // Status of limit order: normal
    uint constant S_NORMAL = 1;
    // Status of limit order: canceled
    uint constant S_CANCELED = 2;

    // Unit of nest
    uint constant NEST_UNIT = 0.0001 ether;

    // Limit order
    struct LimitOrder {
        // Owner of this order
        address owner;
        // Limit price for trigger buy, encode by _encodeFloat()
        uint64 limitPrice;
        // Index of target token, support eth and btc
        uint16 tokenIndex;
        // Leverage of this order
        uint8 lever;
        // Orientation of this order, long or short
        bool orientation;

        // Balance of nest, 4 decimals
        uint48 balance;
        // Service fee, 4 decimals
        uint48 fee;
        // Limit order fee, 4 decimals
        uint48 limitFee;
        // Stop price for trigger sell, encode by _encodeFloat48()
        uint48 stopPrice;
        // Stop order fee, 4 decimals
        uint48 stopFee;

        // 0: executed, 1: normal, 2: canceled
        uint8 status;
    }

    /// @dev Limit order information for view methods
    struct LimitOrderView {
        // Index of this order
        uint32 index;
        // Owner of this order
        address owner;
        // Index of target token, support eth and btc
        uint16 tokenIndex;
        // Leverage of this order
        uint8 lever;
        // Orientation of this order, long or short
        bool orientation;

        // Limit price for trigger buy
        uint limitPrice;
        // Stop price for trigger sell
        uint stopPrice;

        // Balance of nest, 4 decimals
        uint48 balance;
        // Service fee, 4 decimals
        uint48 fee;
        // Limit order fee, 4 decimals
        uint48 limitFee;
        // Stop order fee, 4 decimals
        uint48 stopFee;
        // Status of order, 0: executed, 1: normal, 2: canceled
        uint8 status;
    }

    // Array of limit orders
    LimitOrder[] _limitOrders;

    // TODO: Remove and add as constant to NestFrequentlyUsed
    address NEST_FUTURES_ADDRESS;
    address MAINTAINS_ADDRESS;
    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        NEST_FUTURES_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.futures");
        MAINTAINS_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.maintains");
    }

    modifier onlyMaintains {
        require(msg.sender == MAINTAINS_ADDRESS, "NFP:not maintains");
        _;
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
    ) external view returns (LimitOrderView[] memory orderArray) {
        orderArray = new LimitOrderView[](count);
        // Calculate search region
        LimitOrder[] storage orders = _limitOrders;

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
        for (uint index = 0; index < count && start > end;) {
            LimitOrder memory order = orders[--start];
            if (order.owner == owner) {
                orderArray[index++] = _toOrderView(order, start);
            }
        }
    }

    /// @dev List orders
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (LimitOrderView[] memory orderArray) {
        // Load orders
        LimitOrder[] storage orders = _limitOrders;
        // Create result array
        orderArray = new LimitOrderView[](count);
        uint length = orders.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                LimitOrder memory o = orders[--index];
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

    /// @dev Create limit order, for everyone
    /// @param tokenIndex Index of target token, support eth and btc
    /// @param lever Leverage of this order
    /// @param orientation Orientation of this order, long or short
    /// @param amount Amount of buy order
    /// @param limitPrice Limit price for trigger buy
    /// @param stopPrice If not 0, will open a stop order
    function newLimitOrder(
        uint16 tokenIndex, 
        uint8 lever, 
        bool orientation, 
        uint amount, 
        uint limitPrice,
        uint stopPrice
    ) external {
        require(amount >= 50 ether / NEST_UNIT && amount < 0x1000000000000, "NF:amount invalid");
        
        uint fee = amount * CommonLib.FEE_RATE / 1 ether;
        uint limitFee = amount * 2 / 1000;
        uint stopFee = 0;
        if (stopPrice > 0) {
            stopFee = amount * 2 / 1000;
        }

        _limitOrders.push(LimitOrder(
            msg.sender,
            _encodeFloat(limitPrice),
            tokenIndex,
            lever,
            orientation,

            uint48(amount),
            uint48(fee),
            uint48(limitFee),
            stopPrice > 0 ? _encodeFloat48(stopPrice) : uint48(0),
            uint48(stopFee),

            uint8(S_NORMAL)
        ));

        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            address(this), 
            (amount + fee + limitFee + stopFee) * NEST_UNIT
        );
    }

    /// @dev Update limitPrice for limit order
    /// @param index Index of limit order
    /// @param limitPrice Limit price for trigger buy
    function updateLimitOrder(uint index, uint limitPrice) external {
        _limitOrders[index].limitPrice = _encodeFloat(limitPrice);
    }

    /// @dev Cancel limit order, for everyone
    /// @param index Index of limit order
    function cancelLimitOrder(uint index) external {
        LimitOrder memory order = _limitOrders[index];
        require(uint(order.status) == S_NORMAL, "NFP:order can't be canceled");
        uint nestAmount = uint(order.balance) + uint(order.fee) + uint(order.limitFee) + uint(order.stopFee);

        order.status = uint8(S_CANCELED);
        _limitOrders[index] = order;
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, msg.sender, nestAmount * NEST_UNIT);
    }

    /// @dev Execute limit order, only maintains account
    /// @param indices Array of limit order index
    function executeLimitOrder(uint[] calldata indices) external onlyMaintains {
        uint totalNest = 0;
        for (uint i = indices.length; i > 0;) {
            uint index = indices[--i];
            LimitOrder memory order = _limitOrders[index];
            if (uint(order.status) == S_NORMAL) {
                NestFutures2(NEST_FUTURES_ADDRESS).proxyBuy2(
                    order.owner, 
                    order.tokenIndex, 
                    order.lever, 
                    order.orientation, 
                    order.balance,
                    order.stopPrice
                );
                totalNest += uint(order.balance) + uint(order.fee);

                order.status = uint8(S_EXECUTED);
                _limitOrders[index] = order;
            }
        }

        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, NEST_VAULT_ADDRESS, totalNest * NEST_UNIT);
    }

    /// @dev Execute stop order, only maintains account
    /// @param indices Array of futures order index
    function executeStopOrder(uint[] calldata indices) external onlyMaintains {
        for (uint i = indices.length; i > 0;) {
            uint index = indices[--i];
            NestFutures2(NEST_FUTURES_ADDRESS).sell2(index);
        }
    }

    // Convert LimitOrder to LimitOrderView
    function _toOrderView(LimitOrder memory order, uint index) internal pure returns (LimitOrderView memory v) {
        v = LimitOrderView(
            uint32(index),
            order.owner,
            order.tokenIndex,
            order.lever,
            order.orientation,
            
            _decodeFloat(uint(order.limitPrice)),
            _decodeFloat(uint(order.stopPrice)),

            order.balance,
            order.fee,
            order.limitFee,
            order.stopFee,
            order.status
        );
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return v float format
    function _encodeFloat(uint value) internal pure returns (uint64 v) {
        assembly {
            v := 0
            for { } gt(value, 0x3FFFFFFFFFFFFFF) { v := add(v, 1) } {
                value := shr(4, value)
            }

            v := or(v, shl(6, value))
        }
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return v float format
    function _encodeFloat48(uint value) internal pure returns (uint48 v) {
        assembly {
            v := 0
            for { } gt(value, 0x3FFFFFFFFFF) { v := add(v, 1) } {
                value := shr(4, value)
            }

            v := or(v, shl(6, value))
        }
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint floatValue) internal pure returns (uint) {
        return (floatValue >> 6) << ((floatValue & 0x3F) << 2);
    }
}
