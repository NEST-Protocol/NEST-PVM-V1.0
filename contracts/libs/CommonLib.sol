// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Common library
library CommonLib {
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // // ETH:
    // // Block average time in milliseconds. ethereum 12.09 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    // uint constant BLOCK_TIME = 12090;
    // // Minimal exercise block period. 200000
    // uint constant MIN_PERIOD = 200000;
    // // Minimal exercise block period for NestLPGuarantee. 200000
    // uint constant MIN_EXERCISE_BLOCK = 200000;

    // BSC:
    // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    uint constant BLOCK_TIME = 3000;
    // Minimal exercise block period. 840000
    uint constant MIN_PERIOD = 840000;
    // Minimal exercise block period for NestLPGuarantee. 840000
    uint constant MIN_EXERCISE_BLOCK = 840000;

    // // Polygon:
    // // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    // uint constant BLOCK_TIME = 2200;
    // // Minimal exercise block period. 1200000
    // uint constant MIN_PERIOD = 1200000;
    // // Minimal exercise block period for NestLPGuarantee. 1200000
    // uint constant MIN_EXERCISE_BLOCK = 1200000;

    // // KCC:
    // // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    // uint constant BLOCK_TIME = 3000;
    // // Minimal exercise block period. 840000
    // uint constant MIN_PERIOD = 840000;
    // // Minimal exercise block period for NestLPGuarantee. 840000
    // uint constant MIN_EXERCISE_BLOCK = 840000;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // USDT base
    uint constant USDT_BASE = 1 ether;

    // Post unit: 2000usd
    uint constant POST_UNIT = 2000 * USDT_BASE;

    // Minimum value quantity. If the balance is less than this value, it will be liquidated
    uint constant MIN_FUTURE_VALUE = 15 ether;

    // Unit of nest, 4 decimals
    uint constant NEST_UNIT = 0.0001 ether;

    // Min amount of buy futures, amount >= 50 nest
    uint constant FUTURES_NEST_LB = 499999;

    // Service fee for buy, sell, add and liquidate
    uint constant FEE_RATE = 0.002 ether;
    
    // Fee for execute limit order or stop order, 15 nest
    uint constant EXECUTE_FEE = 150000;

    // Fee for execute limit order or stop order in nest values, 18 decimals
    uint constant EXECUTE_FEE_NEST = EXECUTE_FEE * NEST_UNIT;

    // TODO: To confirm range of lever

    // Range of lever, (LEVER_LB, LEVER_RB)
    uint constant LEVER_LB = 0;

    // Range of lever, (LEVER_LB, LEVER_RB)
    uint constant LEVER_RB = 51;

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return v float format
    function encodeFloat56(uint value) internal pure returns (uint56 v) {
        assembly {
            for { v := 0 } gt(value, 0x3FFFFFFFFFFFF) { v := add(v, 1) } {
                value := shr(4, value)
            }
            v := or(v, shl(6, value))
        }
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function decodeFloat(uint floatValue) internal pure returns (uint) {
        return (floatValue >> 6) << ((floatValue & 0x3F) << 2);
    }

    /// @dev Convert to usdt based price
    /// @param rawPrice The price that equivalent to 2000usd 
    function toUSDTPrice(uint rawPrice) internal pure returns (uint) {
        return CommonLib.POST_UNIT * 1 ether / rawPrice;
    }    
}