// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./NestFrequentlyUsed.sol";

import "../interfaces/INestBatchPrice2.sol";

/// @dev PriceAdapter from INestBatchPrice2
contract NestPriceAdapter is NestFrequentlyUsed {
    
    // Token configuration
    struct TokenConfig {
        // The channelId for call nest price
        uint16 channelId;
        // The pairIndex for call nest price
        uint16 pairIndex;

        // SigmaSQ for token
        uint64 sigmaSQ;
        // MIU_LONG for token
        uint64 miuLong;
        // MIU_SHORT for token
        uint64 miuShort;
    }

    // Post unit: 2000usd
    uint constant POST_UNIT = 2000 * USDT_BASE;

    function _pairIndices(uint pairIndex) private pure returns (uint[] memory pairIndices) {
        pairIndices = new uint[](1);
        pairIndices[0] = pairIndex;
    }

    // Query latest 2 price
    function _lastPriceList(
        TokenConfig memory tokenConfig, 
        uint fee, 
        address payback
    ) internal returns (uint[] memory prices) {
        prices = INestBatchPrice2(NEST_OPEN_PRICE).lastPriceList {
            value: fee
        } (uint(tokenConfig.channelId), _pairIndices(uint(tokenConfig.pairIndex)), 2, payback);

        prices[1] = _toUSDTPrice(prices[1]);
        prices[3] = _toUSDTPrice(prices[3]);
    }

    // Query latest price
    function _latestPrice(
        TokenConfig memory tokenConfig, 
        uint fee, 
        address payback
    ) internal returns (uint oraclePrice) {
        uint[] memory prices = INestBatchPrice2(NEST_OPEN_PRICE).lastPriceList {
            value: fee
        } (uint(tokenConfig.channelId), _pairIndices(uint(tokenConfig.pairIndex)), 1, payback);

        oraclePrice = _toUSDTPrice(prices[1]);
    }

    // Find price by blockNumber
    function _findPrice(
        TokenConfig memory tokenConfig, 
        uint blockNumber, 
        uint fee, 
        address payback
    ) internal returns (uint oraclePrice) {
        uint[] memory prices = INestBatchPrice2(NEST_OPEN_PRICE).findPrice {
            value: fee
        } (uint(tokenConfig.channelId), _pairIndices(uint(tokenConfig.pairIndex)), blockNumber, payback);

        oraclePrice = _toUSDTPrice(prices[1]);
    }

    // Convert to usdt based price
    function _toUSDTPrice(uint rawPrice) internal pure returns (uint) {
        return POST_UNIT * 1 ether / rawPrice;
    }
}
