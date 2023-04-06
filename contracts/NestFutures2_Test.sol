// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestVault.sol";
import "./interfaces/INestFutures3.sol";
import "./interfaces/INestFutures2.sol";

import "./NestFutures2.sol";

/// @dev Nest futures without merger
contract NestFutures2_Test is NestFutures2 {

    // // TODO:
    // address DIRECT_POSTER;
    // /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    // ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    // /// @param newGovernance INestGovernance implementation contract address
    // function update(address newGovernance) public virtual override {
    //     super.update(newGovernance);
    //     DIRECT_POSTER = INestGovernance(newGovernance).checkAddress("nest.app.directPoster");
    // }

    // Initialize account array, execute once
    function init() external {
        require(_accounts.length == 0, "NF:initialized");
        _accounts.push();
    }

    /// @dev Direct post price
    /// @param period Term of validity
    // @param equivalents Price array, one to one with pairs
    function directPost(uint period, uint[3] calldata /*equivalents*/) external {
        require(msg.sender == DIRECT_POSTER, "NFWP:not directPoster");
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
        _prices.push(period);
    }
    
    /// @dev Register token configuration
    /// @param tokenAddress Target token address, 0 means eth
    /// @param tokenConfig token configuration
    function register(address tokenAddress, TokenConfig calldata tokenConfig) external onlyGovernance {
        // Get registered tokenIndex by tokenAddress
        uint index = _tokenMapping[tokenAddress];
        
        // index == 0 means token not registered, add
        if (index == 0) {
            // Add tokenConfig to array
            _tokenConfigs.push(tokenConfig);
            // Record index + 1
            index = _tokenConfigs.length;
            require(index < 0x10000, "NF:too much tokenConfigs");
            _tokenMapping[tokenAddress] = index;
        } else {
            // Update tokenConfig
            _tokenConfigs[index - 1] = tokenConfig;
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
    ) external payable {
        require(amount > CommonLib.FUTURES_NEST_LB && amount < 0x1000000000000, "NF:amount invalid");
        require(lever > 0 && lever < 21, "NF:lever not allowed");

        // 1. Emit event
        emit Buy2(_orders.length, amount, msg.sender);

        // 2. Create order
        _orders.push(Order(
            // owner
            uint32(_addressIndex(msg.sender)),
            // basePrice
            // Query oraclePrice
            CommonLib.encodeFloat56(_queryPrice_old(_tokenConfigs[tokenIndex])),
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
            stopPrice > 0 ? CommonLib.encodeFloat56(stopPrice) : uint56(0)
        ));

        // 4. Transfer NEST from user
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_VAULT_ADDRESS, 
            amount * CommonLib.NEST_UNIT * (1 ether + FEE_RATE * uint(lever)) / 1 ether
        );
    }

    /// @dev Append buy
    /// @param index Index of future
    /// @param amount Amount of paid NEST
    function add2(uint index, uint amount) external payable {
        require(amount > CommonLib.FUTURES_NEST_LB, "NF:amount invalid");

        // 1. Load the order
        Order memory order = _orders[index];

        uint basePrice = CommonLib.decodeFloat(order.basePrice);
        uint balance = uint(order.balance);
        uint newBalance = balance + amount;

        require(balance > 0, "NF:order cleared");
        require(newBalance < 0x1000000000000, "NF:balance too big");
        require(msg.sender == _accounts[uint(order.owner)], "NF:not owner");

        // 2. Query oracle price
        TokenConfig memory tokenConfig = _tokenConfigs[uint(order.tokenIndex)];
        uint oraclePrice = _queryPrice_old(tokenConfig);

        // 3. Update order
        // Merger price
        order.basePrice = CommonLib.encodeFloat56(newBalance * oraclePrice * basePrice / (
            basePrice * amount + (balance << 64) * oraclePrice / _expMiuT(
                uint(order.orientation ? tokenConfig.miuLong : tokenConfig.miuShort), 
                uint(order.baseBlock)
            )
        ));
        order.balance = uint48(newBalance);
        order.baseBlock = uint32(block.number);
        _orders[index] = order;

        // 4. Transfer NEST from user
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            NEST_VAULT_ADDRESS, 
            amount * CommonLib.NEST_UNIT * (1 ether + FEE_RATE * uint(order.lever)) / 1 ether
        );

        // 5. Emit event
        emit Buy2(index, amount, msg.sender);
    }

    // Query price
    function _queryPrice_old(TokenConfig memory tokenConfig) internal view returns (uint oraclePrice) {
        // Query price from oracle
        (uint period, uint height, uint price) = _decodePrice(_prices[_prices.length - 1], uint(tokenConfig.pairIndex));
        require(block.number < height + period, "NFWP:price expired");
        oraclePrice = CommonLib.toUSDTPrice(price);
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
        uint56 stopPrice
    ) external payable onlyProxy {
        // 1. Emit event
        emit Buy2(_orders.length, uint(amount), owner);

        // 2. Create order
        _orders.push(Order(
            // owner
            uint32(_addressIndex(owner)),
            // basePrice
            // Query oraclePrice
            CommonLib.encodeFloat56(_queryPrice(tokenIndex)),
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
}
