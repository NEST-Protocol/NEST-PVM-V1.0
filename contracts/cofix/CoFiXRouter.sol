// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/ICoFiXRouter.sol";
import "./interfaces/ICoFiXPool.sol";

import "./CoFiXBase.sol";

/// @dev Router contract to interact with each CoFiXPair
contract CoFiXRouter is CoFiXBase, ICoFiXRouter {

    /* ******************************************************************************************
     * Note: In order to unify the authorization entry, all transferFrom operations are carried
     * out in the CoFiXRouter, and the CoFiXPool needs to be fixed, CoFiXRouter does trust and 
     * needs to be taken into account when calculating the pool balance before and after rollover
     * ******************************************************************************************/

    // Mapping for trade pairs. keccak256(token0, token1)=>pool
    mapping(bytes32=>address) _pairs;

    // Mapping for trade paths. keccak256(token0, token1) = > path
    mapping(bytes32=>address[]) _paths;

    /// @dev Create CoFiXRouter
    constructor () {
    }

    // Verify that the cutoff time has exceeded
    modifier ensure(uint deadline) {
        require(block.timestamp <= deadline, "CoFiXRouter: EXPIRED");
        _;
    }

    /// @dev Register trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @param pool Pool for the trade pair
    function registerPair(address token0, address token1, address pool) public override onlyGovernance {
        _pairs[_getKey(token0, token1)] = pool;
    }

    /// @dev Get pool address for trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @return pool Pool for the trade pair
    function pairFor(address token0, address token1) external view override returns (address pool) {
        return _pairFor(token0, token1);
    }

    /// @dev Register routing path
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param path Routing path
    function registerRouterPath(address src, address dest, address[] calldata path) external override onlyGovernance {
        // Check that the source and destination addresses are correct
        require(src == path[0], "CoFiXRouter: first token error");
        require(dest == path[path.length - 1], "CoFiXRouter: last token error");
        // Register routing path
        _paths[_getKey(src, dest)] = path;
    }

    /// @dev Get routing path from src token address to dest token address
    /// @param src Src token address
    /// @param dest Dest token address
    /// @return path If success, return the routing path, 
    /// each address in the array represents the token address experienced during the trading
    function getRouterPath(address src, address dest) external view override returns (address[] memory path) {
        // Load the routing path
        path = _paths[_getKey(src, dest)];
        uint j = path.length;

        // If it is a reverse path, reverse the path
        require(j > 0, "CoFiXRouter: path not exist");
        if (src == path[--j] && dest == path[0]) {
            for (uint i = 0; i < j;) {
                address tmp = path[i];
                path[i++] = path[j];
                path[j--] = tmp;
            }
        } else {
            require(src == path[0] && dest == path[j], "CoFiXRouter: path error");
        }
    }
    
    /// @dev Get pool address for trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @return pool Pool for the trade pair
    function _pairFor(address token0, address token1) private view returns (address pool) {
        return _pairs[_getKey(token0, token1)];
    }

    // Generate the mapping key based on the token address
    function _getKey(address token0, address token1) private pure returns (bytes32) {
        (token0, token1) = _sort(token0, token1);
        return keccak256(abi.encodePacked(token0, token1));
    }

    // Sort the address pair
    function _sort(address token0, address token1) private pure returns (address min, address max) {
        if (token0 < token1) {
            min = token0;
            max = token1;
        } else {
            min = token1;
            max = token0;
        }
    }

    /// @dev Maker add liquidity to pool, get pool token (mint XToken to maker) 
    /// (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The deadline of this request
    /// @return xtoken The liquidity share token address obtained
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidity(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external payable override ensure(deadline) returns (address xtoken, uint liquidity) {
        // 1. Transfer token to pool
        if (token != address(0)) {
            TransferHelper.safeTransferFrom(token, msg.sender, pool, amountToken);
        }

        // 2. Add liquidity, and increase xtoken
        (xtoken, liquidity) = ICoFiXPool(pool).mint { 
            value: msg.value 
        } (token, to, amountETH, amountToken, to);

        // The number of shares should not be lower than the expected minimum value
        require(liquidity >= liquidityMin, "CoFiXRouter: less liquidity than expected");
    }

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) 
    /// (notice: msg.value = oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountETHMin The minimum amount of ETH wanted to get from pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The deadline of this request
    /// @return amountETH The real amount of ETH transferred from the pool
    /// @return amountToken The real amount of Token transferred from the pool
    function removeLiquidityGetTokenAndETH(
        address pool,
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable override ensure(deadline) returns (uint amountETH, uint amountToken) {
        // 0. Get xtoken corresponding to the token
        address xtoken = ICoFiXPool(pool).getXToken(token);

        // 1. Transfer xtoken to pool
        TransferHelper.safeTransferFrom(xtoken, msg.sender, pool, liquidity);

        // 2. Remove liquidity and return tokens
        (amountETH, amountToken) = ICoFiXPool(pool).burn {
            value: msg.value
        } (token, to, liquidity, to);

        // 3. amountETH must not less than expected
        require(amountETH >= amountETHMin, "CoFiXRouter: less eth than expected");
    }

    /// @dev Swap exact tokens for tokens
    /// @param  path Routing path. If you need to exchange through multi-level routes, you need to write down all 
    /// token addresses (ETH address is represented by 0) of the exchange path
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The minimum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The deadline of this request
    /// @return amountOut The real amount of Token transferred out of pool
    function swapExactTokensForTokens(
        address[] calldata path,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable override ensure(deadline) returns (uint amountOut) {
        uint mined;
        if (path.length == 2) {
            address src = path[0];
            address dest = path[1];

            // 0. Get pool address for trade pair
            address pool = _pairFor(src, dest);

            // 1. Transfer token to the pool
            if (src != address(0)) {
                TransferHelper.safeTransferFrom(src, msg.sender, pool, amountIn);
            }

            // 2. Trade
            (amountOut, mined) = ICoFiXPool(pool).swap {
                value: msg.value
            } (src, dest, amountIn, to, to);
        } else {
            // 1. Trade
            (amountOut, mined) = _swap(path, amountIn, to);

            // 2. Any remaining ETH in the Router is considered to be the user's and is forwarded to 
            // the address specified by the Router
            uint balance = address(this).balance;
            if (balance > 0) {
                payable(to).transfer(balance);
            } 
        }

        // 3. amountOut must not less than expected
        require(amountOut >= amountOutMin, "CoFiXRouter: got less than expected");
    }

    // Trade
    function _swap(
        address[] calldata path,
        uint amountIn,
        address to
    ) private returns (
        uint amountOut, 
        uint totalMined
    ) {
        // Initialize
        totalMined = 0;
        
        // Get the first pair
        address token0 = path[0];
        address token1 = path[1];
        address pool = _pairFor(token0, token1);
        // Transfer token to first pool
        if (token0 != address(0)) {
            TransferHelper.safeTransferFrom(token0, to, pool, amountIn);
        }

        uint mined;
        // Execute the exchange transaction according to the routing path
        for (uint i = 1; ; ) {
            // Address to receive funds for this transaction
            address recv = to;

            // Next token address. 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF means empty
            address next = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
            if (++i < path.length) {
                next = path[i];
                // While the next token address still exists, the fund receiving address is the next transaction pair
                recv = _pairFor(token1, next);
            }

            // Perform an exchange transaction. If token1 is ETH, the fund receiving address is address(this).
            // Q: The solution of openzeppelin-upgrades may cause transfer eth fail, 
            //    It needs to be validated and resolved
            // A: Since the execution entry is at CoFiXRouter, the proxy address of the CoFiXRouter has 
            //    already been read, which reduces the gas consumption for subsequent reads, So the gas 
            //    consumption of the later receive() transfer to CoFiXRouter is reduced without an error, 
            //    so OpenZeppelin is now available, The upgradable solution of does not cause the problem 
            //    of converting ETH from the capital pool to CoFixRouter to fail.
            (amountIn, mined) = ICoFiXPool(pool).swap {
                value: address(this).balance
            } (token0, token1, amountIn, token1 == address(0) ? address(this) : recv, address(this));

            // Increase total mining
            totalMined += mined;
            // Record the amount of money exchanged this time
            //amounts[i - 1] = amountIn;

            // next equal to 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF means trade is over
            if (next == 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF) {
                break;
            }

            // Switch to the next trade pair in the routing path
            token0 = token1;
            token1 = next;
            pool = recv;
        }

        amountOut = amountIn;
    }

    receive() external payable {
    }
}
