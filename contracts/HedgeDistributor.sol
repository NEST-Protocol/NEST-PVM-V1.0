// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IHedgeDistributor.sol";

import "./HedgeFrequentlyUsed.sol";
import "./DCU.sol";

/// @dev DCU分发合约
contract HedgeDistributor is HedgeFrequentlyUsed, IHedgeDistributor {

    // TODO: 发布时修改为线上版本的CoFiXRouter地址
    // address constant COFIX_ROUTER_ADDRESS = 0x57F0A4ef374B35eb32B61Dd8bc68C58e886CFC84;
    address constant COFIX_ROUTER_ADDRESS = 0x9f7997EFb0aF6f5e370dea99b1941D73330825C9;

    // TODO: 发布时修改为线上版本的NEST地址
    // address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
    //address constant NEST_TOKEN_ADDRESS = 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25;
    address NEST_TOKEN_ADDRESS;

    // TODO: 发布时改为 30000000 ether * 30000000 ether
    //uint constant K = 30000000 ether * 30000000 ether;
    uint constant K = 3000000 ether * 3000000 ether;

    constructor() {
    }

    // TODO: 删除此测试方法
    function setNestTokenAddress(address nestTokenAddress) external {
        NEST_TOKEN_ADDRESS = nestTokenAddress;
    }

    /// @dev 存入nest和dcu
    /// @param nestAmount nest数量
    /// @param dcuAmount dcu数量
    function deposit(uint nestAmount, uint dcuAmount) external {
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), nestAmount);
        TransferHelper.safeTransferFrom( DCU_TOKEN_ADDRESS, msg.sender, address(this),  dcuAmount);
        require(
            IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(this)) * 
            IERC20(DCU_TOKEN_ADDRESS).balanceOf(address(this)) <= K,
            "HD:too much"
        );
    }

    /// @dev Swap token
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountOut The real amount of ETH transferred out of pool
    /// @return mined The amount of CoFi which will be mind by this trade
    function swap(
        address src, 
        address dest, 
        uint amountIn, 
        address to, 
        address payback
    ) external payable returns (
        uint amountOut, 
        uint mined
    ) {
        require(msg.sender == COFIX_ROUTER_ADDRESS, "HD:only for router");
        if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }
        
        amountOut = _swap(src, dest, to);
    }

    /// @dev 使用确定数量的nest兑换dcu
    /// @param nestAmount nest数量
    /// @return dcuAmount 兑换到的dcu数量
    function swapForDCU(uint nestAmount) external override returns (uint dcuAmount) {
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), nestAmount);
        dcuAmount = _swap(NEST_TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, msg.sender);
    }

    /// @dev 使用确定数量的dcu兑换nest
    /// @param dcuAmount dcu数量
    /// @return nestAmount 兑换到的nest数量
    function swapForNEST(uint dcuAmount) external override returns (uint nestAmount) {
        TransferHelper.safeTransferFrom(DCU_TOKEN_ADDRESS, msg.sender, address(this), dcuAmount);
        nestAmount = _swap(DCU_TOKEN_ADDRESS, NEST_TOKEN_ADDRESS, msg.sender);
    }

    /// @dev 使用nest兑换确定数量的dcu
    /// @param dcuAmount 预期得到的dcu数量
    /// @return nestAmount 支付的nest数量
    function swapExactDCU(uint dcuAmount) external override returns (uint nestAmount) {
        nestAmount = _swapExact(NEST_TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, dcuAmount, msg.sender);
    }

    /// @dev 使用dcu兑换确定数量的nest
    /// @param nestAmount 预期得到的nest数量
    /// @return dcuAmount 支付的dcu数量
    function swapExactNEST(uint nestAmount) external override returns (uint dcuAmount) {
       dcuAmount = _swapExact(DCU_TOKEN_ADDRESS, NEST_TOKEN_ADDRESS, nestAmount, msg.sender);
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
