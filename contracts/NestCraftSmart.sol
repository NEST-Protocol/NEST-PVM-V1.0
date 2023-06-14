// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./NestCraft.sol";

/// @dev NestCraft implementation
contract NestCraftSmart is NestCraft {

    // TODO: Support variables: dT, blockNumber, timestamp
    // TODO: When the actual value of the order is lower than a value, it can be liquidated?
    uint constant $EOF          = 0x00;         // 0
    uint constant $SPC          = 0x20;         // SPACE
    uint constant $LBR          = 0x28;         // (
    uint constant $RBR          = 0x29;         // )
    uint constant $MUL          = 0x2A;         // *
    uint constant $ADD          = 0x2B;         // +
    uint constant $CMA          = 0x2C;         // ,
    uint constant $SUB          = 0x2D;         // -
    uint constant $DOT          = 0x2E;         // .
    uint constant $DIV          = 0x2F;         // /
    uint constant $0            = 0x30;         // 0
    uint constant $9            = 0x39;         // 9
    uint constant $COL          = 0x3A;         // :
    uint constant $PA           = 0x40;         // @
    uint constant $A            = 0x41;         // A
    uint constant $Z            = 0x5A;         // Z
    uint constant $BZ           = 0x5B;         // [
    uint constant $Pa           = 0x60;         // `
    uint constant $a            = 0x61;         // a
    uint constant $z            = 0x7A;         // z
    uint constant $Bz           = 0x7B;         // {

    // Status
    uint constant S_NORMAL      = 0x0000;
    uint constant S_INTEGER     = 0x0101;
    uint constant S_DECIMAL     = 0x0102;
    uint constant S_IDENTIFIER  = 0x0103;
    uint constant S_BRACKET     = 0x0104;
    uint constant S_FUNCTION    = 0x0105;
    uint constant S_STRING      = 0x0106;       // consider a string can contains bracket
    uint constant S_OPERATOR    = 0x0201;
    //uint constant S_CALCULATE   = 0x0301;
    uint constant S_INVALID     = 0xFFFF;

    uint constant PI            = 3141592653590000000;
    uint constant E             = 2718281828459000000;
    
    /// @dev Evaluate expression value
    /// @param expr Target expression
    /// @param oi Order information
    function evaluate(
        mapping(uint=>uint) storage context,
        string memory expr, 
        uint oi
    ) internal virtual view override returns (int value) {
        uint start = 0;
        assembly {
            start := add(expr, 0x20)
        }
        (value,,) = _evaluatePart(context, oi, 0, 0x0000, start, start + bytes(expr).length);
    } 

    // Calculate left value with remain expression, and return value
    function _evaluatePart(
        // Identifier context
        mapping(uint=>uint) storage context,
        // Order information
        uint oi,
        // Previous value
        int pv,
        // Previous operator
        uint po,
        // Pointer to string expression start
        uint start,
        // Pointer to string expression end
        uint end
        // result values
    ) internal view returns (int cv, uint co, uint index) {
        // Args
        int[4] memory args;
        uint argIndex = 0;
        // Temp value
        uint temp1 = 0;
        // Machine state
        uint state = S_NORMAL;

        // Load character
        uint c = $EOF;
        assembly {
            index := start
            if lt(index, end) { c := shr(248, mload(index)) }
        }

        // Loop with each character
        for (; ; )
        {
            // normal state, find part start
            if (state == S_NORMAL)
            {
                if (c > $DIV)
                {
                    // integer
                    if (c < $COL) {
                        unchecked { 
                            cv = int(c - $0); 
                            temp1 = 0;
                            state = S_INTEGER;
                        }
                    } 
                    // identifier
                    else if (c > $PA && (c < $BZ || (c > $Pa && c < $Bz))) {
                        // temp1: identifier
                        temp1 = c;
                        state = S_IDENTIFIER;
                    } else { revert("PVM:expression invalid"); }
                }
                // left bracket
                else if (c == $LBR)
                {
                    unchecked {
                        // temp1: bracket counter
                        // start: left index
                        temp1 = 1;
                        start = index + 1;
                        state = S_BRACKET;
                    }
                }
                // end of file, break
                else if (c == $EOF) { co = 0x0000; break; }
                // Ignore space, else error
                else if (c != $SPC) { revert("PVM:expression invalid"); }
            }
            // integer
            else if (state == S_INTEGER)
            {
                // 0 ~ 9, parse integer
                if (c > $DIV && c < $COL)
                {
                    unchecked {
                        // Process decimal
                        if (temp1 > 0) {
                            require(temp1 > 1, "PVM:too many decimals");
                            temp1 /= 10;
                        }
                    }
                    cv = cv * 10 + int(c - $0);
                }
                // decimal
                else if (c == $DOT) {
                    require(temp1 == 0, "PVM:too many points");
                    // temp1: decimals
                    temp1 = DECIMALS;
                }
                // else, parse end
                else
                {
                    cv *= int(temp1 > 0 ? temp1 : DECIMALS);
                    // parse end, find next operator
                    state = S_OPERATOR;
                    continue;
                }
            }
            // identifier
            else if (state == S_IDENTIFIER) {
                // Lower letter, Upper letter or number
                if (c > $DIV && (c < $COL || (c > $PA && (c < $BZ || (c > $Pa && c < $Bz))))) {
                    require(temp1 <= 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "PVM:identifier too long");
                    temp1 = (temp1 << 8) | c;
                } 
                // left bracket, function
                else if (c == $LBR) {
                    unchecked {
                        // cv: bracket counter
                        // temp1: identifier
                        // start: left index
                        cv = 1;
                        start = index + 1;
                        state = S_FUNCTION;
                    }
                }
                // Identifier end
                else {
                    // TODO: Implement var, INestPVMFunction, normal function
                    // TODO: INestPVMFunction query once?
                    // type(8)|data(248)
                    // type: 0 int, 1 call address, 2 delegate call address

                    // Find identifier in context
                    start = context[temp1];

                    // Normal integer
                    if ((start >> 248) == 0x01) {
                        // TODO: sign may lost?
                        cv = int(start & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                    } 
                    // Address staticcall
                    else if ((start >> 248) == 0x02) {
                        // staticcall
                        cv = INestPVMFunction(address(uint160(start))).calculate(abi.encode(temp1));
                    } else {
                        revert("PVM:identifier not exist");
                    }

                    state = S_OPERATOR;
                    continue;
                }
            }
            // left bracket
            else if (state == S_BRACKET)
            {
                unchecked {
                    // TODO: consider bracket in "" and ''
                    // find right bracket
                    if (c == $RBR)
                    {
                        if (--temp1 == 0)
                        {
                            // calculate sub expression in brackets
                            (cv, co,) = _evaluatePart(context, oi, 0, 0x0000, start, index);
                            require(co > 0x0000, "PVM:expression is blank");
                            // calculate end, find next operator
                            state = S_OPERATOR;
                        }
                    }
                    else if (c == $LBR)
                    {
                        ++temp1;
                    }
                }
            }
            // function
            else if (state == S_FUNCTION) {
                unchecked {
                    // temp1: identifier
                    // start: left index
                    // cv: bracket counter
                    if (c == $CMA && cv == 1) {
                        // index is always equals to end when call end
                        (args[argIndex++], co,) = _evaluatePart(context, oi, 0, 0x0000, start, index);
                        require(co > 0x0000, "PVM:argument expression is blank");
                        start = index + 1;
                    } else if (c == $RBR && --cv == 0) {
                        // index is always equals to end when call end
                        (args[argIndex], co,) = _evaluatePart(context, oi, 0, 0x0000, start, index);
                        if (co > 0x0000) { ++argIndex; }
                        else { require(argIndex == 0, "PVM:arg expression is blank"); }

                        // do call
                        cv = _call(context, oi, temp1, args, argIndex);

                        argIndex = 0;
                        state = S_OPERATOR;
                    } else if (c == $LBR) {
                        ++cv;
                    } 
                }
            }
            // find next operator
            else if (state == S_OPERATOR)
            {
                // ignore space
                if (c != $SPC)
                {
                    unchecked {
                        // next operator, + - * / **
                        if (c == $ADD) { co = 0x1001; } else 
                        if (c == $SUB) { co = 0x1002; } else 
                        if (c == $MUL) {
                            //if (index + 1 < end && uint(uint8(expr[index + 1])) == $MUL) { ++index; co = 0x3001; }
                            //else { co = 0x2001; }
                            assembly {
                                switch and(lt(add(index, 1), end), eq(shr(248, mload(add(index, 1))), $MUL))
                                case true {
                                    index := add(index, 1)
                                    co := 0x3001
                                }
                                case false { 
                                    co := 0x2001
                                }
                            }
                        } else 
                        if (c == $DIV) { co = 0x2002; } else 
                        // eof, next operator
                        if (c == $EOF) { co = 0x0001; }
                        else { revert("PVM:expression invalid"); }

                        // assembly {
                        //     switch c
                        //     case 0x2b { co := 0x1001 }
                        //     case 0x2d { co := 0x1002 }
                        //     case 0x2a { co := 0x2001 }
                        //     case 0x2f { co := 0x2002 }
                        //     case 0x00 { co := 0x0001 }
                        //     default { revert(0, 0) }
                        // }

                        // While co > po, calculate with next
                        while ((co >> 8) > (po >> 8))
                        {
                            // test expr1: 4*2**3+1
                            // test expr2: 5+4*2**3+1

                            // in S_OPERATOR state, index doesn't increased
                            // move to next and evaluate
                            (cv, co, index) = _evaluatePart(context, oi, cv, co, ++index, end);
                            
                            // now co is the last operator parsed by evaluatedPart just called
                        }
                    }

                    // Calculate with pv
                    if (po == 0x1001) { pv += cv; } else 
                    if (po == 0x1002) { pv -= cv; } else 
                    if (po == 0x2001) { pv = pv * cv / int(DECIMALS); } else 
                    if (po == 0x2002) { pv = pv * int(DECIMALS) / cv; } else 
                    if (po == 0x3001) { pv = pow(pv, cv); } else 
                    // po is 0, means this is the first part, pv = cv
                    if (po == 0x0000) { pv = cv; }
                    
                    break;
                }
            }
            // not implement
            else
            {
                revert("PVM:not implement");
            }

            // Load character
            assembly {
                index := add(index, 1)
                switch lt(index, end)
                case true  { c := shr(248, mload(index)) }
                case false { c := $EOF }
            }
        }

        cv = pv;
    }

    // Call function
    function _call(
        mapping(uint=>uint) storage context,
        uint oi,
        uint identifier,
        int[4] memory args,
        uint argIndex
    ) internal view returns (int) {
        // Internal call
        if (argIndex == 0) {
            //if (identifier == 0x0000626E) { return  bn(); } else 
            //if (identifier == 0x00007473) { return  ts(); } else 
            if (identifier == 0x00006F62) { return  ob(); } 
        } else if (argIndex == 1) {
            if (identifier == 0x00006F70) { return  op(args[0]); } else 
            if (identifier == 0x00006C6E) { return  ln(args[0]); } else 
            if (identifier == 0x00657870) { return exp(args[0]); } else 
            if (identifier == 0x00666C6F) { return flo(args[0]); } else 
            if (identifier == 0x0063656C) { return cel(args[0]); } else 
            if (identifier == 0x00006D31) { return  m1(oi, args[0]); } else 
            if (identifier == 0x00006D32) { return  m2(oi, args[0]); } else 
            if (identifier == 0x00006D33) { return  m3(oi, args[0]); } else 
            if (identifier == 0x00006D34) { return  m4(oi, args[0]); } else 
            if (identifier == 0x00006D35) { return  m5(oi, args[0]); } 
        } else if (argIndex == 2) {
            if (identifier == 0x006C6F67) { return log(args[0], args[1]); } else
            if (identifier == 0x00706F77) { return pow(args[0], args[1]); } else 
            if (identifier == 0x006F6176) { return oav(args[0], args[1]); } 
        } 

        uint value = context[identifier];
        // Custom function staticcall
        require((value >> 248) == 0x05, "PVM:not staticcall function");

        // Custom static call
        uint temp;
        assembly {
            // Allocate memory and return pointer to first byte
            function allocate(size) -> ptr {
                ptr := mload(0x40)
                // Memory are allocated many times, the free memory pointer is impossible be 0 
                //if iszero(ptr) { ptr := 0x60 }
                mstore(0x40, add(ptr, size))
            }

            // Calculate length of identifier
            let index := 0
            for { temp := identifier } gt(temp, 0) { temp := shr(8, temp) } {
                index := add(index, 1)
            }

            // Calculate length of signature
            temp := add(index, 2)
            if gt(argIndex, 0) { temp := add(temp, sub(mul(argIndex, 7), 1)) }

            // Calculate length of abi arguments
            let size := add(4, shl(5, argIndex))

            // Create memory buffer
            let buf := 0
            switch gt(size, temp) 
            case true  { buf := allocate(size) }
            case false { buf := allocate(temp) }

            // Generate signature
            // Function name
            buf := add(buf, index)
            for { } gt(identifier, 0) { identifier := shr(8, identifier) } {
                buf := sub(buf, 1)
                mstore8(buf, and(identifier, 0xFF))
            }
            buf := add(buf, index)

            // Left bracket
            mstore8(buf, $LBR)
            buf := add(buf, 1)

            // Type of arguments
            for { index := 0 } lt(index, argIndex) { index := add(index, 1) } {
                if gt(index, 0) { 
                    mstore8(buf, $CMA)
                    buf := add(buf, 1)
                } 
                // int256
                mstore8(add(buf, 0), 0x69)        // i
                mstore8(add(buf, 1), 0x6E)        // n
                mstore8(add(buf, 2), 0x74)        // t
                mstore8(add(buf, 3), 0x32)        // 2
                mstore8(add(buf, 4), 0x35)        // 5
                mstore8(add(buf, 5), 0x36)        // 6
                buf := add(buf, 6)
            }

            // Right bracket
            mstore8(buf, $RBR)
            buf := add(buf, 1)

            // 4 bytes signature
            buf := sub(buf, temp)
            mstore(buf, keccak256(buf, temp)) 

            // Generate abi arguments
            argIndex := shl(5, argIndex)
            for { index := add(buf, 0x04) } gt(argIndex, 0) { } { 
                argIndex := sub(argIndex, 0x20)
                mstore(add(index, argIndex), mload(add(args, argIndex))) 
            }

            // staticcall
            temp := staticcall(gas(), value, buf, size, 0x00, 0x20)
            if iszero(temp) { revert(add("PVM:call failed", 0x20), 15) }
            temp := mload(0x00)
        }

        return int(temp);
    }

    // Only for test
    function _toString(bytes memory expr, uint start, uint end) internal pure returns (string memory) {
        uint length = end - start;
        bytes memory res = new bytes(length);
        for (uint i = 0; i < length; ++i) {
            res[i] = expr[start + i];
        }
        return string(res);
    }

    // Only for test
    function _toHexString(bytes memory data) internal pure returns (string memory) {
        unchecked {
            bytes memory buffer = new bytes((data.length << 1) + 2);
            buffer[0] = bytes1(uint8(0x30));    // 0
            buffer[1] = bytes1(uint8(0x78));    // x
            uint index = 2;
            for (uint i = 0; i < data.length; ++i) {
                uint v = uint(uint8(data[i]));
                buffer[index++] = bytes1(uint8(_hex(v >> 4)));
                buffer[index++] = bytes1(uint8(_hex(v & 15)));
            }
            return string(buffer);
        }
    }

    function _hex(uint v) internal pure returns (uint x) {
        unchecked {
            if (v < 10) return v + 48;
            return v + 87;
        }
    }
}
