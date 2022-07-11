// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Swap DCU to NEST
contract NestBuyBackPool is NestFrequentlyUsed {

    uint constant EXCHANGE_RATIO = 3.3 ether;

    // // TODO: use real DCU token address
    // address constant DCU_TOKEN_ADDRESS = 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF;

    // // CoFiXRouter address
    // address constant COFIX_ROUTER_ADDRESS = 0xb29A8d980E1408E487B9968f5E4f7fD7a9B0CaC5;

    // TODO: Use constant version
    address DCU_TOKEN_ADDRESS;
    // CoFiXRouter address
    address COFIX_ROUTER_ADDRESS;
    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);

        DCU_TOKEN_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.dcu");
        COFIX_ROUTER_ADDRESS = INestGovernance(newGovernance).checkAddress("cofix.cofixRouter");
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

        if (src == DCU_TOKEN_ADDRESS && dest == NEST_TOKEN_ADDRESS) {
            amountOut = amountIn * EXCHANGE_RATIO / 1 ether;
            TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, to, amountOut);
        } else {
            revert("PRCSwap:pair not allowed");
        }

        mined = 0;
    }
}
