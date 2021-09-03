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
        bytes memory buffer = new bytes(64);
        uint index = 0;
        while (iv > 0 || index < minLength) {
            buffer[index++] = bytes1(uint8(iv % 10 + 48));
            iv /= 10;
        }
        bytes memory str = new bytes(index);
        for(uint i = 0; i < index; ++i) {
            str[i] = buffer[index - i - 1];
        }
        return string(str);
    }

    /// @dev 将字符串转为大写形式
    /// @param str 目标字符串
    /// @return 目标字符串的大写
    function toUpper(string memory str) internal pure returns (string memory) 
    {
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
    function toLower(string memory str) internal pure returns (string memory) 
    {
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
    function substring(string memory str, uint start, uint count) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        if (start >= length) {
            count = 0;
        } else if (start + count > length) {
            count = length - start;
        }
        bytes memory buffer = new bytes(count);
        while (count > 0) {
            --count;
            buffer[count] = bs[start + count];
        }
        return string(buffer);
    }

    /// @dev 截取字符串
    /// @param str 目标字符串
    /// @param start 截取开始索引
    /// @return 截取结果
    function substring(string memory str, uint start) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        uint count = 0;
        if (start < length) {
            count = length - start;
        }
        bytes memory buffer = new bytes(count);
        while (count > 0) {
            --count;
            buffer[count] = bs[start + count];
        }
        return string(buffer);
    }

    /// @dev 将整形转化为十进制字符串并写入内存数组，如果长度小于指定长度，则在前面补0
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param iv 要转化的整形值
    /// @param minLength 最小长度
    /// @return 写入后的新的内存数组偏移位置
    function writeUIntDec(bytes memory buffer, uint index, uint iv, uint minLength) internal pure returns (uint) 
    {
        uint i = index;
        minLength += index;
        while (iv > 0 || index < minLength) {
            buffer[index++] = bytes1(uint8(iv % 10 + 48));
            iv /= 10;
        }

        for (uint j = index; j > i;) {
            bytes1 tmp = buffer[i];
            buffer[i++] = buffer[--j];
            buffer[j] = tmp;
        }

        return index;
    }

    /// @dev 将整形转化为十进制字符串并写入内存数组，如果长度小于指定长度，则在前面补0
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param fv 要转化的浮点值
    /// @param decimals 小数位数
    /// @return 写入后的新的内存数组偏移位置
    function writeFloat(bytes memory buffer, uint index, uint fv, uint decimals) internal pure returns (uint) 
    {
        uint base = 10 ** decimals;
        index = writeUIntDec(buffer, index, fv / base, 1);
        buffer[index++] = bytes1(uint8(46));
        index = writeUIntDec(buffer, index, fv % base, decimals);

        return index;
    }
    
    /// @dev 将整形转化为十六进制字符串并写入内存数组，如果长度小于指定长度，则在前面补0
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param iv 要转化的整形值
    /// @param minLength 最小长度
    /// @return 写入后的新的内存数组偏移位置
    function writeUIntHex(bytes memory buffer, uint index, uint iv, uint minLength) internal pure returns (uint) 
    {
        uint i = index;
        minLength += index;
        while (iv > 0 || index < minLength) {
            uint c = iv & 0xF;
            if (c > 9) {
                buffer[index++] = bytes1(uint8(c + 87));
            } else {
                buffer[index++] = bytes1(uint8(c + 48));
            }
            iv >>= 4;
        }

        for (uint j = index; j > i;) {
            bytes1 tmp = buffer[i];
            buffer[i++] = buffer[--j];
            buffer[j] = tmp;
        }

        return index;
    }

    /// @dev 截取字符串并写入内存数组
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param str 目标字符串
    /// @param start 截取开始索引
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @return 写入后的新的内存数组偏移位置
    function writeString(
        bytes memory buffer, 
        uint index, 
        string memory str, 
        uint start, 
        uint count
    ) internal pure returns (uint) 
    {
        bytes memory bs = bytes(str);
        uint i = 0;
        while (i < count && start + i < bs.length) {
            buffer[index + i] = bs[start + i];
            ++i;
        }
        return index + i;
    }

    /// @dev 从内存数组中截取一段
    /// @param buffer 目标内存数组
    /// @param start 截取开始索引
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @return 截取结果
    function segment(bytes memory buffer, uint start, uint count) internal pure returns (bytes memory) 
    {
        uint length = buffer.length;
        if (start >= length) {
            count = 0;
        } else if (start + count > length) {
            count = length - start;
        }
        bytes memory re = new bytes(count);
        while (count > 0) {
            --count;
            re[count] = buffer[start + count];
        }
        return re;
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0) internal pure returns (string memory) {
        return sprintf(format, [arg0, 0, 0, 0, 0]);
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg1 参数1（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0, uint arg1) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, 0, 0, 0]);
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg1 参数1（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg2 参数2（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, 0, 0]);
    }
    
    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg1 参数1（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg2 参数2（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg3 参数3（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2, uint arg3) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, arg3, 0]);
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param arg0 参数0（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg1 参数1（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg2 参数2（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg3 参数3（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @param arg4 参数4（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2, uint arg3, uint arg4) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, arg3, arg4]);
    }
    
    /// @dev 将参数按照格式化字符串指定的内容解析并输出
    /// @param format 格式化描述字符串
    /// @param args 参数表（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 格式化结果
    function sprintf(string memory format, uint[5] memory args) internal pure returns (string memory) {
        bytes memory buffer = new bytes(63);
        uint index = sprintf(buffer, 0, bytes(format), args);
        return string(segment(buffer, 0, index));
    }

    /// @dev 将参数按照格式化字符串指定的内容解析并输出到内存数组的指定位置
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param format 格式化描述字符串
    /// @param args 参数表（字符串需要使用StringHelper.enc进行编码，并且长度不能超过31）
    /// @return 写入后的新的内存数组偏移位置
    function sprintf(
        bytes memory buffer, 
        uint index, 
        bytes memory format, 
        uint[5] memory args
    ) internal pure returns (uint) {

        uint i = 0;
        uint pi = 0;
        uint ai = 0;
        uint state = 0;
        uint w = 0;

        while (i < format.length) {
            uint c = uint(uint8(format[i]));
			// 0 正常                                             
            if (state == 0) {
                // %
                if (c == 37) {
                    while (pi < i) {
                        buffer[index++] = format[pi++];
                    }
                    state = 1;
                }
                ++i;
                continue;
            }
			// 1, 确认是否有 -
            else if (state == 1) {
                // %
                if (c == 37) {
                    buffer[index++] = bytes1(uint8(37));
                    pi = ++i;
                    state = 0;
                    continue;
                }
                // // -
                // if (c == 45) {
                //     ++i;
                // }
                // state = 2;
                state = 3;
                continue;
            }
			// // 2, 确认是否有 0  
            // else if (state == 2) {
            //     if (c == 48) {
            //         ++i;
            //     }
            //     state = 3;
            //     continue;
            // }
			// 3 找数据宽度
            else if (state == 3) {
                while (c >= 48 && c <= 57) {
                    w = w * 10 + c - 48;
                    c = uint(uint8(format[++i]));
                }
                state = 4;
                continue;
            }
            // 4, 找格式类型   
			else if (state == 4) {
                uint arg = args[ai++];
                // d
                if (c == 100) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    } else {
                        buffer[index++] = bytes1(uint8(43));
                    }
                    c = 117;
                }
                // u
                if (c == 117) {
                    index = writeUIntDec(buffer, index, arg, w == 0 ? 1 : w);
                }
                // x
                else if (c == 120) {
                    index = writeUIntHex(buffer, index, arg, w == 0 ? 1 : w);
                }
                // s/S
                else if (c == 115 || c == 83) {
                    index = writeEncString(buffer, index, arg, 0, w == 0 ? 31 : w, c == 83 ? 1 : 0);
                }
                // f
                else if (c == 102) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    }
                    index = writeFloat(buffer, index, arg, w == 0 ? 8 : w);
                }
                pi = ++i;
                state = 0;
                w = 0;
            }
        }

        while (pi < i) {
            buffer[index++] = format[pi++];
        }

        return index;
    }

    /// @dev 将字符串编码成uint（字符串长度不能超过31）
    /// @param str 目标字符串
    /// @return 编码结果
    function enc(bytes memory str) internal pure returns (uint) {

        uint i = str.length;
        require(i < 32, "StringHelper:string too long");
        uint v = 0;
        while (i > 0) {
            v = (v << 8) | uint(uint8(str[--i]));
        }

        return (v << 8) | str.length;
    }

    // /// @dev 将使用enc编码的uint解码成字符串
    // /// @param v 使用enc编码过的字符串
    // /// @return 解码结果
    // function dec(uint v) internal pure returns (string memory) {
    //     uint length = v & 0xFF;
    //     v >>= 8;
    //     bytes memory buffer = new bytes(length);
    //     for (uint i = 0; i < length;) {
    //         buffer[i++] = bytes1(uint8(v & 0xFF));
    //         v >>= 8;
    //     }
    //     return string(buffer);
    // }

    /// @dev 将使用enc编码的uint解码成字符串
    /// @param buffer 目标内存数组
    /// @param index 目标内存数组起始位置
    /// @param v 使用enc编码过的字符串
    /// @param start 截取开始索引
    /// @param count 截取长度（如果长度不够，则取剩余长度）
    /// @param charCase 字符的大小写，0不改变，1大小，2小写
    /// @return 写入后的新的内存数组偏移位置
    function writeEncString(
        bytes memory buffer, 
        uint index, 
        uint v, 
        uint start, 
        uint count,
        uint charCase
    ) internal pure returns (uint) {

        uint length = (v & 0xFF) - start;
        if (length > count) {
            length = count;
        }
        v >>= (start + 1) << 3;
        while (length > 0) {
            uint c = v & 0xFF;
            if (charCase == 1 && c >= 97 && c <= 122) {
                c -= 32;
            } else if (charCase == 2 && c >= 65 && c <= 90) {
                c -= 32;
            }
            buffer[index++] = bytes1(uint8(c));
            v >>= 8;
            --length;
        }
        
        return index;
    }
}