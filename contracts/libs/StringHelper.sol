// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev String tools
library StringHelper {

    /// @dev Convert to upper case
    /// @param str Target string
    /// @return Upper case result
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

    /// @dev Convert to lower case
    /// @param str Target string
    /// @return Lower case result
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

    /// @dev Get substring
    /// @param str Target string
    /// @param start Start index in target string
    /// @param count Count of result. if length not enough, returns remain.
    /// @return Substring result
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

    /// @dev Get substring
    /// @param str Target string
    /// @param start Start index in target string
    /// @return Substring result
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

    /// @dev Write a uint in decimal. If length less than minLength, fill with 0 front.
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param iv Target uint value
    /// @param minLength Minimal length
    /// @return New offset in target buffer
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

    /// @dev Write a float in decimal. If length less than minLength, fill with 0 front.
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param fv Target float value
    /// @param decimals Decimal places
    /// @return New offset in target buffer
    function writeFloat(bytes memory buffer, uint index, uint fv, uint decimals) internal pure returns (uint) 
    {
        uint base = 10 ** decimals;
        index = writeUIntDec(buffer, index, fv / base, 1);
        buffer[index++] = bytes1(uint8(46));
        index = writeUIntDec(buffer, index, fv % base, decimals);

        return index;
    }
    
    /// @dev Write a uint in hexadecimal. If length less than minLength, fill with 0 front.
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param iv Target uint value
    /// @param minLength Minimal length
    /// @param upper If upper case
    /// @return New offset in target buffer
    function writeUIntHex(
        bytes memory buffer, 
        uint index, 
        uint iv, 
        uint minLength, 
        bool upper
    ) internal pure returns (uint) 
    {
        uint i = index;
        uint B = upper ? 55 : 87;
        minLength += index;
        while (iv > 0 || index < minLength) {
            uint c = iv & 0xF;
            if (c > 9) {
                buffer[index++] = bytes1(uint8(c + B));
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

    /// @dev Write a part of string to buffer
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param str Target string
    /// @param start Start index in target string
    /// @param count Count of string. if length not enough, use remain.
    /// @return New offset in target buffer
    function writeString(
        bytes memory buffer, 
        uint index, 
        string memory str, 
        uint start, 
        uint count
    ) private pure returns (uint) 
    {
        bytes memory bs = bytes(str);
        uint i = 0;
        while (i < count && start + i < bs.length) {
            buffer[index + i] = bs[start + i];
            ++i;
        }
        return index + i;
    }

    /// @dev Get segment from buffer
    /// @param buffer Target buffer
    /// @param start Start index in buffer
    /// @param count Count of string. if length not enough, returns remain.
    /// @return Segment from buffer
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

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0) internal pure returns (string memory) {
        return sprintf(format, [arg0, 0, 0, 0, 0]);
    }

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg1 Argument 1. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0, uint arg1) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, 0, 0, 0]);
    }

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg1 Argument 1. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg2 Argument 2. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, 0, 0]);
    }
    
    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg1 Argument 1. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg2 Argument 2. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg3 Argument 3. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2, uint arg3) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, arg3, 0]);
    }

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg1 Argument 1. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg2 Argument 2. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg3 Argument 3. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg4 Argument 4. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2, uint arg3, uint arg4) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, arg3, arg4]);
    }
    
    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param args Argument array. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint[5] memory args) internal pure returns (string memory) {
        bytes memory buffer = new bytes(127);
        uint index = sprintf(buffer, 0, bytes(format), args);
        return string(segment(buffer, 0, index));
    }

    /// @dev Format to memory buffer
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param format Format string
    /// @param args Argument array. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return New index in buffer
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
			// 0. Normal                                             
            if (state == 0) {
                // %
                if (c == 37) {
                    while (pi < i) {
                        buffer[index++] = format[pi++];
                    }
                    state = 1;
                }
                ++i;
            }
			// 1. Check if there is -
            else if (state == 1) {
                // %
                if (c == 37) {
                    buffer[index++] = bytes1(uint8(37));
                    pi = ++i;
                    state = 0;
                } else {
                    state = 3;
                }
            }
			// 3. Find with
            else if (state == 3) {
                while (c >= 48 && c <= 57) {
                    w = w * 10 + c - 48;
                    c = uint(uint8(format[++i]));
                }
                state = 4;
            }
            // 4. Find format descriptor   
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
                // x/X
                else if (c == 120 || c == 88) {
                    index = writeUIntHex(buffer, index, arg, w == 0 ? 1 : w, c == 88);
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

    /// @dev Encode string to uint. (The length can not great than 31)
    /// @param str Target string
    /// @return Encoded result
    function enc(string memory str) public pure returns (uint) {

        uint i = bytes(str).length;
        require(i < 32, "StringHelper:string too long");
        uint v = 0;
        while (i > 0) {
            v = (v << 8) | uint(uint8(bytes(str)[--i]));
        }

        return (v << 8) | bytes(str).length;
    }

    /// @dev Decode the value that encoded with enc
    /// @param v The value that encoded with enc
    /// @return Decoded value
    function dec(uint v) public pure returns (string memory) {
        uint length = v & 0xFF;
        v >>= 8;
        bytes memory buffer = new bytes(length);
        for (uint i = 0; i < length;) {
            buffer[i++] = bytes1(uint8(v & 0xFF));
            v >>= 8;
        }
        return string(buffer);
    }

    /// @dev Decode the value that encoded with enc and write to buffer
    /// @param buffer Target memory buffer
    /// @param index Start index in buffer
    /// @param v The value that encoded with enc
    /// @param start Start index in target string
    /// @param count Count of string. if length not enough, use remain.
    /// @param charCase 0: original case, 1: upper case, 2: lower case
    /// @return New index in buffer
    function writeEncString(
        bytes memory buffer, 
        uint index, 
        uint v, 
        uint start, 
        uint count,
        uint charCase
    ) public pure returns (uint) {

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

    // ******** Use abi encode to implement variable arguments ******** //

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param abiArgs byte array of arguments encoded by abi.encode()
    /// @return Format result
    function sprintf(string memory format, bytes memory abiArgs) internal pure returns (string memory) {
        bytes memory buffer = new bytes(127);
        uint index = sprintf(buffer, 0, bytes(format), abiArgs);
        return string(segment(buffer, 0, index));
    }

    /// @dev Format to memory buffer
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param format Format string
    /// @param abiArgs byte array of arguments encoded by abi.encode()
    /// @return New index in buffer
    function sprintf(
        bytes memory buffer, 
        uint index, 
        bytes memory format, 
        bytes memory abiArgs
    ) internal pure returns (uint) {

        uint i = 0;
        uint pi = 0;
        uint ai = 0;
        uint state = 0;
        uint w = 0;

        while (i < format.length) {
            uint c = uint(uint8(format[i]));
			// 0. Normal                                             
            if (state == 0) {
                // %
                if (c == 37) {
                    while (pi < i) {
                        buffer[index++] = format[pi++];
                    }
                    state = 1;
                }
                ++i;
            }
			// 1. Check if there is -
            else if (state == 1) {
                // %
                if (c == 37) {
                    buffer[index++] = bytes1(uint8(37));
                    pi = ++i;
                    state = 0;
                } else {
                    state = 3;
                }
            }
			// 3. Find width
            else if (state == 3) {
                while (c >= 48 && c <= 57) {
                    w = w * 10 + c - 48;
                    c = uint(uint8(format[++i]));
                }
                state = 4;
            }
            // 4. Find format descriptor   
			else if (state == 4) {
                uint arg = readAbiUInt(abiArgs, ai);
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
                // x/X
                else if (c == 120 || c == 88) {
                    index = writeUIntHex(buffer, index, arg, w == 0 ? 1 : w, c == 88);
                }
                // s/S
                else if (c == 115 || c == 83) {
                    index = writeAbiString(buffer, index, abiArgs, arg, w == 0 ? 31 : w, c == 83 ? 1 : 0);
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
                ai += 32;
            }
        }

        while (pi < i) {
            buffer[index++] = format[pi++];
        }

        return index;
    }

    /// @dev Read uint from abi encoded data
    /// @param data abi encoded data
    /// @param index start index in data
    /// @return v Decoded result
    function readAbiUInt(bytes memory data, uint index) internal pure returns (uint v) {
        // uint v = 0;
        // for (uint i = 0; i < 32; ++i) {
        //     v = (v << 8) | uint(uint8(data[index + i]));
        // }
        // return v;
        assembly {
            v := mload(add(add(data, 0x20), index))
        }
    }

    /// @dev Read string from abi encoded data
    /// @param data abi encoded data
    /// @param index start index in data
    /// @return Decoded result
    function readAbiString(bytes memory data, uint index) internal pure returns (string memory) {
        return string(segment(data, index + 32, readAbiUInt(data, index)));
    }

    /// @dev Read string from abi encoded data and write to buffer
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param data Target abi encoded data
    /// @param start Index of string in abi data
    /// @param count Count of string. if length not enough, use remain.
    /// @param charCase 0: original case, 1: upper case, 2: lower case
    /// @return New index in buffer
    function writeAbiString(
        bytes memory buffer, 
        uint index, 
        bytes memory data, 
        uint start, 
        uint count,
        uint charCase
    ) internal pure returns (uint) 
    {
        uint length = readAbiUInt(data, start);
        if (count > length) {
            count = length;
        }
        uint i = 0;
        start += 32;
        while (i < count) {
            uint c = uint(uint8(data[start + i]));
            if (charCase == 1 && c >= 97 && c <= 122) {
                c -= 32;
            } else if (charCase == 2 && c >= 65 && c <= 90) {
                c -= 32;
            }
            buffer[index + i] = bytes1(uint8(c));
            ++i;
        }
        return index + i;
    }
}