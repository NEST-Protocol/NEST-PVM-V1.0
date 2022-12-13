// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/ABDKMath64x64.sol";
import "./libs/TransferHelper.sol";

import "./interfaces/INestPVMFunction.sol";
import "./interfaces/INestFuturesWithPrice.sol";

import "./custom/NestFrequentlyUsed.sol";

import "hardhat/console.sol";

/// @dev NestPVM implementation
contract NestPVM is NestFrequentlyUsed, INestPVMFunction {

    // TODO: Support variables: dT, blockNumber, timestamp
    // TODO: When the actual value of the order is lower than a value, it can be liquidated?
    uint constant $A            = 0x41;         // A
    uint constant $Z            = 0x5A;         // Z
    uint constant $a            = 0x61;         // a
    uint constant $z            = 0x7A;         // z
    uint constant $0            = 0x30;         // 0
    uint constant $9            = 0x39;         // 9
    uint constant $ADD          = 0x2B;         // +
    uint constant $SUB          = 0x2D;         // -
    uint constant $MUL          = 0x2A;         // *
    uint constant $DIV          = 0x2F;         // /
    uint constant $COL          = 0x3A;         // :
    uint constant $LBR          = 0x28;         // (
    uint constant $RBR          = 0x29;         // )
    uint constant $SPC          = 0x20;         // SPACE
    uint constant $DOT          = 0x2E;         // .
    uint constant $CMA          = 0x2C;         // ,
    uint constant $EOF          = 0x00;         // 0

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

    uint constant DECIMALS      = 1 ether;
    uint constant PI            = 3141592653590000000;
    uint constant E             = 2718281828459000000;

    event Buy(string expr, address owner, uint openBlock, uint shares, uint index);

    /// @dev PVM Order data structure
    struct PVMOrder {
        address owner;
        uint32 openBlock;
        uint32 shares;
        uint32 index;
        string expr;
    }

    // Identifier map
    mapping(uint=>uint) _identifierMap;

    // PVM Order array
    PVMOrder[] _orders;

    // TODO: Only for test
    address _nestFutures;
    function setNestFutures(address nestFutures) external onlyGovernance {
        _nestFutures = nestFutures;
    }

    // type(8)|data(248)
    function _register(string memory key, uint value) internal {
        _identifierMap[_fromKey(key)] = value;
    }

    // Calculate identifier from key
    function _fromKey(string memory key) internal pure returns (uint identifier) {
        bytes memory bKey = bytes(key);
        identifier = 0;
        for (uint i = 0; i < bKey.length; ++i) {
            identifier = (identifier << 8) | uint(uint8(bKey[i]));
        }
    }

    /// @dev Register to identifier map
    /// @param key Target key
    /// @param value Target value, type(8)|data(248)
    function register(string memory key, uint value) public onlyGovernance {
        _register(key, value);
    }

    /// @dev Register INestPVMFunction address
    /// @param key Target key
    /// @param addr Address of target INestPVMFunction implementation contract
    function registerAddress(string memory key, address addr) external {
        register(key, (0x02 << 248) | uint(uint160(addr)));
    }

    /// @dev Register custom staticcall function
    /// @param functionName Name of target function
    /// @param addr Address of implementation contract
    function registerStaticCall(string memory functionName, address addr) external {
        uint identifier = _fromKey(functionName);
        require(_identifierMap[identifier] == 0, "PVM:identifier exists");
        _identifierMap[identifier] = (0x05 << 248) | uint(uint160(addr));
    }

    /// @dev Find the mint requests of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return orderArray Matched PVMOrder array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (PVMOrder[] memory orderArray) {
        orderArray = new PVMOrder[](count);
        // Calculate search region
        PVMOrder[] storage orders = _orders;
        // Loop from start to end
        uint end = 0;
        // start is 0 means Loop from the last item
        if (start == 0) {
            start = orders.length;
        }
        // start > maxFindCount, so end is not 0
        if (start > maxFindCount) {
            end = start - maxFindCount;
        }
        
        // Loop lookup to write qualified records to the buffer
        for (uint index = 0; index < count && start > end;) {
            PVMOrder memory order = orders[--start];
            if (order.owner == owner) {
                orderArray[index++] = order;
            }
        }
    }

    /// @dev List mint requests
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of PVMOrder
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (PVMOrder[] memory orderArray) {
        // Load mint requests
        PVMOrder[] storage orders = _orders;
        // Create result array
        orderArray = new PVMOrder[](count);
        uint length = orders.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                orderArray[i++] = orders[--index];
            }
        } 
        // Positive order
        else {
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                orderArray[i++] = orders[index++];
            }
        }
    }

    /// @dev Calculate value
    /// @dev byte array of arguments encoded by abi.encode()
    function calculate(bytes memory abiArgs) external view override returns (int) {
        uint v = abi.decode(abiArgs, (uint));
        uint pairIndex = (v & 0xFF) - 0x30;
        uint[] memory prices = INestFuturesWithPrice(_nestFutures).listPrice(pairIndex, 0, 1, 0);
        return int(prices[2]);
    }

    /// @dev Estimate the value of expression
    /// @param expr Target expression
    /// @return value Estimated value
    function estimate(string memory expr) external view returns (int value) {
        //return evaluate(bytes(expr), 0, bytes(expr).length);
        (value,,) = _evaluatePart(_identifierMap, 0, 0x0000, bytes(expr), 0, bytes(expr).length);
    }

    // TODO: Make expression as a product and can reuse?

    /// @dev Buy a product
    /// @param expr Target expression
    function buy(string memory expr) external {
        (int value,,) = _evaluatePart(_identifierMap, 0, 0x0000, bytes(expr), 0, bytes(expr).length);
        require(value > 0, "PVM:expression value must > 0");
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(value));

        emit Buy(expr, msg.sender, block.number, 1, _orders.length);
        _orders.push(PVMOrder(msg.sender, uint32(block.number), uint32(1), uint32(_orders.length), expr));
    }

    /// @dev Sell a order
    /// @param index Index of target order
    function sell(uint index) external {
        PVMOrder memory order = _orders[index];
        require(msg.sender == order.owner, "PVM:must owner");

        string memory expr = order.expr;
        (int value,,) = _evaluatePart(_identifierMap, 0, 0x0000, bytes(expr), 0, bytes(expr).length);

        value = value * int(uint(order.shares));
        require(value > 0, "PVM:no balance");
        _orders[index].shares = uint32(0);
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, msg.sender, uint(value));
    }

    /// @dev block number
    /// @return Current block number, 18 decimals
    function bn() public view returns (int) {
        return int(block.number * DECIMALS);
    }

    /// @dev timestamp
    /// @return Current timestamp, 18 decimals
    function ts() public view returns (int) {
        return int(block.timestamp * DECIMALS);
    }

    // open block
    function ob() public pure returns (int) {
        revert("PVM:open block not implement");
    }

    /// @dev oracle price
    /// @param pairIndex pairIndex of target token, 18 decimals
    /// @return Latest oracle price, 18 decimals
    function op(int pairIndex) public view returns (int) {
        uint pi = uint(pairIndex) / DECIMALS;
        require(pi < 3, "PVM:pairIndex must < 3");
        return int(INestFuturesWithPrice(_nestFutures).listPrice(pi, 0, 1, 0)[2]);
    }

    /// @dev Calculate oracle average price
    /// @param pairIndex pairIndex of target token, 18 decimals
    /// @param count Indicate number of latest price, 18 decimals
    /// @return v average price, 18 decimals
    function oav(int pairIndex, int count) public view returns (int v) {
        unchecked {
            uint pi = uint(pairIndex) / DECIMALS;
            uint n = uint(count) / DECIMALS;
            require(pi < 3, "PVM:pairIndex must < 3");
            uint[] memory prices = INestFuturesWithPrice(_nestFutures).listPrice(pi, 0, n, 0);
            uint total = 0;
            for (uint i = 0; i < n; ++i) {
                require(prices[i * 3 + 1] > 0, "PVM:no such price");
                total += prices[i * 3 + 2];
            }

            v = int(total / n);
        }
    }

    /// @dev Calculate ln(v)
    /// @param v input value, 18 decimals
    /// @return log value by e, 18 decimals
    function ln(int v) public pure returns (int) {
        return _toDEC(ABDKMath64x64.ln(_toX64(v)));
    }

    /// @dev Pow based e
    /// @param v input value, 18 decimals
    /// @return pow based e value, 18 decimals
    function exp(int v) public pure returns (int) {
        return _toDEC(ABDKMath64x64.exp(_toX64(v)));
    }

    /// @dev floor value
    /// @param v input value, 18 decimals
    /// @return floor value, 18 decimals
    function flo(int v) public pure returns (int) {
        unchecked {
            if (v < 0) { return -cel(-v); }
            return v / int(DECIMALS) * int(DECIMALS);
        }
    }

    /// @dev ceil value
    /// @param v input value, 18 decimals
    /// @return ceil value, 18 decimals
    function cel(int v) public pure returns (int) {
        if (v < 0) { return -flo(-v); }
        return (v + int(DECIMALS - 1)) / int(DECIMALS) * int(DECIMALS);
    }

    /// @dev Calculate log, based on b
    /// @param a input value, 18 decimals
    /// @param b base value, 18 decimals
    /// @return v log value, 18 decimals
    function log(int a, int b) public pure returns (int v) {
        v = _toDEC(ABDKMath64x64.div(ABDKMath64x64.ln(_toX64(a)), ABDKMath64x64.ln(_toX64(b))));
    }

    /// Calculate a ** b
    /// @param a base value, 18 decimals
    /// @param b index value, 18 decimals
    /// @return v a ** b, 18 decimals
    function pow(int a, int b) public pure returns (int v) {
        if (b % int(DECIMALS) == 0) {
            // Negative exponent
            if (b < 0) {
                return int(DECIMALS) * int(DECIMALS) / pow(a, -b);
            }
            v = int(DECIMALS);
            while (b > 0) {
                v = v * a / int(DECIMALS);
                unchecked { b -= int(DECIMALS); }
            }
        } else {
            v = _toDEC(ABDKMath64x64.exp(ABDKMath64x64.mul(ABDKMath64x64.ln(_toX64(a)), _toX64(b))));
        }
    }

    // Calculate left value with remain expression, and return value
    function _evaluatePart(
        // Identifier context
        mapping(uint=>uint) storage context,
        // Previous value
        int pv,
        // Previous operator
        uint po,
        // String expression
        bytes memory expr,
        // Index of expression start in expr
        uint start,
        // Index of expression end in expr
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
        // Loop index
        index = start;

        // Load character
        uint c = $EOF;
        uint pExp = 0;
        assembly {
            pExp := add(expr, 0x20)
            if lt(index, end) { c := shr(248, mload(add(pExp, index))) }
        }

        // Loop with each character
        for (; ; )
        {
            // normal state, find part start
            if (state == S_NORMAL)
            {
                if (c >= $0)
                {
                    // integer
                    if (c <= $9) {
                        unchecked { 
                            cv = int(c - $0); 
                            temp1 = 0;
                            state = S_INTEGER;
                        }
                    } 
                    // identifier
                    else if (c >= $A && (c <= $Z || (c >= $a && c <= $z))) {
                        // temp1: identifier
                        temp1 = uint(c);
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
                if (c >= $0 && c <= $9)
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
                if (c >= $0 && (c <= $9 || (c >= $A && (c <= $Z || (c >= $a && c <= $z))))) {
                //if ((c >= $A && c <= $Z) || (c >= $a && c <= $z) || (c >= $0 && c <= $9)) {
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

                    // Find identifer in context
                    // Here start means tmp value
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
                            (cv, co,) = _evaluatePart(context, 0, 0x0000, expr, start, index);
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
                        (args[argIndex++], co,) = _evaluatePart(context, 0, 0x0000, expr, start, index);
                        require(co > 0x0000, "PVM:argument expression is blank");
                        start = index + 1;
                    } else if (c == $RBR && --cv == 0) {
                        // index is always equals to end when call end
                        (args[argIndex], co,) = _evaluatePart(context, 0, 0x0000, expr, start, index);
                        if (co > 0x0000) { ++argIndex; }
                        else { require(argIndex == 0, "PVM:arg expression is blank"); }

                        // do call
                        cv = _call(context, temp1, args, argIndex);

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
                            if (index + 1 < end && uint(uint8(expr[index + 1])) == $MUL) { ++index; co = 0x3001; }
                            else { co = 0x2001; }
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
                            (cv, co, index) = _evaluatePart(context, cv, co, expr, ++index, end);
                            
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
                case true  { c := shr(248, mload(add(pExp, index))) }
                case false { c := $EOF }
            }
        }

        cv = pv;
    }

    // Call function
    function _call(
        mapping(uint=>uint) storage context,
        uint identifier,
        int[4] memory args,
        uint argIndex
    ) internal view returns (int) {
        // // Internal call
        // if (argIndex == 0) {
        //     if (identifier == 0x0000626E) { return  bn(); } else 
        //     if (identifier == 0x00007473) { return  ts(); } else 
        //     if (identifier == 0x00006F62) { return  ob(); } 
        // } else if (argIndex == 1) {
        //     if (identifier == 0x00006F70) { return  op(args[0]); } else 
        //     if (identifier == 0x00006C6E) { return  ln(args[0]); } else 
        //     if (identifier == 0x00657870) { return exp(args[0]); } else 
        //     if (identifier == 0x00666C6F) { return flo(args[0]); } else 
        //     if (identifier == 0x0063656C) { return cel(args[0]); } 
        // } else if (argIndex == 2) {
        //     if (identifier == 0x006C6F67) { return log(args[0], args[1]); } else
        //     if (identifier == 0x00706F77) { return pow(args[0], args[1]); } else 
        //     if (identifier == 0x006F6176) { return oav(args[0], args[1]); } 
        // } 

        uint value = context[identifier];
        // Custom function staticcall
        require((value >> 248) == 0x05, "PVM:not staticcall function");

        // Custom static call
        uint flag;
        uint data;
        assembly {
            // Allocate memory and return pointer to first byte
            function allocate(size) -> ptr {
                ptr := mload(0x40)
                if iszero(ptr) { ptr := 0x60 }
                mstore(0x40, add(ptr, size))
            }

            // Calculate length of identifier
            let index := 0
            for { let uid := identifier } gt(uid, 0) { uid := shr(8, uid) } {
                index := add(index, 1)
            }

            // Calculate length of signature
            let length := add(index, 2)
            if gt(argIndex, 0) { length := add(length, sub(mul(argIndex, 7), 1)) }

            // Calculate length of abi arguments
            let abiLength := add(4, shl(5, argIndex))

            // Create memory buffer
            let pBuf := 0
            switch gt(abiLength, length) 
            case true  { pBuf := allocate(abiLength) }
            case false { pBuf := allocate(length) }

            // Generate signature
            // Function name
            pBuf := add(pBuf, index)
            for { } gt(identifier, 0) { } {
                pBuf := sub(pBuf, 1)
                mstore8(pBuf, and(identifier, 0xFF))
                identifier := shr(8, identifier)
            }
            pBuf := add(pBuf, index)

            // Left bracket
            mstore8(pBuf, $LBR)
            pBuf := add(pBuf, 1)

            // Type of arguments
            for { let i := 0 } lt(i, argIndex) { i := add(i, 1) } {
                if gt(i, 0) { 
                    mstore8(pBuf, $CMA)
                    pBuf := add(pBuf, 1)
                } 
                // int256
                mstore8(add(pBuf, 0), 0x69)        // i
                mstore8(add(pBuf, 1), 0x6E)        // n
                mstore8(add(pBuf, 2), 0x74)        // t
                mstore8(add(pBuf, 3), 0x32)        // 2
                mstore8(add(pBuf, 4), 0x35)        // 5
                mstore8(add(pBuf, 5), 0x36)        // 6
                pBuf := add(pBuf, 6)
            }

            // Right bracket
            mstore8(pBuf, $RBR)
            pBuf := add(pBuf, 1)

            // 4 bytes signature
            pBuf := sub(pBuf, length)
            mstore(pBuf, keccak256(pBuf, length)) 

            // Generate abi arguments
            argIndex := shl(5, argIndex)
            for { let j := add(pBuf, 0x04) } gt(argIndex, 0) { } { 
                argIndex := sub(argIndex, 0x20)
                mstore(add(j, argIndex), mload(add(args, argIndex))) 
            }

            // staticcall
            flag := staticcall(0x80000, value, pBuf, abiLength, 0x00, 0x20)
            data := mload(0x00)
        }

        require(flag == 1, "PVM:call failed");
        return int(data);
    }

    // Convert 18 decimals to 64 bits
    function _toX64(int v) internal pure returns (int128) {
        v = v * 0x10000000000000000 / int(DECIMALS);
        require(v >= type(int128).min && v <= type(int128).max, "PVM:overflow");
        return int128(v);
    }

    // Convert 64 bits to 18 decimals
    function _toDEC(int128 v) internal pure returns (int) {
        return int(v) * int(DECIMALS) >> 64;
    }

    // Get key length
    function _keyLength(uint uid) internal pure returns (uint length) {
        unchecked {
            length = 0;
            while (uid > 0) {
                ++length;
                uid >>= 8;
            }
        }
    }

    // Convert uint identifier to string identifier
    function _writeKey(uint uid, bytes memory buffer, uint index) internal pure returns (uint newIndex) {
        unchecked {
            newIndex = index;
            while (uid > 0) {
                buffer[--index] = bytes1(uint8(uid & 0xFF));
                uid >>= 8;
            }
        }
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
