// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IHedgeGovernance.sol";

import "./HedgeBase.sol";

/// @dev Base contract of Hedge
contract HedgeFrequentlyUsed is HedgeBase {

    // Address of DCU contract
    address constant DCU_TOKEN_ADDRESS = 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF;

    // Address of NestPriceFacade contract
    address constant NEST_PRICE_FACADE_ADDRESS = 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A;
    
    // USDT代币地址
    address constant USDT_TOKEN_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // USDT代币的基数
    uint constant USDT_BASE = 1 ether;

    // ETH/USDT报价通道id
    uint constant ETH_USDT_CHANNEL_ID = 0;

    uint constant TRANSFER_RATE = 0;

    function _toUSDTPrice(uint rawPrice) internal pure returns (uint) {
        return 2000 ether * 1 ether / rawPrice;
    }
}
