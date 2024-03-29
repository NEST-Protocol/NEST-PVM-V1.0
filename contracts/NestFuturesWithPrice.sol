// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/CommonLib.sol";

import "./interfaces/INestFuturesWithPrice.sol";
import "./interfaces/INestVault.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Futures
contract NestFuturesWithPrice is NestFrequentlyUsed, INestFuturesWithPrice {

    /// @dev Future information
    struct FutureInfo {
        // Target token address
        address tokenAddress; 
        // Lever of future
        uint32 lever;
        // true: call, false: put
        bool orientation;

        // Token index in _tokenConfigs
        uint16 tokenIndex;
        
        // Account mapping
        mapping(address=>Account) accounts;
    }

    /// @dev Account information
    struct Account {
        // Amount of margin
        uint128 balance;
        // Base price
        uint64 basePrice;
        // Base block
        uint32 baseBlock;
    }

    // Token configuration
    struct TokenConfig {
        // The channelId for call nest price
        uint16 channelId;
        // The pairIndex for call nest price
        uint16 pairIndex;

        // SigmaSQ for token
        uint64 sigmaSQ;
        // MIU_LONG for token
        uint64 miuLong;
        // MIU_SHORT for token
        uint64 miuShort;
    }

    // Mapping from composite key to future index
    mapping(uint=>uint) _futureMapping;

    // Future array, element of 0 is place holder
    FutureInfo[] _futures;

    // token to index mapping, address=>tokenConfigIndex + 1
    mapping(address=>uint) _tokenMapping;

    // Token configs
    TokenConfig[] _tokenConfigs;

    // price array, period(16)|height(48)|price3(64)|price2(64)|price1(64)
    uint[] _prices;

    constructor() {
    }

    // TODO: Can remove if there is an exists proxy contract
    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) public override {
        super.initialize(governance);
        _futures.push();
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

    /// @dev List prices
    /// @param pairIndex index of token in channel 0 on NEST Oracle
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return priceArray List of prices, i * 3 + 0 means period, i * 3 + 1 means height, i * 3 + 2 means price
    function listPrice(
        uint pairIndex,
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (uint[] memory priceArray) {
        // Load prices
        uint[] storage prices = _prices;
        // Create result array
        priceArray = new uint[](count * 3);
        uint length = prices.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                (priceArray[i], priceArray[i + 1], priceArray[i + 2]) = _decodePrice(prices[--index], pairIndex);
                i += 3;
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
                (priceArray[i], priceArray[i + 1], priceArray[i + 2]) = _decodePrice(prices[index++], pairIndex);
                i += 3;
            }
        }
    }

    // /// @dev Find the price at block number
    // /// @param pairIndex index of token in channel 0 on NEST Oracle
    // /// @param height Destination block number
    // /// @return blockNumber The block number of price
    // /// @return price The token price. (1eth equivalent to (price) token)
    // function findPrice(
    //     uint pairIndex,
    //     uint height
    // ) external view returns (uint blockNumber, uint price) {

    //     uint length = _prices.length;
    //     uint index = 0;
    //     uint sheetHeight;
    //     {
    //         // If there is no sheet in this channel, length is 0, length - 1 will overflow,
    //         uint right = length - 1;
    //         uint left = 0;
    //         // Find the index use Binary Search
    //         while (left < right) {

    //             index = (left + right) >> 1;
    //             sheetHeight = (_prices[index] >> 192) & 0xFFFFFFFFFFFF;
    //             if (height > sheetHeight) {
    //                 left = ++index;
    //             } else if (height < sheetHeight) {
    //                 // When index = 0, this statement will have an underflow exception, which usually 
    //                 // indicates that the effective block height passed during the call is lower than 
    //                 // the block height of the first quotation
    //                 right = --index;
    //             } else {
    //                 break;
    //             }
    //         }
    //     }

    //     while (((_prices[index] >> 192) & 0xFFFFFFFFFFFF) > height) {
    //         --index;
    //     }

    //     (,blockNumber, price) = _decodePrice(_prices[index], pairIndex);
    // }

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

    /// @dev Returns the current value of target address in the specified future
    /// @param index Index of future
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    /// @param addr Target address
    function balanceOf(uint index, uint oraclePrice, address addr) external view override returns (uint) {
        FutureInfo storage fi = _futures[index];
        Account memory account = fi.accounts[addr];
        return _balanceOf(
            _tokenConfigs[fi.tokenIndex],
            uint(account.balance), 
            CommonLib.decodeFloat(account.basePrice), 
            uint(account.baseBlock),
            oraclePrice, 
            fi.orientation, 
            uint(fi.lever)
        );
    }

    /// @dev Find the futures of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given owner address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return futureArray Matched futures
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view override returns (FutureView[] memory futureArray) {
        futureArray = new FutureView[](count);
        // Calculate search region
        FutureInfo[] storage futures = _futures;

        // Loop from start to end
        uint end = 0;
        // start is 0 means Loop from the last item
        if (start == 0) {
            start = futures.length;
        }
        // start > maxFindCount, so end is not 0
        if (start > maxFindCount) {
            end = start - maxFindCount;
        }
        
        // Loop lookup to write qualified records to the buffer
        for (uint index = 0; index < count && start > end;) {
            FutureInfo storage fi = futures[--start];
            if (uint(fi.accounts[owner].balance) > 0) {
                futureArray[index++] = _toFutureView(fi, start, owner);
            }
        }
    }

    /// @dev List futures
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of futures
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (FutureView[] memory futureArray) {
        // Load futures
        FutureInfo[] storage futures = _futures;
        // Create result array
        futureArray = new FutureView[](count);
        uint length = futures.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                FutureInfo storage fi = futures[--index];
                futureArray[i++] = _toFutureView(fi, index, msg.sender);
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
                futureArray[i++] = _toFutureView(futures[index], index, msg.sender);
                ++index;
            }
        }
    }

    /// @dev Obtain the number of futures that have been created
    /// @return Number of futures created
    function getFutureCount() external view override returns (uint) {
        return _futures.length;
    }

    /// @dev Get information of future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @return Information of future
    function getFutureInfo(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view override returns (FutureView memory) {
        uint index = _futureMapping[_getKey(tokenAddress, lever, orientation)];
        return _toFutureView(_futures[index], index, msg.sender);
    }

    // @dev Buy future
    // @param tokenAddress Target token address, 0 means eth
    // @param lever Lever of future
    // @param orientation true: call, false: put
    // @param nestAmount Amount of paid NEST
    function buy(
        address,// tokenAddress,
        uint,// lever,
        bool,// orientation,
        uint// nestAmount
    ) external payable override {
        revert("NF:please use buy2");
        // return buyDirect(_futureMapping[_getKey(tokenAddress, lever, orientation)], nestAmount);
    }

    // @dev Buy future direct
    // @param index Index of future
    // @param nestAmount Amount of paid NEST
    function buyDirect(uint /*index*/, uint /*nestAmount*/) public payable override {
        revert("NF:please use buy2");
        // require(index != 0, "NF:not exist");
        // require(nestAmount >= 50 ether, "NF:at least 50 NEST");

        // // 1. Transfer NEST from user
        // TransferHelper.safeTransferFrom(
        //     NEST_TOKEN_ADDRESS, 
        //     msg.sender, 
        //     NEST_VAULT_ADDRESS, 
        //     nestAmount * (1 ether + CommonLib.FEE_RATE) / 1 ether
        // );

        // FutureInfo storage fi = _futures[index];
        // bool orientation = fi.orientation;
        
        // // 2. Query oracle price
        // TokenConfig memory tokenConfig = _tokenConfigs[uint(fi.tokenIndex)];
        // uint oraclePrice = _queryPrice(tokenConfig);

        // // 3. Merger price
        // Account memory account = fi.accounts[msg.sender];
        // uint basePrice = CommonLib.decodeFloat(account.basePrice);
        // uint balance = uint(account.balance);
        // uint newPrice = oraclePrice;
        // if (uint(account.baseBlock) > 0) {
        //     newPrice = (balance + nestAmount) * oraclePrice * basePrice / (
        //         basePrice * nestAmount + (balance << 64) * oraclePrice / _expMiuT(
        //             uint(orientation ? tokenConfig.miuLong : tokenConfig.miuShort), 
        //             uint(account.baseBlock)
        //         )
        //     );
        // }
        
        // // 4. Update account
        // account.balance = _toUInt128(balance + nestAmount);
        // account.basePrice = CommonLib.encodeFloat64(newPrice);
        // account.baseBlock = uint32(block.number);
        // fi.accounts[msg.sender] = account;

        // // emit Buy event
        // emit Buy(index, nestAmount, msg.sender);
    }

    /// @dev Sell future
    /// @param index Index of future
    /// @param amount Amount to sell
    function sell(uint index, uint amount) external payable override {
        require(index != 0, "NF:not exist");
        
        // 1. Load the future
        FutureInfo storage fi = _futures[index];
        uint lever = uint(fi.lever);

        // 2. Query oracle price
        TokenConfig memory tokenConfig = _tokenConfigs[uint(fi.tokenIndex)];
        uint oraclePrice = _queryPrice(tokenConfig);

        // 3. Update account
        Account memory account = fi.accounts[msg.sender];
        uint basePrice = CommonLib.decodeFloat(uint(account.basePrice));
        account.balance -= _toUInt128(amount);
        fi.accounts[msg.sender] = account;

        // 4. Transfer NEST to user
        uint value = _balanceOf(
            tokenConfig,
            amount, 
            basePrice, 
            uint(account.baseBlock),
            oraclePrice, 
            fi.orientation, 
            lever
        );

        uint fee = amount * lever * oraclePrice / basePrice * CommonLib.FEE_RATE / 1 ether;
        // If value grater than fee, deduct and transfer NEST to owner
        if (value > fee) {
            INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, value - fee);
        } 

        // emit Sell event
        emit Sell(index, amount, msg.sender, value);
    }

    /// @dev Settle future
    /// @param index Index of future
    /// @param addresses Target addresses
    function settle(uint index, address[] calldata addresses) external payable override {

        require(index != 0, "NF:not exist");

        // 1. Load the future
        FutureInfo storage fi = _futures[index];
        uint lever = uint(fi.lever);
        require(lever > 1, "NF:lever must greater than 1");

        bool orientation = fi.orientation;
            
        // 2. Query oracle price
        TokenConfig memory tokenConfig = _tokenConfigs[uint(fi.tokenIndex)];
        uint oraclePrice = _queryPrice(tokenConfig);

        // 3. Loop and settle
        uint reward = 0;
        for (uint i = addresses.length; i > 0;) {
            address acc = addresses[--i];

            // 4. Update account
            Account memory account = fi.accounts[acc];
            if (uint(account.balance) > 0) {
                uint balance = _balanceOf(
                    tokenConfig,
                    uint(account.balance), 
                    CommonLib.decodeFloat(account.basePrice), 
                    uint(account.baseBlock),
                    oraclePrice, 
                    orientation, 
                    lever
                );

                // 5. Settle logic
                // lever is great than 1, and balance less than a regular value, can be liquidated
                // the regular value is: Max(balance * lever * 2%, MIN_VALUE)
                if (balance < CommonLib.MIN_FUTURE_VALUE || balance < uint(account.balance) * lever / 50) {
                    fi.accounts[acc] = Account(uint128(0), uint64(0), uint32(0));
                    reward += balance;
                    emit Settle(index, acc, msg.sender, balance);
                }
            }
        }

        // 6. Transfer NEST to user
        if (reward > 0) {
            INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, reward);
        }
    }

    // Compose key by tokenAddress, lever and orientation
    function _getKey(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) private pure returns (uint) {
        //return keccak256(abi.encodePacked(tokenAddress, lever, orientation));
        require(lever < 0x100000000, "NF:lever too large");
        return (uint(uint160(tokenAddress)) << 96) | (lever << 8) | (orientation ? 1 : 0);
    }
    
    // Query price
    function _queryPrice(TokenConfig memory tokenConfig) internal view returns (uint oraclePrice) {
        // Query price from oracle
        (uint period, uint height, uint price) = _decodePrice(_prices[_prices.length - 1], uint(tokenConfig.pairIndex));
        require(block.number < height + period, "NFWP:price expired");
        oraclePrice = CommonLib.toUSDTPrice(price);
    }

    // Convert uint to uint128
    function _toUInt128(uint value) private pure returns (uint128) {
        require(value < 0x100000000000000000000000000000000, "NF:can't convert to uint128");
        return uint128(value);
    }

    // Convert uint to int128
    function _toInt128(uint v) private pure returns (int128) {
        require(v < 0x80000000000000000000000000000000, "NF:can't convert to int128");
        return int128(int(v));
    }

    // Convert int128 to uint
    function _toUInt(int128 v) private pure returns (uint) {
        require(v >= 0, "NF:can't convert to uint");
        return uint(int(v));
    }
    
    // Calculate net worth
    function _balanceOf(
        TokenConfig memory tokenConfig,
        uint balance,
        uint basePrice,
        uint baseBlock,
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
                        / _expMiuT(uint(tokenConfig.miuLong), baseBlock);
                right = balance * LEVER;
            } 
            // Put
            else {
                left = balance * (1 + LEVER);
                right = (LEVER << 64) * balance * oraclePrice / basePrice 
                        / _expMiuT(uint(tokenConfig.miuShort), baseBlock);
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
    function _expMiuT(uint miu, uint baseBlock) internal view returns (uint) {
        // return _toUInt(ABDKMath64x64.exp(
        //     _toInt128((orientation ? MIU_LONG : MIU_SHORT) * (block.number - baseBlock) * BLOCK_TIME)
        // ));

        // Using approximate algorithm: x*(1+rt)
        return miu * (block.number - baseBlock) * CommonLib.BLOCK_TIME / 1000 + 0x10000000000000000;
    }

    // Convert FutureInfo to FutureView
    function _toFutureView(FutureInfo storage fi, uint index, address owner) private view returns (FutureView memory) {
        Account memory account = fi.accounts[owner];
        return FutureView(
            index,
            fi.tokenAddress,
            uint(fi.lever),
            fi.orientation,
            uint(account.balance),
            CommonLib.decodeFloat(account.basePrice),
            uint(account.baseBlock)
        );
    }

    // Decode composed price
    function _decodePrice(uint rawPrice, uint pairIndex) private pure returns (uint period, uint height, uint price) {
        return (
            rawPrice >> 240,
            (rawPrice >> 192) & 0xFFFFFFFFFFFF,
            CommonLib.decodeFloat(uint64(rawPrice >> (pairIndex << 6)))
        );
    }
}
