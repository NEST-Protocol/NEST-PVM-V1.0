// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./custom/HedgeFrequentlyUsed.sol";

/// @dev Swap dcu with token
contract FortPRCSwap is HedgeFrequentlyUsed {

    // TODO:
    // address constant COFIX_ROUTER_ADDRESS = address(0);

    // TODO:
    // // Target token address
    // address constant PRC_TOKEN_ADDRESS = address(0);

    // TODO:
    address COFIX_ROUTER_ADDRESS;
    // Target token address
    address PRC_TOKEN_ADDRESS;   
    function setAddress(address cofixRouter, address fortPRC) external onlyGovernance {
        COFIX_ROUTER_ADDRESS = cofixRouter;
        PRC_TOKEN_ADDRESS = fortPRC;
    }

    constructor() {
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
        require(msg.sender == COFIX_ROUTER_ADDRESS, "PRCSwap:not router");
        if (msg.value > 0) {
            // payable(payback).transfer(msg.value);
            TransferHelper.safeTransferETH(payback, msg.value);
        }

        if (src == PRC_TOKEN_ADDRESS && dest == DCU_TOKEN_ADDRESS) {
            amountOut = amountIn;
        } else if (src == DCU_TOKEN_ADDRESS && dest == PRC_TOKEN_ADDRESS) {
            amountOut = amountIn >> 1;
        } else {
            revert("PRCSwap:pair not allowed");
        }

        TransferHelper.safeTransfer(dest, to, amountOut);
        mined = 0;
    }
}
