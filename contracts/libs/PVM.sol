// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "hardhat/console.sol";

/// @dev PVM implementation
library PVM {

    uint8 public constant $ZERO = uint8(0); // 0
    uint8 public constant $A = uint8(65);   // A
    uint8 public constant $Z = uint8(90);   // Z
    uint8 public constant $a = uint8(97);   // a
    uint8 public constant $z = uint8(122);  // z
    uint8 public constant $0 = uint8(48);   // 0
    uint8 public constant $9 = uint8(57);   // 9
    
    uint8 public constant $ADD = uint8(43); // +
    uint8 public constant $SUB = uint8(45); // -
    uint8 public constant $MUL = uint8(42); // *
    uint8 public constant $DIV = uint8(47); // /
    uint8 public constant $COL = uint8(58); // :
    uint8 public constant $LBR = uint8(40); // (
    uint8 public constant $RBR = uint8(41); // )
    uint8 public constant $SPC = uint8(32); // SPACE

    function calc(string memory expr) external view returns (uint) {
        return evaluate(bytes(expr), 0, bytes(expr).length);
    }

    // 1. Use x64 int
    // 2. Use mapping(bytes1=>address) to storage function
    // TODO: bracket
    // TODO: Operator Priority

    function evaluate(bytes memory expr, uint start, uint end) internal view returns (uint) {

        uint state = 0;
        uint index = start;
        uint left = 0;
        uint8 c;
        uint top = 0;
        uint iv = 0;
        uint o = 0;
        uint brackets = 0;

        while (index <= end) { 
            if (index == end) { c = $ZERO; }
            else { c = uint8(expr[index]); }

            if (state == 0) {
                // integer
                if (c >= $0 && c <= $9) {
                    state = 1;
                    iv = uint(c - $0);
                } 
                // identifier
                else if ((c >= $A && c <= $Z) || (c >= $a && c <= $z)) {
                    state = 2;
                } 
                // left bracket
                else if (c == $LBR) {
                    state = 3;
                    left = index + 1;
                    brackets = 1;
                } 
                // operator
                else if (c == $ADD) { state = 0 /* 4 */; o = 1; }
                else if (c == $SUB) { state = 0 /* 4 */; o = 2; } 
                else if (c == $MUL) { state = 0 /* 4 */; o = 3; }
                else if (c == $DIV) { state = 0 /* 4 */; o = 4; }
                // zero
                else if (c == $ZERO) { break; }
                // space
                else if (c == $SPC) { }
                // error
                else { revert("PVM:expression invalid"); }
            } 
            // integer
            else if (state == 1) {
                if (c >= $0 && c <= $9) {
                    iv = iv * 10 + uint(c - $0);
                } else {
                    state = 5;
                    continue;
                }
            }
            // left bracket
            else if (state == 3) {
                if (c == $RBR) {
                    if (--brackets == 0) {
                        iv = evaluate(expr, left, index);
                        state = 5;
                        continue;
                    }
                } else if (c == $LBR) {
                    ++brackets;
                }
            }
            // operator
            else if (state == 4) {
                state = 0;
            } 
            // calculate
            else if (state == 5) {
                // TODO: Process Operator Priority before calculate
                state = 0;
                if (o == 1) { top += iv; } else
                if (o == 2) { top -= iv; } else
                if (o == 3) { top *= iv; } else
                if (o == 4) { top /= iv; } else { top = iv; }
                o = 0;
            }
            // not implement
            else {
                revert("PVM:not implement");
            }
            ++index;
        }

        console.log("expr value: %d", top);
        return top;
    }

}