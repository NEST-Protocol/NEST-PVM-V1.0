// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/PVM.sol";
import "./libs/ABDKMath64x64.sol";
import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";

import "./interfaces/INestPVMFunction.sol";
import "./interfaces/INestFuturesWithPrice.sol";

import "./custom/ChainParameter.sol";
import "./custom/NestFrequentlyUsed.sol";
import "./custom/NestPriceAdapter.sol";

import "hardhat/console.sol";

/// @dev Futures
contract NestPVM is ChainParameter, NestFrequentlyUsed, NestPriceAdapter, INestPVMFunction {

    struct PVMOrder {
        address owner;
        uint32 openBlock;
        uint32 shares;
        uint32 index;
        string expr;
    }

    event Buy(string expr, address owner, uint openBlock, uint shares, uint index);

    // TODO: Support variables: dT, blockNumber, timestamp
    // TODO: Gas save, 1. use uint instead uint8
    uint8 constant $A = uint8(0x41);        // A
    uint8 constant $Z = uint8(0x5a);        // Z
    uint8 constant $a = uint8(0x61);        // a
    uint8 constant $z = uint8(0x7a);        // z
    uint8 constant $0 = uint8(0x30);        // 0
    uint8 constant $9 = uint8(0x39);        // 9
    uint8 constant $ADD = uint8(0x2b);      // +
    uint8 constant $SUB = uint8(0x2d);      // -
    uint8 constant $MUL = uint8(0x2a);      // *
    uint8 constant $DIV = uint8(0x2f);      // /
    uint8 constant $COL = uint8(0x3a);      // :
    uint8 constant $LBR = uint8(0x28);      // (
    uint8 constant $RBR = uint8(0x29);      // )
    uint8 constant $SPC = uint8(0x20);      // SPACE
    uint8 constant $DOT = uint8(0x2e);      // .
    uint8 constant $CMA = uint8(0x2c);      // ,
    uint8 constant $EOF = uint8(0x00);      // 0

    // Status
    uint constant S_NORMAL = 0x0000;
    uint constant S_INTEGER = 0x0101;
    uint constant S_DECIMAL = 0x0102;
    uint constant S_IDENTIFIER = 0x0103;
    uint constant S_BRACKET = 0x0104;
    uint constant S_FUNCTION = 0x0105;
    uint constant S_STRING = 0x0106;        // consider a string can contain's bracket
    uint constant S_OPERATOR = 0x0201;
    uint constant S_CALCULATE = 0x0301;

    uint constant DECIMALS = 1 ether;
    uint constant PI = 3141592653590000000;
    uint constant E  = 2718281828459000000;

    mapping(uint=>uint) _functionMap;

    PVMOrder[] _orders;

    address _nestFutures;

    function setNestFutures(address nestFutures) external onlyGovernance {
        _nestFutures = nestFutures;
    }

    // type(8)|data(248)
    function _register(string memory key, uint value) internal {
        _functionMap[_fromKey(key)] = value;
    }

    function _fromKey(string memory key) internal pure returns (uint idtf) {
        bytes memory bkey = bytes(key);
        idtf = 0;
        for (uint i = 0; i < bkey.length; ++i) {
            idtf = (idtf << 8) | uint(uint8(bkey[i]));
        }
    }

    // type(8)|data(248)
    function register(string memory key, uint value) public onlyGovernance {
        _register(key, value);
    }

    function registerAddress(string memory key, address addr) external {
        register(key, (0x02 << 248) | uint(uint160(addr)));
    }

    function registerStaticCall(string memory functionName, address addr) external {
        uint idtf = _fromKey(functionName);
        require(_functionMap[idtf] == 0, "PVM:identifier exists");
        _functionMap[idtf] = (0x05 << 248) | uint(uint160(addr));
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
        (value,,) = _evaluatePart(_functionMap, 0, 0x0000, bytes(expr), 0, bytes(expr).length);
    }

    // TODO: Make expression as a product and can reuse?

    /// @dev Buy a product
    /// @param expr Target expression
    function buy(string memory expr) external {
        (int value,,) = _evaluatePart(_functionMap, 0, 0x0000, bytes(expr), 0, bytes(expr).length);
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
        (int value,,) = _evaluatePart(_functionMap, 0, 0x0000, bytes(expr), 0, bytes(expr).length);

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
        if (v < 0) { revert("PVM:not inplement"); }
        return v / int(DECIMALS) * int(DECIMALS);
    }

    /// @dev ceil value
    /// @param v input value, 18 decimals
    /// @return ceil value, 18 decimals
    function cel(int v) public pure returns (int) {
        if (v < 0) { revert("PVM:not inplement"); }
        return (v + int(DECIMALS - 1))/ int(DECIMALS) * int(DECIMALS);
    }

    /// @dev Calculate log, based on b
    /// @param a input value, 18 decimals
    /// @param b base value, 18 decimals
    /// @return v log vlaue, 18 decimals
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
                b -= int(DECIMALS);
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
        uint temp1 = 0;
        uint temp2 = 0;
        uint state = S_NORMAL;

        // args
        uint argIndex = 0;
        int[4] memory args;
        // Current value
        cv = 0;
        // Current operator
        co = 0;
        // Index for loop each character
        index = start;

        uint8 c;
        // Load character
        // TODO: Use compare index and end to optimize?
        if (index < end) { c = uint8(expr[index]); } else { c = $EOF; }

        // Loop with each character
        for (; ; )
        {
            // normal state, find part start
            if (state == S_NORMAL)
            {
                // integer
                if (c >= $0 && c <= $9)
                {
                    cv = int(uint(c - $0));
                    state = S_INTEGER;
                }
                // identifier
                else if ((c >= $A && c <= $Z) || (c >= $a && c <= $z))
                {
                    // temp1: identifier
                    temp1 = uint(c);
                    state = S_IDENTIFIER;
                }
                // left bracket
                else if (c == $LBR)
                {
                    // temp1: bracket counter
                    // temp2: left index
                    temp1 = 1;
                    temp2 = index + 1;
                    state = S_BRACKET;
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
                    // Process decimal
                    if (temp1 > 0) {
                        require(temp1 > 1, "PVM:too many decimals");
                        temp1 /= 10;
                    }
                    cv = cv * 10 + int(uint(c - $0));
                }
                // decimal
                else if (c == $DOT) {
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
                if ((c >= $A && c <= $Z) || (c >= $a && c <= $z) || (c >= $0 && c <= $9)) {
                    require(temp1 <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "PVM:identifier too long");
                    temp1 = (temp1 << 8) | uint(c);
                } 
                // left bracket, function
                else if (c == $LBR) {
                    // temp1: identifier
                    // temp2: left index
                    // cv: bracket counter
                    temp2 = index + 1;
                    cv = 1;
                    state = S_FUNCTION;
                }
                // Identifier end
                else {
                    // TODO: Implement var, INestPVMFunction, normal function
                    // TODO: INestPVMFunction query once?
                    // type(8)|data(248)
                    // type: 0 int, 1 call address, 2 delegate call address

                    // Find identifer in context
                    temp2 = context[temp1];

                    // Normal integer
                    if ((temp2 >> 248) == 0x01) {
                        // TODO: sign may lost?
                        cv = int(temp2 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                    } 
                    // Address staticcall
                    else if ((temp2 >> 248) == 0x02) {
                        // staticcall
                        //cv = INestPVMFunction(address(uint160(temp2))).calculate(abi.encode(temp1));
                        (bool flag, bytes memory data) = address(uint160(temp2)).staticcall(abi.encodeWithSignature("calculate(bytes)", abi.encode(temp1)));
                        require(flag, "PVM:call failed");
                        cv = abi.decode(data, (int));
                    } 
                    // Address call
                    else if ((temp2 >> 248) == 0x03) {
                        // call
                    } 
                    // Address deledate call
                    else if ((temp2 >> 248) == 0x04) {
                        // delegatecall
                    } else {
                        revert("PVM:identifier not exist");
                    }

                    // Restore status
                    temp1 = 0;
                    temp2 = 0;
                    state = S_OPERATOR;
                    continue;
                }
            }
            // left bracket
            else if (state == S_BRACKET)
            {
                // TODO: consider bracket in "" and ''
                // find right bracket
                if (c == $RBR)
                {
                    if (--temp1 == 0)
                    {
                        // calculate sub expression in brackets
                        //cv = evaluate(expr, temp2, index);
                        (cv, co,) = _evaluatePart(context, 0, 0x0000, expr, temp2, index);
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
            // function
            else if (state == S_FUNCTION) {
                // temp1: identifier
                // temp2: left index
                // cv: bracket counter
                if (c == $CMA && cv == 1) {
                    // index is always equals to end when call end
                    (args[argIndex++], co, index) = _evaluatePart(context, 0, 0x0000, expr, temp2, index);
                    require(co > 0x0000, "PVM:argument expresion is blank");
                    temp2 = index + 1;
                } else if (c == $RBR && --cv == 0) {
                    // index is always equals to end when call end
                    (args[argIndex], co, index) = _evaluatePart(context, 0, 0x0000, expr, temp2, index);
                    // TODO: nop(3,) is ok?
                    if (co > 0x0000) { ++argIndex; }
                    else { require(argIndex == 0, "PVM:arg expression is blank");}

                    // do call
                    cv = _call(context, temp1, args, argIndex);
                    // Restore status
                    temp1 = 0;
                    temp2 = 0;
                    argIndex = 0;
                    state = S_OPERATOR;
                } else if (c == $LBR) {
                    ++cv;
                } //else if (c != $SPC) { }
            }
            // find next operator
            else if (state == S_OPERATOR)
            {
                // ignore space
                if (c != $SPC)
                {
                    // next operator, + - * / **
                    if (c == $ADD) { co = 0x1001; } else 
                    if (c == $SUB) { co = 0x1002; } else 
                    if (c == $MUL) {
                        if (index + 1 < end && uint8(expr[index + 1]) == $MUL) { ++index; co = 0x3001; }
                        else { co = 0x2001; }
                    } else 
                    if (c == $DIV) { co = 0x2002; } else 
                    // eof, next operator
                    if (c == $EOF) { co = 0x0001; }
                    else { revert("PVM:expression invalid"); }

                    state = S_CALCULATE;
                    continue;
                }
            }
            // calculate
            else if (state == S_CALCULATE)
            {
                // While co > po, calculate with next
                while ((co >> 8) > (po >> 8))
                {
                    // in S_OPERATOR state, index doesn't increased
                    // move to next and evaluate

                    // test expr1: 4*2**3+1
                    // test expr2: 5+4*2**3+1

                    (cv, co, index) = _evaluatePart(context, cv, co, expr, ++index, end);
                    
                    // now co is the last operator paraed by evaluatedPart just called
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
            // not implement
            else
            {
                revert("PVM:not implement");
            }

            // Load character
            // TODO: Use compare index and end to optimize?
            if (++index < end) { c = uint8(expr[index]); } else { c = $EOF; }
        }

        cv = pv;
    }

    // Call function
    function _call(
        mapping(uint=>uint) storage context,
        uint idtf,
        int[4] memory args,
        uint argIndex
    ) internal view returns (int) {
        (bool flag, int cv) = _internalCall(idtf, args, argIndex);
        if (flag) { cv = _staticCall(context, idtf, args, argIndex); }
        return cv;
        //return _staticCall(context, idtf, args, argIndex);
    }

    // Internal call function
    function _internalCall(uint idtf, int[4] memory args, uint argIndex) internal view returns (bool flag, int cv) 
    {
        if (argIndex == 0) {
            if (_equals(idtf,  "bn")) { cv =  bn(); } else 
            if (_equals(idtf,  "ts")) { cv =  ts(); } else 
            if (_equals(idtf,  "ob")) { cv =  ob(); } else { flag = true; }
        } else if (argIndex == 1) {
            if (_equals(idtf,  "op")) { cv =  op(args[0]); } else 
            if (_equals(idtf,  "ln")) { cv =  ln(args[0]); } else 
            if (_equals(idtf, "exp")) { cv = exp(args[0]); } else 
            if (_equals(idtf, "flo")) { cv = flo(args[0]); } else 
            if (_equals(idtf, "cel")) { cv = cel(args[0]); } else { flag = true; }
        } else if (argIndex == 2) {
            if (_equals(idtf, "log")) { cv = log(args[0], args[1]); } else
            if (_equals(idtf, "pow")) { cv = pow(args[0], args[1]); } else 
            if (_equals(idtf, "oav")) { cv = oav(args[0], args[1]); } else { flag = true;}
        } else { flag = true; }
    }

    // Static call function
    function _staticCall(
        mapping(uint=>uint) storage context, 
        uint idtf, 
        int[4] memory args, 
        uint argIndex
    ) internal view returns (int cv) {
        uint v = context[idtf];
        // Custom function staticcall
        require((v >> 248) == 0x05, "PVM:not staticcall function");

        // Generate signature
        string memory sign = _toIdtf(idtf);
        bytes memory buffer = new bytes(256);
        sign = StringHelper.sprintf(buffer, "%s%s", abi.encode(sign, "("));
        for (uint i = 0; i < argIndex; ++i) {
            if (i > 0) { sign = StringHelper.sprintf(buffer, "%s%s", abi.encode(sign, ",")); }
            sign = StringHelper.sprintf(buffer, "%s%s", abi.encode(sign, "int256"));
        }
        sign = StringHelper.sprintf(buffer, "%s%s", abi.encode(sign, ")"));

        // Generate abi arguments
        bytes memory abiArgs = new bytes(4 + (argIndex << 5));
        uint j = 0;
        bytes4 selector = bytes4(keccak256(bytes(sign)));
        for (uint i = 0; i < 4;) {
            abiArgs[j++] = selector[i++];
        }

        for (uint i = 0; i < argIndex; ++i) {
            for (uint k = 32; k > 0;) {
                abiArgs[j++] = bytes1(uint8(uint(args[i]) >> ((--k) << 3)));
            }
        }

        // if (argIndex == 0) {
        //     data = abi.encodeWithSignature(sign);
        // } else if (argIndex == 1) {
        //     data = abi.encodeWithSignature(sign, args[0]);
        // } else if (argIndex == 2) {
        //     data = abi.encodeWithSignature(sign, args[0], args[1]);
        // } else if (argIndex == 3) {
        //     data = abi.encodeWithSignature(sign, args[0], args[1], args[2]);
        // } else if (argIndex == 4) {
        //     data = abi.encodeWithSignature(sign, args[0], args[1], args[2], args[3]);
        // } else {
        //     revert("PVM:only support 4 arguments max");
        // }

        //console.log(_toHexString(buffer, abiArgs));

        // staticcall
        (bool flag, bytes memory data) = address(uint160(v)).staticcall(abiArgs);
        require(flag, "PVM:call failed");
        return abi.decode(data, (int));
    }

    // Convert 18 decimals to 64 bits
    function _toX64(int v) internal pure returns (int128) {
        v = v * 0x10000000000000000 / int(DECIMALS);
        require(v >= type(int128).min && v <= type(int128).max, "PVM:overflow");
        return int128(v);
    }

    // Convert 64 bits to 18 decimals
    function _toDEC(int128 v) internal pure returns (int) {
        return int(v) * int(DECIMALS) / 0x10000000000000000;
    }

    // Convert uint identifier to string identifier
    function _toIdtf(uint uid) internal pure returns (string memory idtf) {
        uint ouid = uid;
        uint length = 0;
        while (uid > 0) {
            ++length;
            uid >>= 8;
        }
        bytes memory bs = new bytes(length);
        while (ouid > 0) {
            bs[--length] = bytes1(uint8(ouid & 0xFF));
            ouid >>= 8;
        }
        idtf = string(bs);
    }

    // Convert uint identifier with string identifier
    function _equals(uint idtf, bytes memory name) internal pure returns (bool) {
        uint length = name.length;
        while (length > 0) {
            if ((idtf & 0xFF) != uint(uint8(name[--length]))) return false;
            idtf >>= 8;
        }
        return idtf == 0;
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
    function _toHexString(bytes memory buffer, bytes memory data) internal pure returns (string memory) {
        string memory s = "0x";
        for (uint i = 0; i < data.length; ++i) {
            s = StringHelper.sprintf(buffer, "%s%2x", abi.encode(s, uint(uint8(data[i]))));
        }
        return s;
    }
}
