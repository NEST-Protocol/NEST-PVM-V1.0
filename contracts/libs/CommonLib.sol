// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Common library
library CommonLib {
    
    // Unit of nest, 4 decimals
    uint constant NEST_UNIT4 = 0.0001 ether;

    // Fee for limit order
    uint constant LIMIT_ORDER_FEE = 10 ether;

    // Fee for stop order
    uint constant STOP_ORDER_FEE = 10 ether;

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return v float format
    function _encodeFloat64(uint value) internal pure returns (uint64 v) {
        assembly {
            v := 0
            for { } gt(value, 0x3FFFFFFFFFFFFFF) { v := add(v, 1) } {
                value := shr(4, value)
            }

            v := or(v, shl(6, value))
        }
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return v float format
    function _encodeFloat48(uint value) internal pure returns (uint48 v) {
        assembly {
            v := 0
            for { } gt(value, 0x3FFFFFFFFFF) { v := add(v, 1) } {
                value := shr(4, value)
            }

            v := or(v, shl(6, value))
        }
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint floatValue) internal pure returns (uint) {
        return (floatValue >> 6) << ((floatValue & 0x3F) << 2);
    }
}