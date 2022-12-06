// Copyright (c) 2007, FeirouSoft and/or its affiliates. All rights reserved.
// FEIROUSOFT PROPRIETARY/CONFIDENTIAL. Use is subject to license terms.
// Author: chenf
// Create: 2022/11/23 17:09:30
// Remark: Evaluate

using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace Baiynui.Utils
{
    /// <summary>
    /// Summary description for Evaluate
    /// by chenf 2022/11/23 17:09:30
    /// </summary>
    public class Evaluate
    {
        const char _A = (char)(0x41);     // A
        const char _Z = (char)(0x5a);     // Z
        const char _a = (char)(0x61);     // a
        const char _z = (char)(0x7a);     // z
        const char _0 = (char)(0x30);     // 0
        const char _9 = (char)(0x39);     // 9
        const char _ADD = (char)(0x2b);   // +
        const char _SUB = (char)(0x2d);   // -
        const char _MUL = (char)(0x2a);   // *
        const char _DIV = (char)(0x2f);   // /
        const char _COL = (char)(0x3a);   // :
        const char _LBR = (char)(0x28);   // (
        const char _RBR = (char)(0x29);   // )
        const char _SPC = (char)(0x20);   // SPACE
        const char _DOT = (char)(0x2e);   // .
        const char _CMA = (char)(0x2c);   // ,
        const char _EOF = (char)(0x00);   // 0

        // Status
        const int S_NORMAL = 0x0000;
        const int S_INTEGER = 0x0101;
        const int S_DECIMAL = 0x0102;
        const int S_IDENTIFIER = 0x0103;
        const int S_BRACKET = 0x0104;
        const int S_FUNCTION = 0x0105;
        const int S_STRING = 0x0106;    // consider a string can contain's bracket
        const int S_OPERATOR = 0x0201;
        const int S_CALCULATE = 0x0301;

        Dictionary<int, uint> _functionMap = new Dictionary<int, uint>();

        void register(string key, uint value)
        {

            int v = 0;
            for (int i = 0; i < key.Length; ++i)
            {
                v = (v << 8) | (int)(key[i]);
            }

            _functionMap[v] = value;
        }

        public Evaluate()
        {
            this.register("pi", 314);
        }

        /// <summary>
        /// Calculate expression
        /// </summary>
        /// <param name="expr"></param>
        /// <returns></returns>
        public int calc(string expr)
        {
            evaluatePart(0, 0, 0, expr, 0, expr.Length, out int cv, out int co, out int index);
            if (co == 0x0000) throw new NormalException("blank expression");
            return cv;
        }

        // Calculate left value with remain expression, and return value
        void evaluatePart(
            int level,
            // Previous value
            int pv,
            // Previous operator
            int po,
            // String expression
            string expr,
            // Index of expression start in expr
            int start,
            // Index of expression end in expr
            int end,
            // result values
            out int cv, out int co, out int index
        )
        {
            int _pv = pv;
            int _po = po;
            int _start = start;
            int _end = end;
            Console.WriteLine($"{space(level)}-evaluatePart({_pv},0x{_po},'{toString(expr, _start, _end)}')");

            // Args
            List<int> args = null;
            // Temp value
            int temp1 = 0;
            // Machine state
            int state = S_NORMAL;
            // Loop index
            index = start;

            // Load character
            char c = _EOF;
            if (index < end) { c = (char)expr[index]; } 

            // Loop with each character
            for(; ; )
            {
                // normal state, find part start
                if (state == S_NORMAL)
                {
                    // integer
                    if (c >= _0 && c <= _9)
                    {
                        cv = (int)(c - _0);
                        temp1 = 0;
                        state = S_INTEGER;
                    }
                    // identifier
                    else if ((c >= _A && c <= _Z) || (c >= _a && c <= _z))
                    {
                        // temp1: identifier
                        temp1 = (int)c;
                        state = S_IDENTIFIER;
                    }
                    // left bracket
                    else if (c == _LBR)
                    {
                        // temp1: bracket counter
                        // start: left index
                        temp1 = 1;
                        start = index + 1;
                        state = S_BRACKET;
                    }
                    // end of file, break
                    else if (c == _EOF) { co = 0x0000; break; }
                    // Ignore space, else error
                    else if (c != _SPC) { throw new NormalException($"invalid expression: [{toString(expr, start, end)}], index={(index - start)}, c={(char)c}"); }
                }
                // integer
                else if (state == S_INTEGER)
                {
                    // 0 ~ 9, parse integer
                    if (c >= _0 && c <= _9)
                    {
                        cv = cv * 10 + (int)(c - _0);
                    }
                    // else, parse end
                    else
                    {
                        // parse end, find next operator
                        state = S_OPERATOR;
                        continue;
                    }
                }
                // identifier
                else if (state == S_IDENTIFIER)
                {
                    if ((c >= _A && c <= _Z) || (c >= _a && c <= _z) || (c >= _0 && c <= _9))
                    {
                        temp1 = (temp1 << 8) | (int)c;
                    }
                    // left bracket, function
                    else if (c == _LBR)
                    {
                        // cv: bracket counter
                        // temp1: identifier
                        // start: left index
                        cv = 1;
                        start = index + 1;
                        state = S_FUNCTION;
                    }
                    else
                    {
                        cv = (int)_functionMap[temp1];
                        state = S_OPERATOR;
                        continue;
                    }
                }
                // left bracket
                else if (state == S_BRACKET)
                {
                    // TODO: consider bracket in "" and ''
                    // find right bracket
                    if (c == _RBR)
                    {
                        if (--temp1 == 0)
                        {
                            // calculate sub expression in brackets
                            // index is always equals to end when call end
                            evaluatePart(level + 1, 0, 0x0000, expr, start, index, out cv, out co, out index);
                            if (co == 0x0000) { throw new NormalException("bracket expression is blank"); }
                            // calculate end, find next operator
                            state = S_OPERATOR;
                        }
                    }
                    // new left bracket, increase counter
                    else if (c == _LBR)
                    {
                        ++temp1;
                    }
                }
                // function
                else if (state == S_FUNCTION)
                {
                    // temp1: identifier
                    // start: left index
                    // cv: bracket counter
                    if (c == _CMA && cv == 1)
                    {
                        // index is always equals to end when call end
                        evaluatePart(level + 1, 0, 0x0000, expr, start, index, out int v, out co, out index);
                        if (co == 0x0000) { throw new NormalException("PVM:argument expression is blank"); }
                        args.Add(v);
                        start = index + 1;
                    }
                    else if (c == _RBR && --cv == 0)
                    {
                        // index is always equals to end when call end
                        evaluatePart(level + 1, 0, 0x0000, expr, start, index, out int v, out co , out index);
                        if (co > 0x0000) { args.Add(v); }
                        else if (args != null) { throw new NormalException("PVM:arg expression is blank"); }

                        string s = "";
                        cv = 0;
                        for (int i = 0; i < (args?.Count ?? 0); ++i)
                        {
                            if (i > 0) { s += ","; }
                            s = s + args[i];
                            cv += args[i];
                        }
                        cv = (int)(this.GetType().GetMethod(idtf(temp1)) as MethodInfo).Invoke(null, args?.Select(i=>(object)i).ToArray());
                        Console.WriteLine($"{space(level)}->{idtf(temp1)}({s})={cv}");

                        // Restore status
                        args = null;
                        state = S_OPERATOR;
                    }
                    else if (c == _LBR)
                    {
                        ++cv;
                    }
                    else if (c != _SPC)
                    {
                        // TODO: why?
                        if (args == null) args = new List<int>();
                    }
                }
                // find next operator
                else if (state == S_OPERATOR)
                {
                    // ignore space
                    if (c != _SPC)
                    {
                        // next operator, + - * / **
                        if (c == _ADD) { co = 0x1001; }
                        else if (c == _SUB) { co = 0x1002; }
                        else if (c == _MUL)
                        {
                            if (index + 1 < end && expr[index + 1] == _MUL) { ++index; co = 0x3001; }
                            else { co = 0x2001; }
                        }
                        else if (c == _DIV) { co = 0x2002; }
                        // eof, no next operator
                        else if (c == _EOF) { co = 0x0001; }
                        else { throw new NormalException("invalid expression: " + expr.Substring(start, end - start) + ", index=" + (index - start) + ", c=" + (char)c); }

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

                        evaluatePart(level + 1, cv, co, expr, ++index, end, out cv, out co, out index);

                        // now co is the last operator paraed by evaluatedPart just called
                    }

                    // Calculate with pv
                    if (po == 0x1001) { pv += cv; }
                    else if (po == 0x1002) { pv -= cv; }
                    else if (po == 0x2001) { pv *= cv; }
                    else if (po == 0x2002) { pv /= cv; }
                    else if (po == 0x3001) { pv = (int)(Math.Pow(pv, cv)); }
                    // po is 0, means this is the first part, pv = cv
                    else if (po == 0x0000) { pv = cv; }
                    break;
                }
                // not implement
                else
                {
                    throw new NormalException("PVM:not implement");
                }

                // Load character
                // TODO: Use compare index and end to optimize?
                if (++index < end) { c = (char)expr[index]; } else { c = _EOF; }
            }

            cv = pv;
            Console.WriteLine($"{space(level)}+evaluatePart({_pv},0x{_po},'{toString(expr, _start, _end)}')=({cv}, {co}, {index})");
        }

        int bracket()
        {
            throw new NotImplementedException();
        }

        string space(int level)
        {
            string s = "";
            while (level > 0)
            {
                s += "   |";
                --level;
            }
            return s;
        }

        string toString(string expr, int start, int end)
        {
            return expr.Substring(start, end - start);
        }

        string idtf(int cv)
        {
            string s = "";
            while (cv > 0)
            {
                s = (char)(cv & 0xFF) + s;
                cv >>= 8;
            }
            return s;
        }

        public static int max(int a, int b, int c)
        {
            //Console.WriteLine("max");
            if (a > b)
            {
                if (a > c)
                {
                    return a;
                } else
                {
                    return c;
                }
            } else
            {
                if (b > c)
                {
                    return b;
                } else
                {
                    return c;
                }
            }
        }

        public static int min(int a, int b, int c)
        {
            //Console.WriteLine("min");
            if (a < b)
            {
                if (a < c)
                {
                    return a;
                }
                else
                {
                    return c;
                }
            }
            else
            {
                if (b < c)
                {
                    return b;
                }
                else
                {
                    return c;
                }
            }
        }

        public static int add(int a, int b, int c)
        {
            //Console.WriteLine("add");
            return a + b + c;
        }

        public static int nop()
        {
            return 8;
        }
    }
}
//         @evaluatePart(4, 0x2001, '2**3+1+pi')= (6, 32, 0x1001)
//     @evaluatePart(0, 0x0, '4*2**3+1+pi')= (8, 33, 0x1001)
//     @evaluatePart(33, 0x1001, 'pi')= (11, 347, 0x0)
// @evaluate('4*2**3+1+pi')=347
// 347


//             @evaluatePart(2, 0x3001, '3+1+pi')= (6, 8, 0x1001)
//         @evaluatePart(4, 0x2001, '2**3+1+pi')= (6, 32, 0x1001)
//     @evaluatePart(0, 0x0, '4*2**3+1+pi')= (8, 33, 0x1001)
//     @evaluatePart(33, 0x1001, 'pi')= (11, 347, 0x0)
// @evaluate('4*2**3+1+pi')=347
// 347