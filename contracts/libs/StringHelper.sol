// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 字符串工具
library StringHelper {

    // from NEST v3.0
    function stringConcat(string memory a, string memory b) internal pure returns (string memory)
    {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        string memory ret = new string(ba.length + bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < ba.length; ++i) {
            bret[k++] = ba[i];
        } 
        for (uint i = 0; i < bb.length; ++i) {
            bret[k++] = bb[i];
        } 
        return string(ret);
    } 
    
    // Convert number into a string, if less than 4 digits, make up 0 in front, from NEST v3.0
    function toString(uint iv, uint minLength) internal pure returns (string memory) 
    {
        bytes memory buf = new bytes(64);
        uint index = 0;
        do {
            buf[index++] = bytes1(uint8(iv % 10 + 48));
            iv /= 10;
        } while (iv > 0 || index < minLength);
        bytes memory str = new bytes(index);
        for(uint i = 0; i < index; ++i) {
            str[i] = buf[index - i - 1];
        }
        return string(str);
    }

    function toUpper(string memory str) internal pure returns (string memory) {
        bytes memory bs = bytes(str);
        for (uint i = 0; i < bs.length; ++i) {
            uint b = uint(uint8(bytes1(bs[i])));
            if (b >= 97 && b <= 122) {
                bs[i] = bytes1(uint8(b - 32));
            }
        }
        return str;
    }

    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bs = bytes(str);
        for (uint i = 0; i < bs.length; ++i) {
            uint b = uint(uint8(bytes1(bs[i])));
            if (b >= 65 && b <= 90) {
                bs[i] = bytes1(uint8(b + 32));
            }
        }
        return str;
    }

    function substring(string memory str, uint start, uint count) internal pure returns (string memory) {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        if (start >= length) {
            return "";
        }
        if (start + count > length) {
            count = length - start;
        }
        bytes memory re = new bytes(count);
        while (count > 0) {
            --count;
            re[count] = bs[start + count];
        }
        return string(re);
    }
}