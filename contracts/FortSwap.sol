// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IFortSwap.sol";

import "./custom/FortFrequentlyUsed.sol";

/// @dev Swap dcu with token
contract FortSwap is FortFrequentlyUsed, IFortSwap {

    // Target token address
    address constant TOKEN_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;

    // K value, according to schedule, sell out nest from HedgeSwap pool on ethereum mainnet,
    // Exchange to usdt, and cross to BSC smart chain. Excluding exchange and cross chain consumption, 
    // a total of 952297.70usdt was obtained, address: 0x2bE88070a330Ef106E0ef77A45bd1F583BFcCf4E.
    // 77027.78usdt transferred to 0xc5229c9e1cbe1888b23015d283413a9c5e353ac7 as project expenditure.
    // 100000.00usdt transferred to the DAO address 0x9221295CE0E0D2E505CbeA635fa6730961FB5dFa for project funds.
    // The remaining 775269.92usdt transfer to the new usdt/dcu swap pool.
    // According to the price when nest/dcu swap pool stops, 1dcu=0.3289221986usdt,
    // The calculated number of dcu is 2357000.92.

    // 868,616.188258191063223411 DCU  868616188258191063223411
    // 200,000 BSC-USD                 200000000000000000000000
    uint constant K = 200000000000000000000000 * 868616188258191063223411;

    constructor() {
    }

    /// @dev Swap token
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param to The target address receiving the ETH
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountOut The real amount of ETH transferred out of pool
    /// @return mined The amount of CoFi which will be mind by this trade
    function swap(
        address src, 
        address dest, 
        uint /*amountIn*/, 
        address to, 
        address payback
    ) external payable returns (
        uint amountOut, 
        uint mined
    ) {
        if (msg.value > 0) {
            // payable(payback).transfer(msg.value);
            TransferHelper.safeTransferETH(payback, msg.value);
        }

        // The value of K is a fixed constant. Forging amountIn is useless.
        if (src == TOKEN_ADDRESS && dest == DCU_TOKEN_ADDRESS) {
            amountOut = _swap(TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, to);
        } else if (src == DCU_TOKEN_ADDRESS && dest == TOKEN_ADDRESS) {
            amountOut = _swap(DCU_TOKEN_ADDRESS, TOKEN_ADDRESS, to);
        } else {
            revert("HS:pair not allowed");
        }

        mined = 0;
    }

    /// @dev Swap for dcu with exact token amount
    /// @param tokenAmount Amount of token
    /// @return dcuAmount Amount of dcu acquired
    function swapForDCU(uint tokenAmount) external override returns (uint dcuAmount) {
        TransferHelper.safeTransferFrom(TOKEN_ADDRESS, msg.sender, address(this), tokenAmount);
        dcuAmount = _swap(TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, msg.sender);
    }

    /// @dev Swap for token with exact dcu amount
    /// @param dcuAmount Amount of dcu
    /// @return tokenAmount Amount of token acquired
    function swapForToken(uint dcuAmount) external override returns (uint tokenAmount) {
        TransferHelper.safeTransferFrom(DCU_TOKEN_ADDRESS, msg.sender, address(this), dcuAmount);
        tokenAmount = _swap(DCU_TOKEN_ADDRESS, TOKEN_ADDRESS, msg.sender);
    }

    /// @dev Swap for exact amount of dcu
    /// @param dcuAmount Amount of dcu expected
    /// @return tokenAmount Amount of token paid
    function swapExactDCU(uint dcuAmount) external override returns (uint tokenAmount) {
        tokenAmount = _swapExact(TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, dcuAmount, msg.sender);
    }

    /// @dev Swap for exact amount of token
    /// @param tokenAmount Amount of token expected
    /// @return dcuAmount Amount of dcu paid
    function swapExactToken(uint tokenAmount) external override returns (uint dcuAmount) {
       dcuAmount = _swapExact(DCU_TOKEN_ADDRESS, TOKEN_ADDRESS, tokenAmount, msg.sender);
    }

    // Swap exact amount of token for other
    function _swap(address src, address dest, address to) private returns (uint amountOut) {
        uint balance0 = IERC20(src).balanceOf(address(this));
        uint balance1 = IERC20(dest).balanceOf(address(this));

        amountOut = balance1 - K / balance0;
        TransferHelper.safeTransfer(dest, to, amountOut);
    }

    // Swap for exact amount of token by other
    function _swapExact(address src, address dest, uint amountOut, address to) private returns (uint amountIn) {
        uint balance0 = IERC20(src).balanceOf(address(this));
        uint balance1 = IERC20(dest).balanceOf(address(this));

        amountIn = K / (balance1 - amountOut) - balance0;
        TransferHelper.safeTransferFrom(src, msg.sender, address(this), amountIn);
        TransferHelper.safeTransfer(dest, to, amountOut);
    }
}
