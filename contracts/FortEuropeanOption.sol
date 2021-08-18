// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/ABDKMath64x64.sol";

import "./interfaces/IFortEuropeanOption.sol";

import "./FortToken.sol";
import "./FortOptionToken.sol";

// import "hardhat/console.sol";
import "hardhat/console.sol";

/// @dev 欧式期权
contract FortEuropeanOption is IFortEuropeanOption {
    
    // 期权代币映射
    mapping(bytes32=>address) _optionMapping;

    // 期权代币数组
    address[] _options;

    // fort代币地址
    address _fortToken;

    // INestPriceFacade地址
    address _nestPriceFacade;

    constructor() {
    }

    /// @dev 列出历史期权代币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray List of price sheets
    function list(uint offset, uint count, uint order) external view override returns (address[] memory optionArray) {
        address[] storage options = _options;
        optionArray = new address[](count);
        if (order == 0) {
            uint length = options.length - offset - 1;
            for (uint i = 0; i < count; ++i) {
                optionArray[i] = options[length - i];
            }
        } else {
            for (uint i = 0; i < count; ++i) {
                optionArray[i] = options[i + offset];
            }
        }
    }

    function setFortToken(address fortToken) external {
        _fortToken = fortToken;
    }

    function setNestPriceFacade(address nestPriceFacade) external {
        _nestPriceFacade = nestPriceFacade;
    }

    /// @dev 获取二元期权信息
    function getBinaryToken(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) public view override returns (address) {
        bytes32 key = keccak256(abi.encodePacked(tokenAddress, price, orientation, endblock));
        return _optionMapping[key];
    }

    /// @dev 开仓
    /// @param tokenAddress 目前Fort系统支持ETH/USDT、NEST/ETH、COFI/ETH、HBTC/ETH
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌2个方向
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    function open(
        address tokenAddress,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) external payable override {

        // 1. 创建期权凭证token
        bytes32 key = keccak256(abi.encodePacked(tokenAddress, price, orientation, endblock));
        address option = _optionMapping[key];
        if (option == address(0)) {
            option = address(new FortOptionToken(tokenAddress, uint88(endblock), orientation, price));
            _optionMapping[key] = option;
            _options.push(option);
        }

        (
            ,//uint blockNumber, 
            uint oraclePrice
        ) = INestPriceFacade(_nestPriceFacade).findPrice {
            value: msg.value
        } (
            tokenAddress, 
            block.number, 
            msg.sender
        );

        uint sigmaSQ = 4168125400;
        //int128 sigma = ABDKMath64x64.sqrt(sigma); //1190940626872424;

        // 2. TODO: 计算权利金（需要的fort数量）
        uint amount;
        uint T = 1000 * 14; // (endblock - block.number) * 14

        // 看涨
        if (orientation) {
            // TODO: 注意价格是倒过来的
            uint vc = _calcVc(oraclePrice, T, price, sigmaSQ);
            //console.log("vc:", vc);
            amount = (fortAmount << 64) * 1 ether / vc;
        } else {
            // TODO: 注意价格是倒过来的
            uint vp = _calcVp(oraclePrice, T, price, sigmaSQ);
            //console.log("vp:", vp);
            amount = (fortAmount << 64) * 1 ether / vp;
        }

        //console.log("fortAmount: ", fortAmount);
        //console.log("amount: ", amount);

        // 3. 销毁权利金
        FortToken(_fortToken).burn(msg.sender, fortAmount);

        // 4. 分发期权凭证
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

    // 0.3/365/86400 = 9.512937595129377E-09
    int128 constant miu = 175482725206;
    // 0.00006456
    //int128 constant sigma = 1190940626872424;
    int128 constant e = 50143449209798400000;
    int128 constant PI = 57952155664617100000;

    function _calcVc(uint S0, uint T, uint K, uint sigmaSQ) private view returns (uint) {

        int128 sigma = ABDKMath64x64.sqrt(int128(int((sigmaSQ << 64) / 1 ether)));
        int128 d1 = _d1(S0, T, K, sigma);
        //log("d1", d1);
        int128 sqrtT = ABDKMath64x64.sqrt(int128(int(T << 64)));
        //console.log("_calcVc-sqrtT: ", uint(int(sqrtT)));

        int128 f1 = _fai(ABDKMath64x64.sub(
            ABDKMath64x64.div(d1, sqrtT),
            ABDKMath64x64.mul(sigma, sqrtT)
        ));
        //log("f1", f1);

        int128 f2 = _fai(ABDKMath64x64.div(d1, sqrtT));
        //log("f2", f2);

        int left = ABDKMath64x64.mul(
            ABDKMath64x64.exp(miu * int128(int(T))), 
            (int128(1 << 64) - f1)
        );

        int right = int128(1 << 64) - f2;

        int r = int(1 ether / S0) * left - int(1 ether / K) * right;

        return uint(r);
    }

    function _calcVp(uint S0, uint T, uint K, uint sigmaSQ) private view returns (uint) {

        int128 sigma = ABDKMath64x64.sqrt(int128(int((sigmaSQ << 64) / 1 ether)));
        int128 d1 = _d1(S0, T, K, sigma);
        //log("d1", d1);
        int128 sqrtT = ABDKMath64x64.sqrt(int128(int(T << 64)));
        //console.log("_calcVc-sqrtT: ", uint(int(sqrtT)));

        int128 f1 = _fai(ABDKMath64x64.div(d1, sqrtT));
        //log("f1", f1);

        int128 f2 = _fai(ABDKMath64x64.sub(
            ABDKMath64x64.div(d1, sqrtT),
            ABDKMath64x64.mul(sigma, sqrtT)
        ));

        //log("f2", f2);

        int left = f1;

        int right = ABDKMath64x64.mul(
            ABDKMath64x64.exp(miu * int128(int(T))), 
            f2
        );

        int r = int(1 ether / K) * left - int(1 ether / S0) * right;

        return uint(r);
    }

    function log(string memory m, int v) private view {
        if (v < 0) {
            console.log(m, "-", uint(-v));
        } else {
            console.log(m, uint(v));
        }
    }

    function _fai(int128 x) private view returns (int128) {
        //console.log("_fai-x:", uint(int((ABDKMath64x64.sqrt(int128(2<<64)) * PI))));
        //int128 f = int128(1<<63) + ABDKMath64x64.div(x, 81956724509658300000);
        //console.log("fai:", uint(int(f)));
        int128 f = ABDKMath64x64.add(
            int128(int(1<<63)),
            ABDKMath64x64.div(
                x,
                ABDKMath64x64.sqrt(
                    ABDKMath64x64.mul(
                        int128(int(2<<64)),
                        PI
                    )
                )
            )
        );

        return f;
    }

    function _d1(uint S0, uint T, uint K, int128 sigma) private view returns (int128) {

        // int128 lnv = ABDKMath64x64.ln(int128(int((S0 << 64) / K)));
        // log("ln", lnv);
        // int128 r =ABDKMath64x64.div(ABDKMath64x64.mul(sigma, sigma), int128(int(2 << 64)));
        // log("r", r);
        // int128 ru = ABDKMath64x64.sub(
        //                     ABDKMath64x64.div(ABDKMath64x64.mul(sigma, sigma), int128(int(2 << 64))), 
        //                     miu
        //                 );
        // log("r-u", ru);
        // int128 ruT = ABDKMath64x64.mul(
        //                 ABDKMath64x64.sub(
        //                     ABDKMath64x64.div(ABDKMath64x64.mul(sigma, sigma), int128(int(2 << 64))), 
        //                     miu
        //                 ),
        //                 int128(int(T << 64))
        //             );
        // log("r-u*T", ruT);
        // int128 fm = ABDKMath64x64.add(
        //             lnv, 
        //             ABDKMath64x64.mul(
        //                 ABDKMath64x64.sub(
        //                     ABDKMath64x64.div(ABDKMath64x64.mul(sigma, sigma), int128(int(2 << 64))), 
        //                     miu
        //                 ),
        //                 int128(int(T << 64))
        //             )
        //         );
        // log("fm", fm);
        // int128 v = ABDKMath64x64.div(
        //         ABDKMath64x64.add(
        //             lnv, 
        //             ABDKMath64x64.mul(
        //                 ABDKMath64x64.sub(
        //                     ABDKMath64x64.div(ABDKMath64x64.mul(sigma, sigma), int128(int(2 << 64))), 
        //                     miu
        //                 ),
        //                 int128(int(T << 64))
        //             )
        //         ),
        //         sigma
        //     );
        // log("v", v);

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
                            miu
                        ),
                        int128(int(T << 64))
                    )
                ),
                sigma
            );
    }

    function ln(uint x) public view returns (uint) {
        return uint(int(ABDKMath64x64.ln(int128(int(x)))));
    }

    function sqrt(uint x) public view returns (uint) {
        return uint(int(ABDKMath64x64.sqrt(int128(int(x)))));
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

        // 2. 销毁期权
        FortOptionToken(optionAddress).burn(msg.sender, amount);

        // 3. 调用预言机获取价格
        // 读取预言机在指定区块的价格
        (
            ,//uint blockNumber, 
            uint oraclePrice
        ) = INestPriceFacade(_nestPriceFacade).findPrice {
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
            // 赌对了
            if (oraclePrice < price) {
                gain = amount / oraclePrice - amount / price;
            }
            // 赌错了
            else {

            }
        } 
        // 看跌期权
        else {
            // 赌对了
            if (oraclePrice > price) {
                gain = amount / price - amount / oraclePrice;
            }
            // 赌错了
            else {

            }
        }

        // 5. 用户赌赢了，给其增发赢得的fort
        if (gain > 0) {
            FortToken(_fortToken).mint(msg.sender, gain);
        }
    }
}
