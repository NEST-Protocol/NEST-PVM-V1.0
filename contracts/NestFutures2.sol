// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestFuturesWithPrice.sol";
import "./interfaces/INestVault.sol";
import "./interfaces/INestFutures2.sol";

import "./custom/ChainParameter.sol";

import "./NestFuturesWithPrice.sol";

/// @dev Nest futures without merger
contract NestFutures2 is NestFuturesWithPrice, INestFutures2 {

    // Unit of nest
    uint constant NEST_UNIT = 0.0001 ether;

    /// @dev Order structure
    struct Order {
        // Address index of owner
        uint32 owner;
        // Base price of this order, encoded with _encodeFloat()
        uint64 basePrice;
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
        // Stop price, for stop order
        uint48 stopPrice;
    }

    // TODO: place holder
    uint[3] _placeHolder;

    // Array of orders
    Order[] _orders;

    // Registered account address mapping
    mapping(address=>uint) _accountMapping;

    // Registered accounts
    address[] _accounts;

    // TODO:
    address FUTURES_PROXY_ADDRESS;
    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        FUTURES_PROXY_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.futuresProxy");
    }

    constructor() {
    }

    modifier onlyProxy {
        require(msg.sender == FUTURES_PROXY_ADDRESS, "NF:not futures proxy");
        _;
    }

    // TODO: Don't forget init after upgrade
    // Initialize account array, execute once
    function init() external {
        require(_accounts.length == 0, "NF:initialized");
        _accounts.push();
    }

    /// @dev Returns the current value of target order
    /// @param index Index of order
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    function valueOf2(uint index, uint oraclePrice) external view override returns (uint) {
        // Load order
        Order memory order = _orders[index];
        return _balanceOf(
            // tokenConfig
            _tokenConfigs[uint(order.tokenIndex)],
            // balance
            uint(order.balance) * NEST_UNIT, 
            // basePrice
            _decodeFloat(order.basePrice), 
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
            if (uint(order.balance) > 0 && uint(order.owner) == ownerIndex) {
                orderArray[index++] = _toOrderView(order, start);
            }
        }
    }

    /// @dev List orders
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function list2(uint offset, uint count, uint order) external view override returns (OrderView[] memory orderArray) {
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
    /// @param tokenIndex Index of token
    /// @param lever Lever of order
    /// @param orientation true: long, false: short
    /// @param amount Amount of paid NEST, 4 decimals
    /// @param stopPrice Stop price for trigger sell, 0 means not stop order
    function buy2(
        uint16 tokenIndex, 
        uint8 lever, 
        bool orientation, 
        uint amount, 
        uint stopPrice
    ) external payable override {
        // TODO: Test gas of 50 ether / NEST_UNIT and 500000
        require(amount >= 50 ether / NEST_UNIT && amount < 0x1000000000000, "NF:amount invalid");

        // TODO: Restrict bounds for lever
        require(lever > 0 && lever < 21, "NF:lever not allowed");

        // 1. Transfer NEST from user
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_VAULT_ADDRESS, 
            stopPrice > 0 ? ((amount + amount * 2 / 100) * NEST_UNIT) : (amount * NEST_UNIT)
        );

        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k

        // TODO: Use fee to instead of k
        TokenConfig memory tokenConfig = _tokenConfigs[tokenIndex];
        uint oraclePrice = _queryPrice(amount * NEST_UNIT, tokenConfig, orientation);

        // 3. Emit event
        emit Buy2(_orders.length, amount, msg.sender);

        // 4. Create order
        _orders.push(Order(
            // owner
            uint32(_addressIndex(msg.sender)),
            // basePrice
            _encodeFloat(oraclePrice),
            // balance
            uint48(amount),
            // baseBlock
            uint32(block.number),
            // tokenIndex
            tokenIndex,
            // lever
            lever,
            // orientation
            orientation,
            // stopPrice
            stopPrice > 0 ? _encodeFloat48(stopPrice) : uint48(0)
        ));
    }

    /// @dev Set stop price for stop order
    /// @param index Index of order
    /// @param stopPrice Stop price for trigger sell
    function setStopPrice(uint index, uint stopPrice) external {
        Order memory order = _orders[index];
        require(msg.sender == _accounts[order.owner], "NF:not owner");
        if (uint(order.stopPrice) == 0) {
            TransferHelper.safeTransferFrom(
                NEST_TOKEN_ADDRESS, 
                msg.sender, 
                FUTURES_PROXY_ADDRESS, 
                uint(order.balance) * 2 / 1000 * NEST_UNIT
            );
        }
        order.stopPrice = _encodeFloat48(stopPrice);
        _orders[index] = order;
    }

    /// @dev Append buy
    /// @param index Index of future
    /// @param amount Amount of paid NEST
    function add2(uint index, uint amount) external payable override {
        // TODO: Test gas of 50 ether / NEST_UNIT and 500000
        require(amount >= 50 ether / NEST_UNIT, "NF:at least 50 NEST");

        // 1. Transfer NEST from user
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, NEST_VAULT_ADDRESS, amount * NEST_UNIT);

        // 1. Load the order
        Order memory order = _orders[index];
        require(_accounts[uint(order.owner)] == msg.sender, "NF:not owner");
        bool orientation = order.orientation;

        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        TokenConfig memory tokenConfig = _tokenConfigs[uint(order.tokenIndex)];
        uint oraclePrice = _queryPrice(amount * NEST_UNIT, tokenConfig, orientation);

        // 3. Merger price
        uint basePrice = _decodeFloat(order.basePrice);
        uint balance = uint(order.balance);
        uint newBalance = balance + amount;
        require(balance > 0, "NF:order cleared");
        require(newBalance < 0x1000000000000, "NF:balance too big");
        uint newPrice = newBalance * oraclePrice * basePrice / (
            basePrice * amount + (balance << 64) * oraclePrice / _expMiuT(
                uint(orientation ? tokenConfig.miuLong : tokenConfig.miuShort), 
                uint(order.baseBlock)
            )
        );

        // 4. Update order
        order.balance = uint48(newBalance);
        order.basePrice = _encodeFloat(newPrice);
        order.baseBlock = uint32(block.number);
        _orders[index] = order;

        // 5. Emit event
        emit Buy2(index, amount, msg.sender);
    }

    /// @dev Sell order
    /// @param index Index of order
    function sell2(uint index) external payable override {
        // 1. Load the order
        Order memory order = _orders[index];
        address owner = _accounts[uint(order.owner)];
        require(msg.sender == owner || msg.sender == FUTURES_PROXY_ADDRESS, "NF:not owner");
        bool orientation = order.orientation;

        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        TokenConfig memory tokenConfig = _tokenConfigs[uint(order.tokenIndex)];
        uint oraclePrice = _queryPrice(0, tokenConfig, !orientation);

        // 3. Update account
        uint balance = uint(order.balance);
        order.balance = uint48(0);
        _orders[index] = order;

        // 4. Transfer NEST to user
        uint value = _balanceOf(
            // tokenConfig
            tokenConfig,
            // balance
            balance * NEST_UNIT, 
            // basePrice
            _decodeFloat(order.basePrice), 
            // baseBlock
            uint(order.baseBlock),
            // oraclePrice
            oraclePrice, 
            // ORIENTATION
            orientation, 
            // LEVER
            uint(order.lever)
        );

        INestVault(NEST_VAULT_ADDRESS).transferTo(owner, value);

        // 5. Emit event
        emit Sell2(index, balance, owner, value);
    }

    /// @dev Liquidate order
    /// @param indices Target order indices
    function liquidate2(uint[] calldata indices) external payable override {
        TokenConfig memory tokenConfig;
        uint oraclePrice = 0;
        uint tokenIndex = 0;
        bool orientation = false;

        // 1. Loop and settle
        uint reward = 0;
        for (uint i = indices.length; i > 0;) {
            uint index = indices[--i];
            Order memory order = _orders[index];

            if (oraclePrice == 0) {
                // 2. Query oracle price
                // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
                // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
                // When merger, s0 use recorded price, s1 use corrected by k
                tokenIndex = uint(order.tokenIndex);
                orientation = order.orientation;
                tokenConfig = _tokenConfigs[tokenIndex];
                oraclePrice = _queryPrice(0, tokenConfig, !orientation);
                require(oraclePrice > 0, "NF:price error");
            } else {
                require(tokenIndex == uint(order.tokenIndex), "NF:tokenIndex error");
                require(orientation == order.orientation, "NF:orientation error");
            }

            uint lever = uint(order.lever);
            uint balance = uint(order.balance) * NEST_UNIT;

            if (lever > 1 && balance > 0) {
                // 3. Update account
                uint value = _balanceOf(
                    // tokenConfig
                    tokenConfig,
                    // balance
                    balance, 
                    // basePrice
                    _decodeFloat(order.basePrice), 
                    // baseBlock
                    uint(order.baseBlock),
                    // oraclePrice
                    oraclePrice, 
                    // ORIENTATION
                    orientation, 
                    // LEVER
                    lever
                );

                // 4. Liquidate logic
                // lever is great than 1, and balance less than a regular value, can be liquidated
                // the regular value is: Max(balance * lever * 2%, MIN_VALUE)
                if (value < MIN_VALUE || value < balance * lever / 50) {
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

    /// @dev Buy from NestFuturesPRoxy
    /// @param tokenIndex Index of token
    /// @param lever Lever of order
    /// @param orientation true: call, false: put
    /// @param amount Amount of paid NEST, 4 decimals
    /// @param stopPrice Stop price for stop order
    function proxyBuy2(
        address owner, 
        uint16 tokenIndex, 
        uint8 lever, 
        bool orientation, 
        uint48 amount,
        uint48 stopPrice
    ) external payable onlyProxy {

        //require(amount >= 50 ether, "NF:at least 50 NEST");

        // 1. Transfer NEST from user
        // TODO: Transfer NEST token
        //TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, NEST_VAULT_ADDRESS, amount);

        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        TokenConfig memory tokenConfig = _tokenConfigs[tokenIndex];
        uint oraclePrice = _queryPrice(uint(amount) * NEST_UNIT, tokenConfig, orientation);

        // 3. Emit event
        emit Buy2(_orders.length, uint(amount), owner);

        // 4. Create order
        _orders.push(Order(
            // owner
            uint32(_addressIndex(owner)),
            // basePrice
            _encodeFloat(oraclePrice),
            // balance
            amount,
            // baseBlock
            uint32(block.number),
            // tokenIndex
            tokenIndex,
            // lever
            lever,
            // orientation
            orientation,
            // stopPrice
            stopPrice
        ));
    }

    /// @dev Gets the index number of the specified address. If it does not exist, register
    /// @param addr Destination address
    /// @return The index number of the specified address
    function _addressIndex(address addr) private returns (uint) {
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
            _decodeFloat(order.basePrice),
            // stopPrice
            _decodeFloat(order.stopPrice)
        );
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
}
