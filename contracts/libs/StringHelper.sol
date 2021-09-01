// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 字符串工具
library StringHelper {

    /// @dev 连接两个字符串
    /// @param a 字符串a
    /// @param b 字符串b
    /// @return 连接后的字符串
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
    
    /// @dev 将整形转化为字符串，如果长度小于指定长度，则在前面补0
    /// @param iv 要转化的整形值
    /// @param minLength 最小长度
    /// @return 转化结果字符串
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

    /// @dev 将字符串转为大写形式
    /// @param str 目标字符串
    /// @return 目标字符串的大写
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

    /// @dev 将字符串转为小写形式
    /// @param str 目标字符串
    /// @return 目标字符串的小写
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

    /// @dev 截取字符串
    /// @param str 目标字符串
    /// @param start 截取开始索引
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @return 截取结果
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

    /// @dev 截取字符串
    /// @param str 目标字符串
    /// @param start 截取开始索引
    /// @return 截取结果
    function substring(string memory str, uint start) internal pure returns (string memory) {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        if (start >= length) {
            return "";
        }
        uint count = length - start;
        bytes memory re = new bytes(count);
        while (count > 0) {
            --count;
            re[count] = bs[start + count];
        }
        return string(re);
    }
}