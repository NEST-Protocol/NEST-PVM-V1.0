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
    
    // 64位二进制精度的1
    int128 constant ONE = 0x10000000000000000;

    int128 constant TWO = 0x20000000000000000;

    // 64位二进制精度的50000
    uint constant V50000 = 0x0C3500000000000000000;

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

    function _check(address tokenAddress) private pure returns (bool) {
        //return tokenAddress == 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        return true;
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

        // 1. 最小期权费用（计算公式）为每份（注意用户买入可以是0.1份，这是指计算）
        //    期权费用不低于S0,K的1%（分别对应看涨和看跌）
        //    Vc>=S0*1%; Vp>=K*1%
        // 2. 行权周期不低于10000区块
        // 3. 杠杆币 100FORT起（最小单位未来和FORT价格挂钩：注意激励相容） 期权0.1份起
        // 4. 按照区块触发
        // 5. 1.0目前就支持eth/usd开仓
        // 6. 杠杆币：E/U+F1和E/U-F1
        // 7. 期权 C3302E/U10003837 P3321E/U10008766
        //    价格精度和转化问题

        // TODO: 确定哪些交易对可以开仓
        require(fortAmount < 0x100000000000000000000000000000000, "FEO:fortAmount too large");
        require(endblock > block.number + uint(_minPeriod), "FEO:endblock to small");

        // 1. 获取或创建期权代币
        bytes32 key = _getKey(tokenAddress, price, orientation, endblock);
        address option = _optionMapping[key];
        if (option == address(0)) {
            
            require(_check(tokenAddress), "FEO:token not allowed");
            // TODO: 重新对齐
            // TODO: 代币命名问题
            string memory idx = StringHelper.toString(_options.length, 1);
            option = address(new FortOptionToken(
                StringHelper.stringConcat("FT-", idx),
                StringHelper.stringConcat("FORT-", idx),
                tokenAddress, 
                price, 
                orientation, 
                endblock
            ));
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

        // TODO: 波动率改为手动输入的
        // TODO: 测试代码
        //sigmaSQ = 4168125400;

        // 3. TODO: 计算权利金（需要的fort数量）
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

        uint amount;
        // 看涨
        if (orientation) {
            // TODO: 注意价格是倒过来的
            uint vc = _calcVc(oraclePrice, T, price, sigmaSQ);
            // Vc>=S0*1%; Vp>=K*1%
            require(vc * oraclePrice * 100 >= 1 << 64, "FEO:vc must greater than S0*1%");
            //amount = (fortAmount << 64) * 1 ether / vc;
            //amount = fortAmount * 0x0DE0B6B3A76400000000000000000000 / vc;
            amount = (fortAmount << 128) / vc;
        }
        // 看跌
        else {
            // TODO: 注意价格是倒过来的
            uint vp = _calcVp(oraclePrice, T, price, sigmaSQ);
            // Vc>=S0*1%; Vp>=K*1%
            require(vp * price * 100 >= 1 << 64, "FEO:vc must greater than S0*1%");
            //amount = (fortAmount << 64) * 1 ether / vp;
            //amount = fortAmount * 0x0DE0B6B3A76400000000000000000000 / vp;
            amount = (fortAmount << 128) / vp;
        }
        require(amount > 0.1 ether, "FEO:at least 0.1");

        // 4. 销毁权利金
        FortToken(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 5. 分发期权凭证
        FortOptionToken(option).mint(msg.sender, amount);
    }

    /// @dev 预估开仓可以买到的期权币数量
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    /// @param oraclePrice 当前预言机价格价
    /// @param sigmaSQ 波动率
    /// @return amount 预估可以获得的期权币数量
    function estimate(
        uint oraclePrice,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount,
        uint sigmaSQ
    ) external view override returns (uint amount) {

        // TODO: 确定哪些交易对可以开仓
        require(fortAmount < 0x100000000000000000000000000000000, "FEO:fortAmount too large");
        require(endblock > block.number + uint(_minPeriod), "FEO:endblock to small");

        // // 1. 获取或创建期权代币
        // bytes32 key = _getKey(tokenAddress, price, orientation, endblock);
        // address option = _optionMapping[key];
        // require(option != address(0));

        // 3. TODO: 计算权利金（需要的fort数量）
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
            //amount = (fortAmount << 64) * 1 ether / vc;
            //amount = fortAmount * 0x0DE0B6B3A76400000000000000000000 / vc;
            amount = (fortAmount << 128) / vc;
        }
        // 看跌
        else {
            // TODO: 注意价格是倒过来的
            uint vp = _calcVp(oraclePrice, T, price, sigmaSQ);
            //amount = (fortAmount << 64) * 1 ether / vp;
            //amount = fortAmount * 0x0DE0B6B3A76400000000000000000000 / vp;
            amount = (fortAmount << 128) / vp;
        }
    }
    
    // 将18位十进制定点数转化为64位二级制定点数
    function _d18TOb64(uint v) private pure returns (int128) {
        //require(v < 0x1000000000000000000000000000000000000000000000000, "FEO:value can't ROL 64bits");
        require(v < 0x0DE0B6B3A764000000000000000000000000000000000000, "FEO:can't convert to 64bits");
        return int128(int((v << 64) / 1 ether));
    }

    // 将uint转化为int128
    function _toInt128(uint v) private pure returns (int128) {
        require(v < 0x100000000000000000000000000000000, "FEO:can't convert to int128");
        return int128(int(v));
    }

    // 将int128转化为uint
    function _toUInt(int128 v) private pure returns (uint) {
        require(v >= 0, "FEO:can't convert to uint");
        return uint(int(v));
    }

    // 计算看涨期权价格
    function _calcVc(uint S0, uint T, uint K, uint sigmaSQ) private view returns (uint) {

        int128 sigmaSQ_T = _d18TOb64(sigmaSQ * T);
        int128 miu_T = _toInt128(uint(int(_miu)) * T);
        int128 sigma_t = ABDKMath64x64.sqrt(sigmaSQ_T);
        int128 D1 = _D1(S0, K, sigmaSQ_T, miu_T);
        int128 d = ABDKMath64x64.div(D1, sigma_t);

        uint left = (_toUInt(ABDKMath64x64.mul(
            ABDKMath64x64.exp(miu_T), 
            ABDKMath64x64.sub(
                ONE,
                _snd(ABDKMath64x64.sub(d, sigma_t))
            )
        )) << 64) / S0;
        uint right = (_toUInt(ABDKMath64x64.sub(ONE, _snd(d))) << 64) / K;

        return left - right;
    }

    // 计算看跌期权价格
    function _calcVp(uint S0, uint T, uint K, uint sigmaSQ) private view returns (uint) {

        int128 sigmaSQ_T = _d18TOb64(sigmaSQ * T);
        int128 miu_T = _toInt128(uint(int(_miu)) * T);
        int128 sigma_t = ABDKMath64x64.sqrt(sigmaSQ_T);
        int128 D1 = _D1(S0, K, sigmaSQ_T, miu_T);
        int128 d = ABDKMath64x64.div(D1, sigma_t);

        uint left = (_toUInt(_snd(d)) << 64) / K;
        uint right = (_toUInt(ABDKMath64x64.mul(
            ABDKMath64x64.exp(miu_T), 
            _snd(ABDKMath64x64.sub(d, sigma_t))
        )) << 64) / S0;

        return left - right;
    }

    // 计算公式种的d1，因为没有除以σ，所以命名为D1
    function _D1(uint S0, uint K, int128 sigmaSQ_T, int128 miu_T) private pure returns (int128) {

        require(S0 < 0x1000000000000000000000000000000000000000000000000, "FEO:S0 can't ROL 64bits");
        return
            ABDKMath64x64.sub(
                ABDKMath64x64.add(
                    ABDKMath64x64.ln(_toInt128((S0 << 64) / K)),
                    sigmaSQ_T >> 1
                ),
                miu_T
            );
    }

    // 通过查表的方法计算标准正态分布函数
    function _snd(int128 x) private pure returns (int128) {

        uint[28] memory table = [
            /* */ ///////////////////// STANDARD NORMAL TABLE //////////////////////////
            /* */ 0x174A15BF143412A8111C0F8F0E020C740AE6095807CA063B04AD031E018F0000, //
            ///// 0x2F8C2E0F2C912B1229922811268F250B23872202207D1EF61D6F1BE61A5D18D8, //
            /* */ 0x2F8C2E0F2C912B1229922811268F250B23872202207D1EF61D6F1BE61A5D18D4, //
            /* */ 0x46A2453C43D4426B41003F943E263CB63B4539D3385F36EA357333FB32823108, //
            /* */ 0x5C0D5AC5597B582F56E05590543E52EA5194503C4EE24D874C294ACA49694807, //
            /* */ 0x6F6C6E466D1F6BF56AC9699B686A6738660364CC6392625761195FD95E975D53, //
            /* */ 0x807E7F7F7E7D7D797C737B6A7A5F79517841772F761A750373E972CD71AF708E, //
            /* */ 0x8F2A8E518D768C998BB98AD789F2890B88218736864785568463836E8276817B, //
            /* */ 0x9B749AC19A0B9953989997DD971E965D959A94D4940C9342927591A690D49000, //
            /* */ 0xA57CA4ECA459A3C4A32EA295A1FAA15CA0BDA01C9F789ED29E2A9D809CD39C25, //
            ///// 0xA57CA4ECA459A3C4A32EA295A1FAA15DA0BDA01C9F789ED29E2A9D809CD39C25, //
            /* */ 0xAD78AD07AC93AC1EABA7AB2EAAB3AA36A9B8A937A8B5A830A7AAA721A697A60B, //
            /* */ 0xB3AAB353B2FAB2A0B245B1E7B189B128B0C6B062AFFDAF96AF2DAEC2AE56ADE8, //
            /* */ 0xB859B818B7D6B793B74EB708B6C0B678B62EB5E2B595B547B4F7B4A6B454B400, //
            /* */ 0xBBCDBB9EBB6EBB3CBB0ABAD7BAA2BA6DBA36B9FFB9C6B98CB951B915B8D8B899, //
            /* */ 0xBE49BE27BE05BDE2BDBEBD99BD74BD4DBD26BCFEBCD5BCACBC81BC56BC29BBFC, //
            /* */ 0xC006BFEEBFD7BFBEBFA5BF8CBF72BF57BF3CBF20BF03BEE6BEC8BEA9BE8ABE69, //
            /* */ 0xC135C126C116C105C0F4C0E3C0D1C0BFC0ACC099C086C072C05DC048C032C01C, //
            /* */ 0xC200C1F5C1EBC1E0C1D5C1C9C1BEC1B1C1A5C198C18BC17EC170C162C154C145, //
            /* */ 0xC283C27CC275C26EC267C260C258C250C248C240C238C22FC226C21DC213C20A, //
            /* */ 0xC2D6C2D2C2CDC2C9C2C5C2C0C2BBC2B6C2B1C2ACC2A7C2A1C29BC295C28FC289, //
            /* */ 0xC309C306C304C301C2FEC2FCC2F9C2F6C2F2C2EFC2ECC2E8C2E5C2E1C2DEC2DA, //
            /* */ 0xC328C326C325C323C321C320C31EC31CC31AC318C316C314C312C310C30EC30B, //
            /* */ 0xC33AC339C338C337C336C335C334C333C332C331C330C32EC32DC32CC32AC329, //
            /* */ 0xC344C343C343C342C342C341C341C340C33FC33FC33EC33DC33DC33CC33BC33A, //
            /* */ 0xC34AC349C349C349C348C348C348C348C347C347C346C346C346C345C345C344, //
            /* */ 0xC34DC34DC34CC34CC34CC34CC34CC34CC34BC34BC34BC34BC34BC34AC34AC34A, //
            /* */ 0xC34EC34EC34EC34EC34EC34EC34EC34EC34EC34EC34DC34DC34DC34DC34DC34D, //
            /* */ 0xC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34EC34E, //
            /* */ 0xC350C350C350C350C350C350C34FC34FC34FC34FC34FC34FC34FC34FC34FC34F  //
            /* */ //////////////////// MADE IN CHINA 2021-08-24 ////////////////////////
        ];

        //  uint[448] memory tableOld = [
        //  uint(0), 399, 798, 1197, 1595, 1994, 2392, 2790, 3188, 3586,
		//  3983, 4380, 4776, 5172, 5567, 5962, 6356, 6749, 7142, 7535,
		//  7926, 8317, 8706, 9095, 9483, 9871, 10257, 10642, 11026, 11409,
		//  11791, 12172, 12552, 12930, 13307, 13683, 14058, 14431, 14803, 15173,
		//  15542, 15910, 16276, 16640, 17003, 17364, 17724, 18082, 18439, 18793,
		//  19146, 19497, 19847, 20194, 20540, 20884, 21226, 21566, 21904, 22240,
		//  22575, 22907, 23237, 23565, 23891, 24215, 24537, 24857, 25175, 25490,
		//  25804, 26115, 26424, 26730, 27035, 27337, 27637, 27935, 28230, 28524,
		//  28814, 29103, 29389, 29673, 29955, 30234, 30511, 30785, 31057, 31327,
		//  31594, 31859, 32121, 32381, 32639, 32894, 33147, 33398, 33646, 33891,
		//  34134, 34375, 34614, 34849, 35083, 35314, 35543, 35769, 35993, 36214,
		//  36433, 36650, 36864, 37076, 37286, 37493, 37698, 37900, 38100, 38298,
		//  38493, 38686, 38877, 39065, 39251, 39435, 39617, 39796, 39973, 40147,
		//  40320, 40490, 40658, 40824, 40988, 41149, 41309, 41466, 41621, 41774,
		//  41924, 42073, 42220, 42364, 42507, 42647, 42785, 42922, 43056, 43189,
		//  43319, 43448, 43574, 43699, 43822, 43943, 44062, 44179, 44295, 44408,
		//  44520, 44630, 44738, 44845, 44950, 45053, 45154, 45254, 45352, 45449,
		//  45543, 45637, 45728, 45818, 45907, 45994, 46080, 46164, 46246, 46327,
		//  46407, 46485, 46562, 46638, 46712, 46784, 46856, 46926, 46995, 47062,
		//  47128, 47193, 47257, 47320, 47381, 47441, 47500, 47558, 47615, 47670,
		//  47725, 47778, 47831, 47882, 47932, 47982, 48030, 48077, 48124, 48169,
		//  48214, 48257, 48300, 48341, 48382, 48422, 48461, 48500, 48537, 48574,
		//  48610, 48645, 48679, 48713, 48745, 48778, 48809, 48840, 48870, 48899,
		//  48928, 48956, 48983, 49010, 49036, 49061, 49086, 49111, 49134, 49158,
		//  49180, 49202, 49224, 49245, 49266, 49286, 49305, 49324, 49343, 49361,
		//  49379, 49396, 49413, 49430, 49446, 49461, 49477, 49492, 49506, 49520,
		//  49534, 49547, 49560, 49573, 49585, 49598, 49609, 49621, 49632, 49643,
		//  49653, 49664, 49674, 49683, 49693, 49702, 49711, 49720, 49728, 49736,
		//  49744, 49752, 49760, 49767, 49774, 49781, 49788, 49795, 49801, 49807,
		//  49813, 49819, 49825, 49831, 49836, 49841, 49846, 49851, 49856, 49861,
		//  49865, 49869, 49874, 49878, 49882, 49886, 49889, 49893, 49896, 49900,
		//  49903, 49906, 49910, 49913, 49916, 49918, 49921, 49924, 49926, 49929,
		//  49931, 49934, 49936, 49938, 49940, 49942, 49944, 49946, 49948, 49950,
		//  49952, 49953, 49955, 49957, 49958, 49960, 49961, 49962, 49964, 49965,
		//  49966, 49968, 49969, 49970, 49971, 49972, 49973, 49974, 49975, 49976,
		//  49977, 49978, 49978, 49979, 49980, 49981, 49981, 49982, 49983, 49983,
		//  49984, 49985, 49985, 49986, 49986, 49987, 49987, 49988, 49988, 49989,
		//  49989, 49990, 49990, 49990, 49991, 49991, 49992, 49992, 49992, 49992,
		//  49993, 49993, 49993, 49994, 49994, 49994, 49994, 49995, 49995, 49995,
		//  49995, 49995, 49996, 49996, 49996, 49996, 49996, 49996, 49997, 49997,
		//  49997, 49997, 49997, 49997, 49997, 49997, 49998, 49998, 49998, 49998,
		//  49998, 49998, 49998, 49998, 49998, 49998, 49998, 49998, 49999, 49999,
		//  49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999,
		//  49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999, 49999,
		//  49999, 49999, 50000, 50000, 50000, 50000, 50000, 50000
        //  ];

        // for (uint i = 0; i < 448; ++i) {
        //     require(uint(tableOld[i]) == uint((table[i >> 4] >> ((i & 0xF) << 4)) & 0xFFFF), "FEO:not equal");
        // }

        uint ux = uint(int(x < 0 ? -x : x)) * 100;
        uint i = ux >> 64;
        uint v = V50000;

        if (i < 447) {
            v = uint((table[i >> 4] >> ((i & 0xF) << 4)) & 0xFFFF) << 64;
            v = (
                    (
                        (
                            (uint((table[(i + 1) >> 4] >> (((i + 1) & 0xF) << 4)) & 0xFFFF) << 64)
                            - v
                        ) * (ux - (i << 64))
                    ) >> 64
                ) + v;
        }

        if (x > 0) {
            v = V50000 + v;
        } else {
            v = V50000 - v;
        }

        return int128(int(v / 100000));
    }

    /// @dev 行权
    /// @param optionAddress 期权合约地址
    /// @param amount 结算的期权分数
    function exercise(address optionAddress, uint amount) external payable override {

        // 1. 获取期权信息
        (
            address tokenAddress, 
            uint price, 
            bool orientation, 
            uint endblock
        ) = FortOptionToken(optionAddress).getOptionInfo();

        // TODO: 测试期间不检查
        //require(block.number >= endblock, "FEO:at maturity");

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

    // TODO: 测试方法，需要删掉
    function log(string memory m, int v) private view {
        if (v < 0) {
            console.log(m, "-", uint(-v));
        } else {
            console.log(m, uint(v));
        }
    }
}
