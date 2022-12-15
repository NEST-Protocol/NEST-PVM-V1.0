// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestFuturesWithPrice.sol";
import "./interfaces/INestVault.sol";
import "./interfaces/INestFutures2.sol";

import "./custom/ChainParameter.sol";

import "./NestFuturesWithPrice.sol";

/// @dev Futures
contract NestFutures2 is NestFuturesWithPrice, INestFutures2 {

    // Future array, element of 0 is place holder
    Future2[] _future2s;

    // Registered account address mapping
    mapping(address=>uint) _accountMapping;

    // Registered accounts
    address[] _accounts;

    constructor() {
    }

    /// @dev Returns the current value of target address in the specified future
    /// @param index Index of future
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    function balanceOf2(uint index, uint oraclePrice) external view override returns (uint) {
        Future2 memory future = _future2s[index];
        return _balanceOf(
            _tokenConfigs[uint(future.tokenIndex)],
            _decodeFloat(future.balance), 
            _decodeFloat(future.basePrice), 
            uint(future.baseBlock),
            oraclePrice, 
            future.orientation, 
            uint(future.lever)
        );
    }

    /// @dev Find the futures of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given owner address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return futureArray Matched futures
    function find2(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view override returns (Future2[] memory futureArray) {
        futureArray = new Future2[](count);
        // Calculate search region
        Future2[] storage futures = _future2s;

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
        uint ownerIndex = _accountMapping[owner];
        for (uint index = 0; index < count && start > end;) {
            Future2 memory fi = futures[--start];
            if (_decodeFloat(fi.balance) > 0 && uint(fi.owner) == ownerIndex) {
                futureArray[index++] = fi;
            }
        }
    }

    /// @dev List futures
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of futures
    function list2(
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (Future2[] memory futureArray) {
        // Load futures
        Future2[] storage futures = _future2s;
        // Create result array
        futureArray = new Future2[](count);
        uint length = futures.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                Future2 memory fi = futures[--index];
                futureArray[i++] = fi;
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
                futureArray[i++] = futures[index];
                ++index;
            }
        }
    }

    /// @dev Gets the index number of the specified address. If it does not exist, register
    /// @param addr Destination address
    /// @return The index number of the specified address
    function _addressIndex(address addr) private returns (uint) {

        // TODO: no first address
        uint index = _accountMapping[addr];
        if (index == 0) {
            // If it exceeds the maximum number that 32 bits can store, you can't continue to register a new account.
            // If you need to support a new account, you need to update the contract
            require((_accountMapping[addr] = index = _accounts.length) < 0x100000000, "NO:!accounts");
            _accounts.push(addr);
        }

        return index;
    }

    /// @dev Buy future direct
    /// @param tokenIndex Index of token
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @param nestAmount Amount of paid NEST
    function buy2(uint16 tokenIndex, uint8 lever, bool orientation, uint nestAmount) external payable override {

        require(nestAmount >= 50 ether, "NF:at least 50 NEST");

        // 1. Transfer NEST from user
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, NEST_VAULT_ADDRESS, nestAmount);

        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        TokenConfig memory tokenConfig = _tokenConfigs[tokenIndex];
        uint oraclePrice = _queryPrice(nestAmount, tokenConfig, orientation);

        // 3. Merger price
        // TODO: Emit event

        _future2s.push(Future2(
            uint32(_addressIndex(msg.sender)),
            _encodeFloat(oraclePrice),
            _encodeFloat(nestAmount),
            uint32(block.number),
            tokenIndex,
            lever,
            orientation
        ));

        // emit Buy event
        // emit Buy(index, nestAmount, msg.sender);
    }

    /// @dev Sell future
    /// @param index Index of future
    /// @param amount Amount to sell
    function sell2(uint index, uint amount) external payable override {

        // 1. Load the future
        Future2 memory future = _future2s[index];
        bool orientation = future.orientation;

        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        TokenConfig memory tokenConfig = _tokenConfigs[uint(future.tokenIndex)];
        uint oraclePrice = _queryPrice(0, tokenConfig, !orientation);

        // 3. Update account
        future.balance = _encodeFloat(_decodeFloat(future.balance) - amount);
        _future2s[index] = future;

        // 4. Transfer NEST to user
        uint value = _balanceOf(
            tokenConfig,
            amount, 
            _decodeFloat(future.basePrice), 
            uint(future.baseBlock),
            oraclePrice, 
            orientation, 
            uint(future.lever)
        );
        INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, value);

        // TODO: Emit event
        // emit Sell event
        //emit Sell(index, amount, msg.sender, value);
    }

    /// @dev Settle future
    /// @param indices Target future indices
    function liquidate2(uint[] calldata indices) external payable override {

        // 1. Load the future

        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        TokenConfig memory tokenConfig;
        uint oraclePrice = 0;
        uint tokenIndex = 0;
        bool orientation = false;

        // 3. Loop and settle
        uint reward = 0;
        for (uint i = indices.length; i > 0;) {
            Future2 memory future = _future2s[indices[--i]];

            if (oraclePrice == 0) {
                tokenIndex = uint(future.tokenIndex);
                orientation = future.orientation;
                tokenConfig = _tokenConfigs[tokenIndex];
                oraclePrice = _queryPrice(0, tokenConfig, !orientation);
                require(oraclePrice > 0, "NF:price error");
            } else {
                require(tokenIndex == uint(future.tokenIndex), "NF:tokenIndex error");
                require(orientation == future.orientation, "NF:orientation error");
            }

            uint lever = uint(future.lever);
            uint balance = _decodeFloat(future.balance);

            if (lever > 1 && balance > 0) {
                // 4. Update account
                uint remain = _balanceOf(
                    tokenConfig,
                    balance, 
                    _decodeFloat(future.basePrice), 
                    uint(future.baseBlock),
                    oraclePrice, 
                    orientation, 
                    lever
                );

                // 5. Settle logic
                // lever is great than 1, and balance less than a regular value, can be liquidated
                // the regular value is: Max(balance * lever * 2%, MIN_VALUE)
                uint minValue = balance * lever / 50;
                if (remain < (minValue < MIN_VALUE ? MIN_VALUE : minValue)) {
                    future.balance = uint64(0);
                    future.baseBlock = uint32(0);
                    _future2s[indices[i]] = future;
                    reward += remain;
                    // TODO: Emit event
                    //emit Settle(index, acc, msg.sender, balance);
                }
            }
        }

        // 6. Transfer NEST to user
        if (reward > 0) {
            //DCU(DCU_TOKEN_ADDRESS).mint(msg.sender, reward);
            INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, reward);
        }
    }
}
