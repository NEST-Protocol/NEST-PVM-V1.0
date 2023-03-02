// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestVault.sol";
import "./interfaces/INestFutures3.sol";
import "./interfaces/INestFutures2.sol";

import "./NestFuturesWithPrice.sol";

/// @dev Nest futures without merger
contract NestFutures2 is NestFuturesWithPrice, INestFutures2 {

    /// @dev Order structure
    struct Order {
        // Address index of owner
        uint32 owner;
        // Base price of this order, encoded with encodeFloat56()
        uint56 basePrice;
        // Balance of this order, 4 decimals
        uint48 balance;
        // Open block of this order
        uint32 baseBlock;
        // Index of target token, support eth and btc
        uint16 tokenIndex;
        // Leverage of this order
        uint8 lever;
        // Orientation of this order, long or short
        bool orientation;
        // Stop price, for stop order, encoded with encodeFloat56()
        uint56 stopPrice;
    }

    // Array of orders
    Order[] _orders;

    // Registered account address mapping
    mapping(address=>uint) _accountMapping;

    // Registered accounts
    address[] _accounts;

    address constant FUTURES_PROXY_ADDRESS = 0x8b2A11F6C5cEbB00793dCE502a9B08741eDBcb96;
    address constant MAINTAINS_ADDRESS = 0x029972C516c4F248c5B066DA07DbAC955bbb5E7F;
    // TODO:
    address constant NEST_FUTURES3_ADDRESS = address(0);

    constructor() {
    }

    modifier onlyProxy {
        require(msg.sender == FUTURES_PROXY_ADDRESS, "NF:not futures proxy");
        _;
    }

    /// @dev Returns the current value of target order
    /// @param index Index of order
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    function valueOf2(uint index, uint oraclePrice) external view override returns (uint) {
        // Load order
        Order memory order = _orders[index];

        // Newest value of order, no service charge deducted
        return _balanceOf(
            // tokenConfig
            _tokenConfigs[uint(order.tokenIndex)],
            // balance
            uint(order.balance) * CommonLib.NEST_UNIT, 
            // basePrice
            CommonLib.decodeFloat(uint(order.basePrice)), 
            // baseBlock
            uint(order.baseBlock),
            // oraclePrice
            oraclePrice, 
            // ORIENTATION
            order.orientation, 
            // LEVER
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
    function find2(
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
            uint ownerIndex = _accountMapping[owner];
            for (uint index = 0; index < count && start > end;) {
                Order memory order = orders[--start];
                if (uint(order.owner) == ownerIndex) {
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
    function list2(uint offset, uint count, uint order) external view override returns (OrderView[] memory orderArray) {
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

    /// @dev Set stop price for stop order
    /// @param index Index of order
    /// @param stopPrice Stop price for trigger sell
    function setStopPrice(uint index, uint stopPrice) external {
        require(msg.sender == _accounts[_orders[index].owner], "NF:not owner");
        _orders[index].stopPrice = CommonLib.encodeFloat56(stopPrice);
    }

    /// @dev Sell order
    /// @param index Index of order
    function sell2(uint index) external payable override {
        // 1. Load the order
        Order memory order = _orders[index];
        
        require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");

        uint basePrice = CommonLib.decodeFloat(uint(order.basePrice));
        uint balance = uint(order.balance);
        uint lever = uint(order.lever);

        // 2. Query oracle price
        TokenConfig memory tokenConfig = _tokenConfigs[uint(order.tokenIndex)];
        uint oraclePrice = _queryPrice(uint(order.tokenIndex));

        // 3. Update order
        order.balance = uint48(0);
        _orders[index] = order;

        // 4. Transfer NEST to user
        uint value = _balanceOf(
            // tokenConfig
            tokenConfig,
            // balance
            balance * CommonLib.NEST_UNIT, 
            // basePrice
            basePrice, 
            // baseBlock
            uint(order.baseBlock),
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
        emit Sell2(index, balance, msg.sender, value);
    }

    /// @dev Liquidate order
    /// @param indices Target order indices
    function liquidate2(uint[] calldata indices) external payable override {
        uint reward = 0;
        uint oraclePrice = 0;
        uint tokenIndex = 0x10000;
        TokenConfig memory tokenConfig;
        
        // 1. Loop and liquidate
        for (uint i = indices.length; i > 0;) {
            uint index = indices[--i];
            Order memory order = _orders[index];

            uint lever = uint(order.lever);
            uint balance = uint(order.balance) * CommonLib.NEST_UNIT;
            if (lever > 1 && balance > 0) {
                // If tokenIndex is not same with previous, need load new tokenConfig and query oracle
                // At first, tokenIndex is 0x10000, this is impossible the same with current tokenIndex
                if (tokenIndex != uint(order.tokenIndex)) {
                    tokenIndex = uint(order.tokenIndex);
                    tokenConfig = _tokenConfigs[tokenIndex];
                    oraclePrice = _queryPrice(tokenIndex);
                    //require(oraclePrice > 0, "NF:price error");
                }

                // 3. Calculate order value
                uint basePrice = CommonLib.decodeFloat(order.basePrice);
                uint value = _balanceOf(
                    // tokenConfig
                    tokenConfig,
                    // balance
                    balance, 
                    // basePrice
                    basePrice, 
                    // baseBlock
                    uint(order.baseBlock),
                    // oraclePrice
                    oraclePrice, 
                    // ORIENTATION
                    order.orientation, 
                    // LEVER
                    lever
                );

                // 4. Liquidate logic
                // lever is great than 1, and balance less than a regular value, can be liquidated
                // the regular value is: Max(M0 * L * St / S0 * c, a) | expired
                // the regular value is: Max(M0 * L * St / S0 * c + a, M0 * L * 0.5%)
                if (value < balance * lever / 200 || 
                    value < balance * lever * oraclePrice / basePrice * CommonLib.FEE_RATE / 1 ether 
                            + CommonLib.MIN_FUTURE_VALUE
                ) {

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
                    emit Liquidate2(index, msg.sender, value);
                }
            }
        }

        // 6. Transfer NEST to user
        if (reward > 0) {
            INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, reward);
        }
    }

    /// @dev Execute stop order, only for maintains account
    /// @param indices Array of futures order index
    function executeStopOrder(uint[] calldata indices) external payable override {
        // Only for maintains address
        require(msg.sender == MAINTAINS_ADDRESS, "NFP:not maintains");

        uint executeFee = 0;
        uint oraclePrice = 0;
        uint tokenIndex = 0x10000;
        TokenConfig memory tokenConfig;

        for (uint i = indices.length; i > 0;) {
            uint index = indices[--i];
            // 1. Load the order
            Order memory order = _orders[index];
            require(order.stopPrice > 0, "NF:not stop order");

            uint balance = uint(order.balance);
            if (balance > 0) {
                // 2. Query oraclePrice
                // If tokenIndex is not same with previous, need load new tokenConfig and query oracle
                // At first, tokenIndex is 0x10000, this is impossible the same with current tokenIndex
                if (tokenIndex != uint(order.tokenIndex)) {
                    tokenIndex = uint(order.tokenIndex);
                    tokenConfig = _tokenConfigs[tokenIndex];
                    oraclePrice = _queryPrice(tokenIndex);
                    //require(oraclePrice > 0, "NF:price error");
                }

                uint lever = uint(order.lever);
                uint basePrice = CommonLib.decodeFloat(uint(order.basePrice));
                address owner = _accounts[uint(order.owner)];

                // 3. Update account
                order.balance = uint48(0);
                _orders[index] = order;

                // 4. Transfer NEST to user
                uint value = _balanceOf(
                    // tokenConfig
                    tokenConfig,
                    // balance
                    balance * CommonLib.NEST_UNIT, 
                    // basePrice
                    basePrice, 
                    // baseBlock
                    uint(order.baseBlock),
                    // oraclePrice
                    oraclePrice, 
                    // ORIENTATION
                    order.orientation, 
                    // LEVER
                    uint(order.lever)
                );

                uint fee = balance 
                         * CommonLib.NEST_UNIT 
                         * lever 
                         * oraclePrice 
                         / basePrice 
                         * CommonLib.FEE_RATE 
                         / 1 ether;

                // 5. Transfer NEST to owner
                // Newest value of order is greater than fee + EXECUTE_FEE, deduct and transfer NEST to owner
                if (value > fee + CommonLib.EXECUTE_FEE_NEST) {
                    INestVault(NEST_VAULT_ADDRESS).transferTo(owner, value - fee - CommonLib.EXECUTE_FEE_NEST);
                }
                executeFee += CommonLib.EXECUTE_FEE_NEST;

                // 6. Emit event
                emit Sell2(index, balance, owner, value);
            }
        }

        // Transfer EXECUTE_FEE to proxy address
        INestVault(NEST_VAULT_ADDRESS).transferTo(FUTURES_PROXY_ADDRESS, executeFee);
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
            // tokenIndex
            order.tokenIndex,
            // baseBlock
            order.baseBlock,
            // lever
            order.lever,
            // orientation
            order.orientation,
            // basePrice
            CommonLib.decodeFloat(order.basePrice),
            // stopPrice
            CommonLib.decodeFloat(order.stopPrice)
        );
    }

    // Query price
    function _queryPrice(uint tokenIndex) internal view override returns (uint oraclePrice) {
        (uint period, uint height, uint price) = INestFutures3(NEST_FUTURES3_ADDRESS).lastPrice(tokenIndex);
        unchecked { require(block.number < height + period, "NF:price expired"); }
        oraclePrice = price;
    }
}
