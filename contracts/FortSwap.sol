// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IFortSwap.sol";

import "./custom/HedgeFrequentlyUsed.sol";

/// @dev dcu兑换合约
contract FortSwap is HedgeFrequentlyUsed, IFortSwap {

    // 目标代币地址
    address constant TOKEN_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;

    // TODO: 确定初始存入的DCU和USDT数量
    // K值，按照计划，根据以太坊上的swap资金池内的nest按照市价卖出，换得的usdt跨链到bsc，
    // 除去兑换和跨链的消耗，共得到952297.70usdt到bsc上，地址0x2bE88070a330Ef106E0ef77A45bd1F583BFcCf4E
    // 
    // 77027.78usdt作为项目支出转到0xc5229c9e1cbe1888B23015D283413a9C5e353aC7
    // 100000.00usdt转到DAO账号，作为项目经费
    // 剩余775269.92usdt进入新的usdt/dcu兑换资金池，根据nest/dcu资金池停掉时的价格
    // 计算出dcu的数量为 XXX
    uint constant K = 775269925761307568974296 * 2600000 ether;

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

        // K值是固定常量，伪造amountIn没有意义
        if (src == TOKEN_ADDRESS && dest == DCU_TOKEN_ADDRESS) {
            amountOut = _swap(TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, to);
        } else if (src == DCU_TOKEN_ADDRESS && dest == TOKEN_ADDRESS) {
            amountOut = _swap(DCU_TOKEN_ADDRESS, TOKEN_ADDRESS, to);
        } else {
            revert("HS:pair not allowed");
        }

        mined = 0;
    }

    /// @dev 使用确定数量的token兑换dcu
    /// @param tokenAmount token数量
    /// @return dcuAmount 兑换到的dcu数量
    function swapForDCU(uint tokenAmount) external override returns (uint dcuAmount) {
        TransferHelper.safeTransferFrom(TOKEN_ADDRESS, msg.sender, address(this), tokenAmount);
        dcuAmount = _swap(TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, msg.sender);
    }

    /// @dev 使用确定数量的dcu兑换token
    /// @param dcuAmount dcu数量
    /// @return tokenAmount 兑换到的token数量
    function swapForToken(uint dcuAmount) external override returns (uint tokenAmount) {
        TransferHelper.safeTransferFrom(DCU_TOKEN_ADDRESS, msg.sender, address(this), dcuAmount);
        tokenAmount = _swap(DCU_TOKEN_ADDRESS, TOKEN_ADDRESS, msg.sender);
    }

    /// @dev 使用token兑换确定数量的dcu
    /// @param dcuAmount 预期得到的dcu数量
    /// @return tokenAmount 支付的token数量
    function swapExactDCU(uint dcuAmount) external override returns (uint tokenAmount) {
        tokenAmount = _swapExact(TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, dcuAmount, msg.sender);
    }

    /// @dev 使用dcu兑换确定数量的token
    /// @param tokenAmount 预期得到的token数量
    /// @return dcuAmount 支付的dcu数量
    function swapExactToken(uint tokenAmount) external override returns (uint dcuAmount) {
       dcuAmount = _swapExact(DCU_TOKEN_ADDRESS, TOKEN_ADDRESS, tokenAmount, msg.sender);
    }

    // 使用确定数量的token兑换目标token
    function _swap(address src, address dest, address to) private returns (uint amountOut) {
        uint balance0 = IERC20(src).balanceOf(address(this));
        uint balance1 = IERC20(dest).balanceOf(address(this));

        amountOut = balance1 - K / balance0;
        TransferHelper.safeTransfer(dest, to, amountOut);
    }

    // 使用token兑换预期数量的token
    function _swapExact(address src, address dest, uint amountOut, address to) private returns (uint amountIn) {
        uint balance0 = IERC20(src).balanceOf(address(this));
        uint balance1 = IERC20(dest).balanceOf(address(this));

        amountIn = K / (balance1 - amountOut) - balance0;
        TransferHelper.safeTransferFrom(src, msg.sender, address(this), amountIn);
        TransferHelper.safeTransfer(dest, to, amountOut);
    }
}
