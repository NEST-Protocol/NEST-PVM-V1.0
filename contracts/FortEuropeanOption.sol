// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";
import "./libs/ABDKMath64x64.sol";

import "./interfaces/IFortEuropeanOption.sol";

import "./FortFrequentlyUsed.sol";
import "./FortDCU.sol";

/// @dev 欧式期权
contract FortEuropeanOption is FortFrequentlyUsed, IFortEuropeanOption {

    /// @dev 期权结构
    struct Option {
        address tokenAddress;
        uint56 price;
        bool orientation;
        uint32 endblock;
        
        //uint totalSupply;
        mapping(address=>uint) balances;
    }

    // 64位二进制精度的1
    int128 constant ONE = 0x10000000000000000;

    // 64位二进制精度的50000
    uint constant V50000 = 0x0C3500000000000000000;

    // 期权代币映射
    mapping(bytes32=>uint) _optionMapping;

    // 配置参数
    mapping(address=>Config) _configs;

    // 缓存代币的基数值
    mapping(address=>uint) _bases;

    // 期权代币数组
    Option[] _options;

    constructor() {
    }

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IFortGovernance implementation contract address
    function initialize(address governance) public override {
        super.initialize(governance);
        _options.push();
    }

    /// @dev 修改指定代币通道的配置
    /// @param tokenAddress 目标代币地址
    /// @param config 配置对象
    function setConfig(address tokenAddress, Config calldata config) external override {
        _configs[tokenAddress] = config;
    }

    /// @dev 获取指定代币通道的配置
    /// @param tokenAddress 目标代币地址
    /// @return 配置对象
    function getConfig(address tokenAddress) external view override returns (Config memory) {
        return _configs[tokenAddress];
    }

    /// @dev 返回指定期权的余额
    /// @param index 目标期权索引号
    /// @param addr 目标地址
    function balanceOf(uint index, address addr) external view override returns (uint) {
        return _options[index].balances[addr];
    }

    function _toOptionView(Option storage option, uint index) private view returns (OptionView memory) {
        return OptionView(
            index,
            option.tokenAddress,
            _decodeFloat(option.price),
            option.orientation,
            uint32(option.endblock),
            option.balances[msg.sender]
        );
    }

    /// @dev 查找目标账户的期权（倒序）
    /// @param start 从给定的合约地址对应的索引向前查询（不包含start对应的记录）
    /// @param count 最多返回的记录条数
    /// @param maxFindCount 最多查找maxFindCount记录
    /// @param owner 目标账户地址
    /// @return optionArray 期权信息列表
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view override returns (OptionView[] memory optionArray) {
        
        optionArray = new OptionView[](count);
        uint index = 0;
        
        // 计算查找区间i和end
        Option[] storage options = _options;
        uint i = options.length;
        uint end = 0;
        if (start > 0) {
            i = start;
        }
        if (i > maxFindCount) {
            end = i - maxFindCount;
        }
        
        // 循环查找，将符合条件的记录写入缓冲区
        while (count > 0 && i-- > end) {
            Option storage option = options[i];
            if (option.balances[owner] > 0) {
                --count;
                optionArray[index++] = _toOptionView(option, i);
            }
        }
    }

    /// @dev 列出历史期权信息
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray 期权信息列表
    function list(uint offset, uint count, uint order) external view override returns (OptionView[] memory optionArray) {

        // 加载代币数组
        Option[] storage options = _options;
        // 创建结果数组
        optionArray = new OptionView[](count);
        uint length = options.length;
        uint i = 0;

        // 倒序
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                Option storage option = options[--index];
                optionArray[i++] = _toOptionView(option, index);
            }
        } 
        // 正序
        else {
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                optionArray[i++] = _toOptionView(options[index], index);
                ++index;
            }
        }
    }

    /// @dev 获取已经开通的欧式期权代币数量
    /// @return 已经开通的欧式期权代币数量
    function getTokenCount() external view override returns (uint) {
        return _options.length;
    }

    /// @dev 获取期权信息
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @return 期权信息
    function getOptionInfo(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) external view override returns (OptionView memory) {        
        uint index = _optionMapping[_getKey(tokenAddress, price, orientation, endblock)];
        return _toOptionView(_options[index], index);
    }

    /// @dev 开仓
    /// @param tokenAddress 目标代币地址，0表示eth
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

        // 将价格对齐为7位有效数字，避免精度过高导致期权代币数量过多
        //price = _align(price);

        // 1. 调用预言机获取价格
        // 1.1. 获取token相对于eth的价格
        uint tokenAmount = 1 ether;
        uint fee = msg.value;
        if (tokenAddress != address(0)) {
            fee = msg.value >> 1;
            (, tokenAmount) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).triggeredPrice {
                value: fee
            } (tokenAddress, msg.sender);
        }

        // 1.2. 获取usdt相对于eth的价格
        (, uint usdtAmount) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).triggeredPrice {
            value: fee
        } (USDT_TOKEN_ADDRESS, msg.sender);

        // 1.3. 将token价格转化为以usdt为单位计算的价格
        uint oraclePrice = usdtAmount * _getBase(tokenAddress) / tokenAmount;

        // 2. 计算可以买到的期权份数
        uint amount = estimate(tokenAddress, oraclePrice, price, orientation, endblock, fortAmount);
        //require(amount >= 0.1 ether, "FEO:at least 0.1");

        // 3. 获取或创建期权代币
        bytes32 key = _getKey(tokenAddress, price, orientation, endblock);
        uint optionIndex = _optionMapping[key];
        Option storage option = _options[optionIndex];
        if (optionIndex == 0) {
            
            optionIndex = _options.length;
            option = _options.push();
            option.tokenAddress = tokenAddress;
            option.price = _encodeFloat(price);
            option.orientation = orientation;
            require(endblock < 0x100000000, "FEO:endblock to large");
            option.endblock = uint32(endblock);

            // 将期权代币地址存入映射和数组，便于后面检索
            _optionMapping[key] = optionIndex;
        }

        // 4. 销毁权利金
        FortDCU(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 5. 分发期权凭证
        option.balances[msg.sender] += amount;
    }

    /// @dev 预估开仓可以买到的期权币数量
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param oraclePrice 当前预言机价格价
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    /// @return amount 预估可以获得的期权币数量
    function estimate(
        address tokenAddress,
        uint oraclePrice,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) public view override returns (uint amount) {

        Config memory config = _configs[tokenAddress];
        uint minPeriod = uint(config.minPeriod);
        require(minPeriod > 0, "FEO:not allowed");
        //require(fortAmount < 0x100000000000000000000000000000000, "FEO:fortAmount too large");
        require(endblock > block.number + minPeriod, "FEO:endblock to small");

        // 1. 获取或创建期权代币
        //price = _align(price);

        // 2. 调用预言机获取价格

        // 3. 计算权利金（需要的fort数量）
        // 按照平均每14秒出一个块计算
        uint T = (endblock - block.number) * 14;
        uint v;
        if (orientation) {
            v = _calcVc(config, oraclePrice, T, price);
            // Vc>=S0*1%; Vp>=K*1%
            require(v * 100 >> 64 >= oraclePrice, "FEO:vc must greater than S0*1%");
        } else {
            v = _calcVp(config, oraclePrice, T, price);
            // Vc>=S0*1%; Vp>=K*1%
            require(v * 100 >> 64 >= price, "FEO:vp must greater than K*1%");
        }

        amount = (USDT_BASE << 64) * fortAmount / v;
    }
    
    /// @dev 行权
    /// @param index 期权编号
    /// @param amount 结算的期权分数
    function exercise(uint index, uint amount) external payable override {

        // 1. 获取期权信息
        Option storage option = _options[index];
        address tokenAddress = option.tokenAddress;
        uint price = _decodeFloat(option.price);
        bool orientation = option.orientation;
        uint endblock = uint(option.endblock);

        // TODO: 测试期间不检查
        //require(block.number >= endblock, "FEO:at maturity");

        // 2. 销毁期权代币
        option.balances[msg.sender] -= amount;

        // 3. 调用预言机获取价格，读取预言机在指定区块的价格
        // 3.1. 获取token相对于eth的价格
        uint tokenAmount = 1 ether;
        uint fee = msg.value;
        if (tokenAddress != address(0)) {
            fee = msg.value >> 1;
            (, tokenAmount) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).findPrice {
                value: fee
            } (tokenAddress, endblock,msg.sender);
        }

        // 3.2. 获取usdt相对于eth的价格
        (, uint usdtAmount) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).findPrice {
            value: fee
        } (USDT_TOKEN_ADDRESS, endblock,msg.sender);

        // 将token价格转化为以usdt为单位计算的价格
        uint oraclePrice = usdtAmount * _getBase(tokenAddress) / tokenAmount;
        // 4. 分情况计算用户可以获得的fort数量
        uint gain = 0;
        // 计算结算结果
        // 看涨期权
        if (orientation) {
            // 赌赢了
            if (oraclePrice > price) {
                gain = amount * (oraclePrice - price) / USDT_BASE;
            }
        } 
        // 看跌期权
        else {
            // 赌赢了
            if (oraclePrice < price) {
                gain = amount * (price - oraclePrice) / USDT_BASE;
            }
        }

        // 5. 用户赌赢了，给其增发赢得的fort
        if (gain > 0) {
            FortDCU(FORT_TOKEN_ADDRESS).mint(msg.sender, gain);
        }
    }

    // 根据期权信息获取索引key
    function _getKey(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress, price, orientation, endblock));
    }

    // // 对齐价格，保留7位有效数字
    // function _align(uint price) private pure returns (uint) {
    //     // uint decimals = 0;
    //     // while (price >= 10000000) {
    //     //     price /= 10;
    //     //     ++decimals;
    //     // }
    //     // return price * 10 ** decimals;

    //     uint base = 10000000;
    //     while (price >= base) {
    //         base *= 10;
    //     }
    //     return price - price % (base / 10000000);
    // }

    // 获取代币的基数值
    function _getBase(address tokenAddress) private returns (uint base) {
        if (tokenAddress == address(0)) {
            base = 1 ether;
        } else {
            base = _bases[tokenAddress];
            if (base == 0) {
                base = 10 ** ERC20(tokenAddress).decimals();
                _bases[tokenAddress] = base;
            }
        }
    }

    // 将18位十进制定点数转化为64位二级制定点数
    function _d18TOb64(uint v) private pure returns (int128) {
        require(v < 0x6F05B59D3B200000000000000000000, "FEO:can't convert to 64bits");
        return int128(int((v << 64) / 1 ether));
    }

    // 将uint转化为int128
    function _toInt128(uint v) private pure returns (int128) {
        require(v < 0x80000000000000000000000000000000, "FEO:can't convert to int128");
        return int128(int(v));
    }

    // 将int128转化为uint
    function _toUInt(int128 v) private pure returns (uint) {
        require(v >= 0, "FEO:can't convert to uint");
        return uint(int(v));
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
                        ) * (ux & 0xFFFFFFFFFFFFFFFF) //(ux - (i << 64))
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

    // 计算看涨期权价格
    function _calcVc(Config memory config, uint S0, uint T, uint K) private pure returns (uint) {

        int128 sigmaSQ_T = _d18TOb64(uint(config.sigmaSQ) * T);
        int128 miu_T = _toInt128(uint(int(config.miu)) * T);
        int128 sigma_t = ABDKMath64x64.sqrt(sigmaSQ_T);
        int128 D1 = _D1(S0, K, sigmaSQ_T, miu_T);
        int128 d = ABDKMath64x64.div(D1, sigma_t);

        uint left = _toUInt(ABDKMath64x64.mul(
            ABDKMath64x64.exp(miu_T), 
            ABDKMath64x64.sub(
                ONE,
                _snd(ABDKMath64x64.sub(d, sigma_t))
            )
        )) * S0;
        uint right = _toUInt(ABDKMath64x64.sub(ONE, _snd(d))) * K;
        
        return left - right;
    }

    // 计算看跌期权价格
    function _calcVp(Config memory config, uint S0, uint T, uint K) private pure returns (uint) {

        int128 sigmaSQ_T = _d18TOb64(uint(config.sigmaSQ) * T);
        int128 miu_T = _toInt128(uint(int(config.miu)) * T);
        int128 sigma_t = ABDKMath64x64.sqrt(sigmaSQ_T);
        int128 D1 = _D1(S0, K, sigmaSQ_T, miu_T);
        int128 d = ABDKMath64x64.div(D1, sigma_t);

        uint left = _toUInt(_snd(d)) * K;
        uint right = _toUInt(ABDKMath64x64.mul(
            ABDKMath64x64.exp(miu_T), 
            _snd(ABDKMath64x64.sub(d, sigma_t))
        )) * S0;

        return left - right;
    }

    // 计算公式种的d1，因为没有除以σ，所以命名为D1
    function _D1(uint S0, uint K, int128 sigmaSQ_T, int128 miu_T) private pure returns (int128) {

        require(K < 0x1000000000000000000000000000000000000000000000000, "FEO:K can't ROL 64bits");
        return
            ABDKMath64x64.sub(
                ABDKMath64x64.add(
                    ABDKMath64x64.ln(_toInt128((K << 64) / S0)),
                    sigmaSQ_T >> 1
                ),
                miu_T
            );
    }
    
    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint56) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint56((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint56 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }
}
