// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";
import "./libs/ABDKMath64x64.sol";

import "./interfaces/IFortEuropeanOption.sol";

import "./FortFrequentlyUsed.sol";
import "./FortToken.sol";
import "./FortOptionToken.sol";

import "hardhat/console.sol";

/// @dev 欧式期权
contract FortEuropeanOption is FortFrequentlyUsed, IFortEuropeanOption {
    
    // 64位二进制精度的 PI = 3.1415926
    int128 constant PI = 57952155664617100000;

    // 64位二进制精度的1
    int128 constant ONE = int128(int(1 << 64));

    // 期权代币映射
    mapping(bytes32=>address) _optionMapping;

    // 期权代币数组
    address[] _options;

    // 64位二进制精度
    // 0.3/365/86400 = 9.512937595129377E-09
    // 175482725206
    int128 _miu;

    // TODO: 通过数值计算过程，确定期权行权时间最大间隔
    // 期权行权时间和当前时间的最小间隔
    uint32 _minPeriod;

    constructor() {
    }

    /// @dev 设置配置
    function setConfig(int128 miu, uint32 minPeriod) external onlyGovernance {
        _miu = miu;
        _minPeriod = minPeriod;
    }

    /// @dev 获取配置
    function getConfig() external view returns (int128 miu, uint32 minPeriod) {
        return (_miu, _minPeriod);
    }

    /// @dev 列出历史期权代币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray List of price sheets
    function list(uint offset, uint count, uint order) external view override returns (address[] memory optionArray) {

        // 加载代币数组
        address[] storage options = _options;
        // 创建结果数组
        optionArray = new address[](count);

        uint i = 0;
        // 倒序
        if (order == 0) {
            uint end = options.length - offset - 1;
            while (i < count) {
                optionArray[i] = options[end - i];
                ++i;
            }
        } 
        // 正序
        else {
            while (i < count) {
                optionArray[i] = options[i + offset];
                ++i;
            }
        }
    }

    /// @dev 获取已经开通的欧式期权代币数量
    /// @return 已经开通的欧式期权代币数量
    function getTokenCount() external view override returns (uint) {
        return _options.length;
    }

    function _getKey(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress, price, orientation, endblock));
    }

    /// @dev 获取欧式期权代币地址
    /// @param tokenAddress 目前Fort系统支持ETH/USDT、NEST/ETH、COFI/ETH、HBTC/ETH
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @return 欧式期权代币地址
    function getEuropeanToken(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) external view override returns (address) {
        return _optionMapping[_getKey(tokenAddress, price, orientation, endblock)];
    }

    /// @dev 开仓
    /// @param tokenAddress 目前Fort系统支持ETH/USDT、NEST/ETH、COFI/ETH、HBTC/ETH
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    function open(
        address tokenAddress,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) external payable override {

        // TODO: 确定哪些交易对可以开仓
        require(endblock > block.number + uint(_minPeriod), "FortEuropeanOption: endblock to small");

        // 1. 获取或创建期权代币
        bytes32 key = _getKey(tokenAddress, price, orientation, endblock);
        address option = _optionMapping[key];
        if (option == address(0)) {
            // TODO: 重新对齐
            // TODO: 代币命名问题
            string memory idx = StringHelper.toString(_options.length);
            option = address(new FortOptionToken(
                StringHelper.stringConcat("FT-", idx),
                StringHelper.stringConcat("FORT-", idx),
                tokenAddress, 
                uint88(endblock), 
                orientation, 
                price)
            );
            _optionMapping[key] = option;
            _options.push(option);
        }

        // 2. 调用预言机获取价格
        (
            ,//uint blockNumber, 
            uint oraclePrice,
            ,
            uint sigmaSQ
        ) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).triggeredPriceInfo {
            value: msg.value
        } (
            tokenAddress, 
            msg.sender
        );

        // TODO: 测试代码
        //sigmaSQ = 4168125400;

        // 3. TODO: 计算权利金（需要的fort数量）
        uint amount;
        // 按照平均每14秒出一个块计算
        // TODO: 确定时间间隔，是从block.number算起，还是从预言机价格所在区块算起
        uint T = (endblock - block.number) * 14;
        // TODO: 测试代码
        //T = 1000 * 14;
        // console.log("open-oraclePrice", oraclePrice);
        // console.log("open-price", price);
        // console.log("open-T", T);
        // console.log("open-sigmaSQ", sigmaSQ);
        // {
        //     uint vc = _calcVc(oraclePrice, T, price, sigmaSQ);
        //     uint vp = _calcVp(oraclePrice, T, price, sigmaSQ);
        //     console.log("open-vc", vc);
        //     console.log("open-vp", vp);
        // }

        // 看涨
        if (orientation) {
            // TODO: 注意价格是倒过来的
            uint vc = _calcVc(oraclePrice, T, price, sigmaSQ);
            amount = (fortAmount << 64) * 1 ether / vc;
        } else {
            // TODO: 注意价格是倒过来的
            uint vp = _calcVp(oraclePrice, T, price, sigmaSQ);
            amount = (fortAmount << 64) * 1 ether / vp;
        }

        // 4. 销毁权利金
        FortToken(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 5. 分发期权凭证
        FortOptionToken(option).mint(msg.sender, amount);
    }
    
    // TODO: 优化计算公式
    function _calcVc(uint S0, uint T, uint K, uint sigmaSQ) private view returns (uint) {

        int128 sigma = ABDKMath64x64.sqrt(int128(int((sigmaSQ << 64) / 1 ether)));
        int128 d1 = _d1(S0, T, K, sigma);
        int128 sqrtT = ABDKMath64x64.sqrt(int128(int(T << 64)));

        int128 f1 = _snd(ABDKMath64x64.sub(
            ABDKMath64x64.div(d1, sqrtT),
            ABDKMath64x64.mul(sigma, sqrtT)
        ));

        int128 f2 = _snd(ABDKMath64x64.div(d1, sqrtT));

        int left = ABDKMath64x64.mul(
            ABDKMath64x64.exp(_miu * int128(int(T))), 
            (int128(1 << 64) - f1)
        );

        int right = int128(1 << 64) - f2;

        int r = int(1 ether / S0) * left - int(1 ether / K) * right;

        return uint(r);
    }

    function _calcVp(uint S0, uint T, uint K, uint sigmaSQ) private view returns (uint) {

        // TODO: 看跌期权，行权价必须比当前价低，也就是 S0 < T
        int128 sigma = ABDKMath64x64.sqrt(int128(int((sigmaSQ << 64) / 1 ether)));
        int128 d1 = _d1(S0, T, K, sigma);
        int128 sqrtT = ABDKMath64x64.sqrt(int128(int(T << 64)));

        int128 f1 = _snd(ABDKMath64x64.div(d1, sqrtT));

        int128 f2 = _snd(ABDKMath64x64.sub(
            ABDKMath64x64.div(d1, sqrtT),
            ABDKMath64x64.mul(sigma, sqrtT)
        ));

        int left = f1;

        int right = ABDKMath64x64.mul(
            ABDKMath64x64.exp(_miu * int128(int(T))), 
            f2
        );

        int r = int(1 ether / K) * left - int(1 ether / S0) * right;

        return uint(r);
    }

    // TODO: 测试方法，需要删掉
    function log(string memory m, int v) private view {
        if (v < 0) {
            console.log(m, "-", uint(-v));
        } else {
            console.log(m, uint(v));
        }
    }

    // 通过近似的方法计算标准正态分布函数
    // function _snd(int128 x) private pure returns (int128) {

    //     int128 r = 
    //         ABDKMath64x64.add(
    //             int128(int(1 << 63)),
    //             ABDKMath64x64.div(
    //                 x,
    //                 ABDKMath64x64.sqrt(
    //                     ABDKMath64x64.mul(
    //                         int128(int(2 << 64)),
    //                         PI
    //                     )
    //                 )
    //             )
    //         );

    //     return r;
    // }

    // 通过查表的方法计算标准正态分布函数
    function _snd(int128 x) private pure returns (int128) {

        uint16[410] memory table = [
            //  Z     +0.00  +0.01  +0.02  +0.03  +0.04  +0.05  +0.06  +0.07  +0.08  +0.09  //////////////
            /* 0.0 */ 0    , 399  , 798  , 1197 , 1595 , 1994 , 2392 , 2790 , 3188 , 3586 , // 0.00 ~ 0.09
            /* 0.1 */ 3983 , 4380 , 4776 , 5172 , 5567 , 5962 , 6360 , 6749 , 7142 , 7535 , // 0.10 ~ 0.19
            /* 0.2 */ 7926 , 8317 , 8706 , 9095 , 9483 , 9871 , 10257, 10642, 11026, 11409, // 0.20 ~ 0.29
            /* 0.3 */ 11791, 12172, 12552, 12930, 13307, 13683, 14058, 14431, 14803, 15173, // 0.30 ~ 0.39
            /* 0.4 */ 15542, 15910, 16276, 16640, 17003, 17364, 17724, 18082, 18439, 18793, // 0.40 ~ 0.49
            /* 0.5 */ 19146, 19497, 19847, 20194, 20540, 20884, 21226, 21566, 21904, 22240, // 0.50 ~ 0.59
            /* 0.6 */ 22575, 22907, 23237, 23565, 23891, 24215, 24537, 24857, 25175, 25490, // 0.60 ~ 0.69
            /* 0.7 */ 25804, 26115, 26424, 26730, 27035, 27337, 27637, 27935, 28230, 28524, // 0.70 ~ 0.79
            /* 0.8 */ 28814, 29103, 29389, 29673, 29955, 30234, 30511, 30785, 31057, 31327, // 0.80 ~ 0.89
            /* 0.9 */ 31594, 31859, 32121, 32381, 32639, 32894, 33147, 33398, 33646, 33891, // 0.90 ~ 0.99
            /* 1.0 */ 34134, 34375, 34614, 34849, 35083, 35314, 35543, 35769, 35993, 36214, // 1.00 ~ 1.09
            /* 1.1 */ 36433, 36650, 36864, 37076, 37286, 37493, 37698, 37900, 38100, 38298, // 1.10 ~ 1.19
            /* 1.2 */ 38493, 38686, 38877, 39065, 39251, 39435, 39617, 39796, 39973, 40147, // 1.20 ~ 1.29
            /* 1.3 */ 40320, 40490, 40658, 40824, 40988, 41149, 41308, 41466, 41621, 41774, // 1.30 ~ 1.39
            /* 1.4 */ 41924, 42073, 42220, 42364, 42507, 42647, 42785, 42922, 43056, 43189, // 1.40 ~ 1.49
            /* 1.5 */ 43319, 43448, 43574, 43699, 43822, 43943, 44062, 44179, 44295, 44408, // 1.50 ~ 1.59
            /* 1.6 */ 44520, 44630, 44738, 44845, 44950, 45053, 45154, 45254, 45352, 45449, // 1.60 ~ 1.69
            /* 1.7 */ 45543, 45637, 45728, 45818, 45907, 45994, 46080, 46164, 46246, 46327, // 1.70 ~ 1.79
            /* 1.8 */ 46407, 46485, 46562, 46638, 46712, 46784, 46856, 46926, 46995, 47062, // 1.80 ~ 1.89
            /* 1.9 */ 47128, 47193, 47257, 47320, 47381, 47441, 47500, 47558, 47615, 47670, // 1.90 ~ 1.99
            /* 2.0 */ 47725, 47778, 47831, 47882, 47932, 47982, 48030, 48077, 48124, 48169, // 2.00 ~ 2.09
            /* 2.1 */ 48214, 48257, 48300, 48341, 48382, 48422, 48461, 48500, 48537, 48574, // 2.10 ~ 2.19
            /* 2.2 */ 48610, 48645, 48679, 48713, 48745, 48778, 48809, 48840, 48870, 48899, // 2.20 ~ 2.29
            /* 2.3 */ 48928, 48956, 48983, 49010, 49036, 49061, 49086, 49111, 49134, 49158, // 2.30 ~ 2.39
            /* 2.4 */ 49180, 49202, 49224, 49245, 49266, 49286, 49305, 49324, 49343, 49361, // 2.40 ~ 2.49
            /* 2.5 */ 49379, 49396, 49413, 49430, 49446, 49461, 49477, 49492, 49506, 49520, // 2.50 ~ 2.59
            /* 2.6 */ 49534, 49547, 49560, 49573, 49585, 49598, 49609, 49621, 49632, 49643, // 2.60 ~ 2.69
            /* 2.7 */ 49653, 49664, 49674, 49683, 49693, 49702, 49711, 49720, 49728, 49736, // 2.70 ~ 2.79
            /* 2.8 */ 49744, 49752, 49760, 49767, 49774, 49781, 49788, 49795, 49801, 49807, // 2.80 ~ 2.89
            /* 2.9 */ 49813, 49819, 49825, 49831, 49836, 49841, 49846, 49851, 49856, 49861, // 2.90 ~ 2.99
            /* 3.0 */ 49865, 49869, 49874, 49878, 49882, 49886, 49889, 49893, 49896, 49900, // 3.00 ~ 3.09
            /* 3.1 */ 49903, 49906, 49910, 49913, 49916, 49918, 49921, 49924, 49926, 49929, // 3.10 ~ 3.19
            /* 3.2 */ 49931, 49934, 49936, 49938, 49940, 49942, 49944, 49946, 49948, 49950, // 3.20 ~ 3.29
            /* 3.3 */ 49952, 49953, 49955, 49957, 49958, 49960, 49961, 49962, 49964, 49965, // 3.30 ~ 3.39
            /* 3.4 */ 49966, 49968, 49969, 49970, 49971, 49972, 49973, 49974, 49975, 49976, // 3.40 ~ 3.49
            /* 3.5 */ 49977, 49978, 49978, 49979, 49980, 49981, 49981, 49982, 49983, 49983, // 3.50 ~ 3.59
            /* 3.6 */ 49984, 49985, 49985, 49986, 49986, 49987, 49987, 49988, 49988, 49989, // 3.60 ~ 3.69
            /* 3.7 */ 49989, 49990, 49990, 49990, 49991, 49991, 49992, 49992, 49992, 49992, // 3.70 ~ 3.79
            /* 3.8 */ 49993, 49993, 49993, 49994, 49994, 49994, 49994, 49995, 49995, 49995, // 3.80 ~ 3.89
            /* 3.9 */ 49995, 49995, 49996, 49996, 49996, 49996, 49996, 49996, 49997, 49997, // 3.90 ~ 3.99
            /* 4.0 */ 49997, 49997, 49997, 49997, 49997, 49997, 49998, 49998, 49998, 49998  // 4.00 ~ 4.09
        ];

        uint ux = uint(int(x < 0 ? -x : x));
        uint i = (ux * 100 ) >> 64;
        uint v = 50000 << 64;

        if (i < 410) {
            v = uint(table[i]) << 64;
            if (i < 409) {
                v = v + ((((uint(table[i + 1]) << 64) - v) * (ux * 100 - (i << 64))) >> 64);
            }
        }

        if (x > 0) {
            v = (50000 << 64) + v;
        } else {
            v = (50000 << 64) - v;
        }

        int128 r = int128(int(v / 100000));
        return r;
    }

    function _d1(uint S0, uint T, uint K, int128 sigma) private view returns (int128) {

        // TODO: 考虑溢出问题
        return
            ABDKMath64x64.div(
                ABDKMath64x64.add(
                    ABDKMath64x64.ln(int128(int((S0 << 64) / K))), 
                    ABDKMath64x64.mul(
                        ABDKMath64x64.sub(
                            ABDKMath64x64.div(
                                ABDKMath64x64.mul(sigma, sigma), 
                                int128(int(2 << 64))
                            ), 
                            _miu
                        ),
                        int128(int(T << 64))
                    )
                ),
                sigma
            );
    }

    /// @dev 行权
    /// @param optionAddress 期权合约地址
    /// @param amount 结算的期权分数
    function exercise(address optionAddress, uint amount) external payable override {

        // 1. 获取期权信息
        (
            address tokenAddress, 
            uint endblock, 
            bool orientation, 
            uint price
        ) = FortOptionToken(optionAddress).getOptionInfo();

        // TODO: 测试期间不检查
        //require(block.number >= endblock, "FortEuropeanOption:at maturity");

        // 2. 销毁期权代币
        FortOptionToken(optionAddress).burn(msg.sender, amount);

        // 3. 调用预言机获取价格
        // 读取预言机在指定区块的价格
        (
            ,//uint blockNumber, 
            uint oraclePrice
        ) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).findPrice {
            value: msg.value
        } (
            tokenAddress, 
            endblock, 
            msg.sender
        );

        // 4. 分情况计算用户可以获得的fort数量
        uint gain = 0;
        // 计算结算结果
        // 看涨期权
        if (orientation) {
            // 赌赢了
            if (oraclePrice < price) {
                gain = amount / oraclePrice - amount / price;
            }
            // 赌输了
            // else {
            // }
        } 
        // 看跌期权
        else {
            // 赌赢了
            if (oraclePrice > price) {
                gain = amount / price - amount / oraclePrice;
            }
            // 赌输了
            // else {
            // }
        }

        // 5. 用户赌赢了，给其增发赢得的fort
        if (gain > 0) {
            FortToken(FORT_TOKEN_ADDRESS).mint(msg.sender, gain);
        }
    }
}
