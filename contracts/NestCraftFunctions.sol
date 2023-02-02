// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/ABDKMath64x64.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/INestFuturesWithPrice.sol";
import "./interfaces/INestPVMFunction.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev NestCraft functions
contract NestCraftFunctions is NestFrequentlyUsed, INestPVMFunction {

    // TODO: Restrict linear relationship
    // TODO: When λ is negative, means short(put), use short(put) μ
    // TODO: To confirm if payment value for stopping time order is different
    // TODO: Design a mechanism to ensure the argument of martingale function must be constant
    // 
    
    uint constant   DECIMALS      = 1 ether;
    uint constant   OP_BUY        = 0;
    uint constant   OP_SELL       = 1;
     int constant   BLOCK_TIME    = 3000;

    
    event Buy(string expr, address owner, uint openBlock, uint shares, uint index);

    struct TokenConfig {
        // The pairIndex for call nest price
        uint16 pairIndex;

        // SigmaSQ for token
        int64 sigmaSQ;
        // MIU for token
        int64 miu;
    }

    /// @dev PVM Order data structure
    struct CraftOrder {
        address owner;
        uint32 openBlock;
        uint32 stopBlock;
        uint32 shares;
        string expr;
    }

    TokenConfig[] _tokenConfigs;

    // PVM Order array
    CraftOrder[] _orders;

    // Identifier map
    mapping(uint=>uint) _identifierMap;

    // TODO: Only for test
    address NEST_FUTURES_ADDRESS;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        NEST_FUTURES_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.futures");
    }


    /// @dev Find the mint requests of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return orderArray Matched CraftOrder array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (CraftOrder[] memory orderArray) {
        orderArray = new CraftOrder[](count);
        // Calculate search region
        CraftOrder[] storage orders = _orders;
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
            CraftOrder memory order = orders[--start];
            if (order.owner == owner) {
                orderArray[index++] = order;
            }
        }
    }

    /// @dev List mint requests
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of CraftOrder
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (CraftOrder[] memory orderArray) {
        // Load mint requests
        CraftOrder[] storage orders = _orders;
        // Create result array
        orderArray = new CraftOrder[](count);
        uint length = orders.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                orderArray[i++] = orders[--index];
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
                orderArray[i++] = orders[index++];
            }
        }
    }

    /// @dev Estimate the value of expression
    /// @param expr Target expression
    /// @return value Estimated value
    function estimate(string memory expr) external view returns (int value) {
        value = evaluate(_identifierMap, expr, 0);
    }

    function evaluate(
        mapping(uint=>uint) storage context,
        string memory expr, 
        uint oi
    ) internal virtual view returns (int value) { } 

    // TODO: Make expression as a product and can reuse?

    /// @dev Buy a product
    /// @param expr Target expression
    function buy(string memory expr) external {
        
        uint index = _orders.length;

        emit Buy(expr, msg.sender, block.number, 1, index);
        _orders.push(CraftOrder(msg.sender, uint32(block.number), uint32(0), uint32(1), expr));

        int value = evaluate(_identifierMap, expr, (OP_BUY << 248) | index);
        require(value > 0, "PVM:expression value must > 0");
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(value));
    }

    /// @dev Sell a order
    /// @param index Index of target order
    function sell(uint index) external {
        CraftOrder memory order = _orders[index];
        require(msg.sender == order.owner, "PVM:must owner");

        int value = evaluate(_identifierMap, order.expr, (OP_SELL << 248) | index);

        value = value * int(uint(order.shares));
        require(value > 0, "PVM:no balance");
        _orders[index].shares = uint32(0);
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, msg.sender, uint(value));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Martingale functions

    // Context: μ, t0, 
    // ctx: operation(8)|reserved(216)|orderIndex(32)
    function m1(uint ctx, int pairIndex) public view returns (int v) {
        uint operation = ctx >> 248;
        int St = op(pairIndex);
        
        // Buy
        if (operation == OP_BUY) {
            v = St;
        } 
        // Sell
        else if (operation == OP_SELL) {
            // TODO: Use integer pairIndex. (Use variable to instead of method?)
            // TODO: Design a mechanism to improve transmit miu, sigmaSQ and t0
            TokenConfig memory tokenConfig = _tokenConfigs[uint(pairIndex / int(DECIMALS))];
            CraftOrder memory order = _orders[ctx & 0xFFFFFFFF];
            int miu = int(tokenConfig.miu);
            int t0 = int(uint(order.openBlock));
            int t = (int(block.number) - t0) * BLOCK_TIME / 1000 * int(DECIMALS);

            v = St * int(DECIMALS) / exp(miu * t / int(DECIMALS));
        } 
        // Not support
        else {
            revert("PVM:operation error");
        }
    }

    function m2(uint ctx, int pairIndex) public view returns (int v) {
        uint operation = ctx >> 248;
        int St = op(pairIndex);

        // Buy
        if (operation == OP_BUY) {
            v = St * St / int(DECIMALS);
        } 
        // Sell
        else if (operation == OP_SELL) {
            TokenConfig memory tokenConfig = _tokenConfigs[uint(pairIndex / int(DECIMALS))];
            CraftOrder memory order = _orders[ctx & 0xFFFFFFFF];
            int sigmaSQ = int(tokenConfig.sigmaSQ);
            int miu = int(tokenConfig.miu);
            int t0 = int(uint(order.openBlock));
            int t = (int(block.number) - t0) * BLOCK_TIME / 1000 * int(DECIMALS);

            v = St * St / exp((miu * 2 + sigmaSQ) * t / int(DECIMALS));
        }
        // Not support
        else {
            revert("PVM:operation error");
        }
    }

    function m3(uint ctx, int pairIndex) public view returns (int v) {
        uint operation = ctx >> 248;
        int St = op(pairIndex);

        // Buy
        if (operation == OP_BUY) {
            v = int(DECIMALS) * int(DECIMALS) / St;
        } 
        // Sell
        else if (operation == OP_SELL) {
            TokenConfig memory tokenConfig = _tokenConfigs[uint(pairIndex / int(DECIMALS))];
            CraftOrder memory order = _orders[ctx & 0xFFFFFFFF];
            int sigmaSQ = int(tokenConfig.sigmaSQ);
            int miu = int(tokenConfig.miu);
            int t0 = int(uint(order.openBlock));
            int t = (int(block.number) - t0) * BLOCK_TIME / 1000 * int(DECIMALS);

            v = int(DECIMALS) * exp((miu - sigmaSQ) * t / int(DECIMALS)) / St;
        }
        // Not support
        else {
            revert("PVM:operation error");
        }
    }

    function m4(uint ctx, int pairIndex) public view returns (int v) {
        uint operation = ctx >> 248;
        int St = op(pairIndex);

        // Buy
        if (operation == OP_BUY) {
            v = sqrt(St);
        } 
        // Sell
        else if (operation == OP_SELL) {
            TokenConfig memory tokenConfig = _tokenConfigs[uint(pairIndex / int(DECIMALS))];
            CraftOrder memory order = _orders[ctx & 0xFFFFFFFF];
            int sigmaSQ = int(tokenConfig.sigmaSQ);
            int miu = int(tokenConfig.miu);
            int t0 = int(uint(order.openBlock));
            int t = (int(block.number) - t0) * BLOCK_TIME / 1000 * int(DECIMALS);

            v = sqrt(St) * exp((sigmaSQ / 8 - miu / 2) * t / int(DECIMALS)) / int(DECIMALS);
        }
        // Not support
        else {
            revert("PVM:operation error");
        }
    }

    function m5(uint ctx, int pairIndex) public view returns (int v) {
        uint operation = ctx >> 248;
        int St = op(pairIndex);

        // Buy
        if (operation == OP_BUY) {
            v = ln(St);
        } 
        // Sell
        else if (operation == OP_SELL) {
            TokenConfig memory tokenConfig = _tokenConfigs[uint(pairIndex / int(DECIMALS))];
            CraftOrder memory order = _orders[ctx & 0xFFFFFFFF];
            int sigmaSQ = int(tokenConfig.sigmaSQ);
            int miu = int(tokenConfig.miu);
            int t0 = int(uint(order.openBlock));
            int t = (int(block.number) - t0) * BLOCK_TIME / 1000 * int(DECIMALS);

            v = ln(St) - miu * t / int(DECIMALS) + sigmaSQ * t / int(DECIMALS) / 2;
        }
        // Not support
        else {
            revert("PVM:operation error");
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @dev Calculate value
    /// @dev byte array of arguments encoded by abi.encode()
    function calculate(bytes memory abiArgs) external view override returns (int) {
        uint v = abi.decode(abiArgs, (uint));
        uint pairIndex = (v & 0xFF) - 0x30;
        uint[] memory prices = INestFuturesWithPrice(NEST_FUTURES_ADDRESS).listPrice(pairIndex, 0, 1, 0);
        return int(prices[2]);
    }

    /// @dev block number
    /// @return Current block number, 18 decimals
    function bn() public view returns (int) {
        return int(block.number * DECIMALS);
    }

    /// @dev timestamp
    /// @return Current timestamp, 18 decimals
    function ts() public view returns (int) {
        return int(block.timestamp * DECIMALS);
    }

    // open block
    function ob() public pure returns (int) {
        revert("PVM:open block not implement");
    }

    /// @dev oracle price
    /// @param pairIndex pairIndex of target token, 18 decimals
    /// @return Latest oracle price, 18 decimals
    function op(int pairIndex) public view returns (int) {
        uint pi = uint(pairIndex) / DECIMALS;
        require(pi < 3, "PVM:pairIndex must < 3");
        return int(INestFuturesWithPrice(NEST_FUTURES_ADDRESS).listPrice(pi, 0, 1, 0)[2]);
    }

    /// @dev Calculate oracle average price
    /// @param pairIndex pairIndex of target token, 18 decimals
    /// @param count Indicate number of latest price, 18 decimals
    /// @return v average price, 18 decimals
    function oav(int pairIndex, int count) public view returns (int v) {
        unchecked {
            uint pi = uint(pairIndex) / DECIMALS;
            uint n = uint(count) / DECIMALS;
            require(pi < 3, "PVM:pairIndex must < 3");
            uint[] memory prices = INestFuturesWithPrice(NEST_FUTURES_ADDRESS).listPrice(pi, 0, n, 0);
            uint total = 0;
            for (uint i = 0; i < n; ++i) {
                require(prices[i * 3 + 1] > 0, "PVM:no such price");
                total += prices[i * 3 + 2];
            }

            v = int(total / n);
        }
    }

    /// @dev Calculate ln(v)
    /// @param v input value, 18 decimals
    /// @return log value by e, 18 decimals
    function ln(int v) public pure returns (int) {
        return _toDEC(ABDKMath64x64.ln(_toX64(v)));
    }

    /// @dev Pow based e
    /// @param v input value, 18 decimals
    /// @return pow based e value, 18 decimals
    function exp(int v) public pure returns (int) {
        return _toDEC(ABDKMath64x64.exp(_toX64(v)));
    }

    /// @dev floor value
    /// @param v input value, 18 decimals
    /// @return floor value, 18 decimals
    function flo(int v) public pure returns (int) {
        unchecked {
            if (v < 0) { return -cel(-v); }
            return v / int(DECIMALS) * int(DECIMALS);
        }
    }

    /// @dev ceil value
    /// @param v input value, 18 decimals
    /// @return ceil value, 18 decimals
    function cel(int v) public pure returns (int) {
        if (v < 0) { return -flo(-v); }
        return (v + int(DECIMALS - 1)) / int(DECIMALS) * int(DECIMALS);
    }

    /// @dev Calculate log, based on b
    /// @param a input value, 18 decimals
    /// @param b base value, 18 decimals
    /// @return v log value, 18 decimals
    function log(int a, int b) public pure returns (int v) {
        v = _toDEC(ABDKMath64x64.div(ABDKMath64x64.ln(_toX64(a)), ABDKMath64x64.ln(_toX64(b))));
    }

    /// Calculate a ** b
    /// @param a base value, 18 decimals
    /// @param b index value, 18 decimals
    /// @return v a ** b, 18 decimals
    function pow(int a, int b) public pure returns (int v) {
        if (b % int(DECIMALS) == 0) {
            // Negative exponent
            if (b < 0) {
                return int(DECIMALS) * int(DECIMALS) / pow(a, -b);
            }
            v = int(DECIMALS);
            while (b > 0) {
                v = v * a / int(DECIMALS);
                unchecked { b -= int(DECIMALS); }
            }
        } else {
            v = _toDEC(ABDKMath64x64.exp(ABDKMath64x64.mul(ABDKMath64x64.ln(_toX64(a)), _toX64(b))));
        }
    }

    /// Calculate sqrt(v)
    /// @param v input value, 18 decimals
    /// @return sqrt(v), 18 decimals
    function sqrt(int v) public pure returns (int) {
        return _toDEC(ABDKMath64x64.sqrt(_toX64(v)));
    }

    // Convert 18 decimals to 64 bits
    function _toX64(int v) internal pure returns (int128) {
        v = v * 0x10000000000000000 / int(DECIMALS);
        require(v >= type(int128).min && v <= type(int128).max, "PVM:overflow");
        return int128(v);
    }

    // Convert 64 bits to 18 decimals
    function _toDEC(int128 v) internal pure returns (int) {
        return int(v) * int(DECIMALS) >> 64;
    }
}
