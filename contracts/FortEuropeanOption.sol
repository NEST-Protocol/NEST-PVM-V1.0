// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
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
            option = address(new FortOptionToken(tokenAddress, uint88(endblock), orientation, price));
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
    
    // jackson:
    // μ和σ的值分别怎么取

    // James:
    // 首先 单位都是秒  包括T  

    // James:
    // 其次  波动率来自于NEST   而u是定期更新的输入 

    // jackson:
    // μ的取值范围是多少

    // James:
    // 很小很小 

    // James:
    // 年化30%  折算成秒是多少？

    // TODO: 优化计算公式
    function _calcVc(uint S0, uint T, uint K, uint sigmaSQ) private view returns (uint) {

        int128 sigma = ABDKMath64x64.sqrt(int128(int((sigmaSQ << 64) / 1 ether)));
        int128 d1 = _d1(S0, T, K, sigma);
        int128 sqrtT = ABDKMath64x64.sqrt(int128(int(T << 64)));

        int128 f1 = _fai(ABDKMath64x64.sub(
            ABDKMath64x64.div(d1, sqrtT),
            ABDKMath64x64.mul(sigma, sqrtT)
        ));

        int128 f2 = _fai(ABDKMath64x64.div(d1, sqrtT));

        int left = ABDKMath64x64.mul(
            ABDKMath64x64.exp(_miu * int128(int(T))), 
            (int128(1 << 64) - f1)
        );

        int right = int128(1 << 64) - f2;

        int r = int(1 ether / S0) * left - int(1 ether / K) * right;

        return uint(r);
    }

    function _calcVp(uint S0, uint T, uint K, uint sigmaSQ) private view returns (uint) {

        int128 sigma = ABDKMath64x64.sqrt(int128(int((sigmaSQ << 64) / 1 ether)));
        int128 d1 = _d1(S0, T, K, sigma);
        int128 sqrtT = ABDKMath64x64.sqrt(int128(int(T << 64)));

        int128 f1 = _fai(ABDKMath64x64.div(d1, sqrtT));

        int128 f2 = _fai(ABDKMath64x64.sub(
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

    function _fai(int128 x) private pure returns (int128) {

        return 
            ABDKMath64x64.add(
                int128(int(1 << 63)),
                ABDKMath64x64.div(
                    x,
                    ABDKMath64x64.sqrt(
                        ABDKMath64x64.mul(
                            int128(int(2 << 64)),
                            PI
                        )
                    )
                )
            );
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

        require(block.number >= endblock, "FortEuropeanOption:at maturity");

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
