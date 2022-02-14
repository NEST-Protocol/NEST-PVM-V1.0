// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IHedgeSwap.sol";

import "./custom/HedgeFrequentlyUsed.sol";

import "./DCU.sol";

/// @dev Swap DCU with NEST
contract HedgeSwap is HedgeFrequentlyUsed, IHedgeSwap {

    // NEST token address
    address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;

    // K value, 15000000 nest and 15000000 dcu
    uint constant K = 15000000 ether * 15000000 ether;

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
        if (src == NEST_TOKEN_ADDRESS && dest == DCU_TOKEN_ADDRESS) {
            amountOut = _swap(NEST_TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, to);
        } else if (src == DCU_TOKEN_ADDRESS && dest == NEST_TOKEN_ADDRESS) {
            amountOut = _swap(DCU_TOKEN_ADDRESS, NEST_TOKEN_ADDRESS, to);
        } else {
            revert("HS:pair not allowed");
        }

        mined = 0;
    }

    /// @dev Swap for dcu with exact nest amount
    /// @param nestAmount Amount of nest
    /// @return dcuAmount Amount of dcu acquired
    function swapForDCU(uint nestAmount) external override returns (uint dcuAmount) {
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), nestAmount);
        dcuAmount = _swap(NEST_TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, msg.sender);
    }

    /// @dev Swap for token with exact dcu amount
    /// @param dcuAmount Amount of dcu
    /// @return nestAmount Amount of token acquired
    function swapForNEST(uint dcuAmount) external override returns (uint nestAmount) {
        TransferHelper.safeTransferFrom(DCU_TOKEN_ADDRESS, msg.sender, address(this), dcuAmount);
        nestAmount = _swap(DCU_TOKEN_ADDRESS, NEST_TOKEN_ADDRESS, msg.sender);
    }

    /// @dev Swap for exact amount of dcu
    /// @param dcuAmount amount of dcu expected
    /// @return nestAmount Amount of token paid
    function swapExactDCU(uint dcuAmount) external override returns (uint nestAmount) {
        nestAmount = _swapExact(NEST_TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, dcuAmount, msg.sender);
    }

    /// @dev Swap for exact amount of token
    /// @param nestAmount Amount of token expected
    /// @return dcuAmount Amount of dcu paid
    function swapExactNEST(uint nestAmount) external override returns (uint dcuAmount) {
       dcuAmount = _swapExact(DCU_TOKEN_ADDRESS, NEST_TOKEN_ADDRESS, nestAmount, msg.sender);
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
