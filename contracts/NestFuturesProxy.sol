// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";

import "./interfaces/INestFutures2.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Futures proxy
contract NestFuturesProxy is NestFrequentlyUsed {
    
    // Status of limit order: executed
    uint constant S_EXECUTED = 0;
    // Status of limit order: normal
    uint constant S_NORMAL = 1;
    // Status of limit order: canceled
    uint constant S_CANCELED = 2;

    // Limit order
    struct LimitOrder {
        // Owner of this order
        address owner;
        // Limit price for trigger buy, encode by encodeFloat56()
        uint56 limitPrice;
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
        // Stop price for trigger sell, encode by encodeFloat56()
        uint56 stopPrice;

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
        // 1. Check arguments
        require(amount > CommonLib.FUTURES_NEST_LB && amount < 0x1000000000000, "NF:amount invalid");
        require(lever > 0 && lever < 21, "NF:lever not allowed");
        
        // 2. Service fee, 4 decimals
        uint fee = amount * CommonLib.FEE_RATE * uint(lever) / 1 ether;

        // 3. Create limit order
        _limitOrders.push(LimitOrder(
            // owner
            msg.sender,
            // limitPrice
            CommonLib.encodeFloat56(limitPrice),
            // tokenIndex
            tokenIndex,
            // lever
            lever,
            // orientation
            orientation,

            // balance
            uint48(amount),
            // fee
            uint48(fee),
            // limitFee
            uint48(CommonLib.EXECUTE_FEE),
            // stopPrice
            stopPrice > 0 ? CommonLib.encodeFloat56(stopPrice) : uint56(0),

            // status
            uint8(S_NORMAL)
        ));

        // 4. Transfer nest from user to this contract
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            address(this), 
            (amount + fee + CommonLib.EXECUTE_FEE) * CommonLib.NEST_UNIT
        );
    }

    /// @dev Update limitPrice for limit order
    /// @param index Index of limit order
    /// @param limitPrice Limit price for trigger buy
    function updateLimitOrder(uint index, uint limitPrice) external {
        _limitOrders[index].limitPrice = CommonLib.encodeFloat56(limitPrice);
    }

    /// @dev Cancel limit order, for everyone
    /// @param index Index of limit order
    function cancelLimitOrder(uint index) external {
        LimitOrder memory order = _limitOrders[index];
        require(uint(order.status) == S_NORMAL, "NFP:order can't be canceled");

        order.status = uint8(S_CANCELED);
        _limitOrders[index] = order;

        TransferHelper.safeTransfer(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            (uint(order.balance) + uint(order.fee) + uint(order.limitFee)) * CommonLib.NEST_UNIT
        );
    }

    /// @dev Execute limit order, only maintains account
    /// @param indices Array of limit order index
    function executeLimitOrder(uint[] calldata indices) external onlyMaintains {
        uint totalNest = 0;
        // Loop and execute limit orders
        for (uint i = indices.length; i > 0;) {
            // Get order index
            uint index = indices[--i];
            // Load limit order
            LimitOrder memory order = _limitOrders[index];
            // Status of limit order must be S_NORMAL
            if (uint(order.status) == S_NORMAL) {
                // Create futures order by proxy
                INestFutures2(NEST_FUTURES_ADDRESS).proxyBuy2(
                    // owner
                    order.owner, 
                    // tokenIndex
                    order.tokenIndex, 
                    // lever
                    order.lever, 
                    // orientation
                    order.orientation, 
                    // amount
                    order.balance,
                    // stopPrice
                    order.stopPrice
                );

                // Add nest to totalNest
                totalNest += uint(order.balance) + uint(order.fee);
                order.status = uint8(S_EXECUTED);
                _limitOrders[index] = order;
            }
        }

        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, NEST_VAULT_ADDRESS, totalNest * CommonLib.NEST_UNIT);
    }

    // /// @dev Execute stop order, only maintains account
    // /// @param indices Array of futures order index
    // function executeStopOrder(uint[] calldata indices) external onlyMaintains {
    //     // Loop and execute stop orders
    //     // for (uint i = indices.length; i > 0;) {
    //     //     NestFutures2(NEST_FUTURES_ADDRESS).proxySell2(indices[--i]);
    //     // }
    //     NestFutures2(NEST_FUTURES_ADDRESS).proxySell2(indices);
    // }

    /// @dev Migrate token to NestLedger
    /// @param tokenAddress Address of target token
    /// @param value Value of target token
    function migrate(address tokenAddress, uint value) external onlyGovernance {
        TransferHelper.safeTransfer(tokenAddress, INestGovernance(_governance).getNestLedgerAddress(), value);
    }

    // Convert LimitOrder to LimitOrderView
    function _toOrderView(LimitOrder memory order, uint index) internal pure returns (LimitOrderView memory v) {
        v = LimitOrderView(
            // index
            uint32(index),
            // owner
            order.owner,
            // tokenIndex
            order.tokenIndex,
            // lever
            order.lever,
            // orientation
            order.orientation,
            
            // limitPrice
            CommonLib.decodeFloat(uint(order.limitPrice)),
            // stopPrice
            CommonLib.decodeFloat(uint(order.stopPrice)),

            // balance
            order.balance,
            // fee
            order.fee,
            // limitFee
            order.limitFee,
            // status
            order.status
        );
    }
}
