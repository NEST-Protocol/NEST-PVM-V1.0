// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";

import "./interfaces/IFortLever.sol";

import "./FortFrequentlyUsed.sol";
import "./FortDCU.sol";
import "./FortLeverToken.sol";

/// @dev 杠杆币交易
contract FortLever is FortFrequentlyUsed, IFortLever {

    // 用户账本
    struct Account {
        // 账本-余额
        uint128 balance;
        // 账本-价格
        uint64 price;
        // 解锁区块
        uint32 unlockBlock;
    }

    struct LeverInfo {
        address tokenAddress; 
        uint lever;
        bool orientation;
        
        mapping(address=>Account) accounts;
    }

    // 最小余额数量，余额小于此值会被清算
    uint constant MIN_VALUE = 5 ether;

    // 买入杠杆币和其他交易之间最小的间隔区块数
    uint constant MIN_PERIOD = 100;

    // 杠杆币映射
    mapping(bytes32=>uint) _leverMapping;

    // 杠杆币数组
    LeverInfo[] _levers;

    constructor() {
    }

    // 根据新价格计算账户余额
    function _balanceOf(
        Account memory account, 
        uint oraclePrice, 
        bool ORIENTATION, 
        uint LEVER
    ) private pure returns (uint balance) {

        balance = uint(account.balance);
        if (balance > 0) {
            uint price = _decodeFloat(account.price);

            uint left;
            uint right;
            // 看涨
            if (ORIENTATION) {
                left = balance + balance * oraclePrice * LEVER / price;
                right = balance * LEVER;
            } 
            // 看跌
            else {
                left = balance * (1 + LEVER);
                right = balance * oraclePrice * LEVER / price;
            }

            if (left > right) {
                balance = left - right;
            } else {
                balance = 0;
            }
        }
    }

    /// @dev 列出历史杠杆币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return leverArray List of price sheets
    function list(uint offset, uint count, uint order) external view override returns (LeverView[] memory leverArray) {

        // 加载代币数组
        LeverInfo[] storage levers = _levers;
        // 创建结果数组
        leverArray = new LeverView[](count);
        uint length = levers.length;
        uint i = 0;

        // 倒序
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                LeverInfo storage li = levers[--index];
                leverArray[i++] = LeverView(
                    index,
                    li.tokenAddress,
                    li.lever,
                    li.orientation,
                    uint(li.accounts[msg.sender].balance)
                );
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
                LeverInfo storage li = levers[index];
                leverArray[i++] = LeverView(
                    index,
                    li.tokenAddress,
                    li.lever,
                    li.orientation,
                    uint(li.accounts[msg.sender].balance)
                );
                ++index;
            }
        }
    }

    /// @dev 创建杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external override onlyGovernance {

        // bytes32 key = _getKey(tokenAddress, lever, orientation);
        // address leverAddress = _leverMapping[key];
        // require(leverAddress == address(0), "FortLever:exists");

        // uint tokenBase = 1 ether;
        // if (tokenAddress != address(0)) {
        //     tokenBase = 10 ** ERC20(tokenAddress).decimals();
        // }
        // leverAddress = address(new FortLeverToken(
        //     //name,
        //     StringHelper.sprintf("%4S/USDT%sF%u", abi.encode(
        //         tokenAddress == address(0) ? "ETH" : ERC20(tokenAddress).symbol(),
        //         orientation ? "+" : "-",
        //         lever,
        //         0, 0
        //     )),
        //     USDT_TOKEN_ADDRESS,
        //     tokenAddress, 
        //     lever, 
        //     orientation,
        //     tokenBase
        // ));
        // // 使用create2创建合约，会导致杠杆币内不能使用immutable变量来保存杠杆信息，从而增加gas消耗，放弃此方法
        // // leverAddress = address(new FortLeverToken { 
        // //         salt: keccak256(abi.encodePacked(tokenAddress, lever, orientation)) 
        // //     } (
        // //         StringHelper.stringConcat("LEVER-", StringHelper.toString(_levers.length)),
        // //         tokenAddress, 
        // //         lever, 
        // //         orientation
        // //     )
        // // );
        
        // FortLeverToken(leverAddress).setNestPriceFacade(NEST_PRICE_FACADE_ADDRESS);
        // _leverMapping[key] = leverAddress;
        // _levers.push(leverAddress);
    }

    /// @dev 获取已经开通的杠杆币数量
    /// @return 已经开通的杠杆币数量
    function getTokenCount() external view override returns (uint) {
        return _levers.length;
    }

    /// @dev 获取杠杆币地址
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 杠杆币地址
    function getLeverToken(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view override returns (LeverView memory) {
        uint index = _leverMapping[_getKey(tokenAddress, lever, orientation)];
        LeverInfo storage li = _levers[index];
        return LeverView(
            index,
            li.tokenAddress,
            li.lever,
            li.orientation,
            uint(li.accounts[msg.sender].balance)
        );
    }

    /// @dev 买入杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param fortAmount 支付的fort数量
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint fortAmount
    ) external payable override {

        require(fortAmount >= 100 ether, "FortLever:at least 100 FORT");
        // 1. 找到杠杆代币地址
        uint index = _leverMapping[_getKey(tokenAddress, lever, orientation)];
        require(index != 0, "FortLever:not exist");
        LeverInfo storage li = _levers[index];

        // 2. 销毁用户的fort
        FortDCU(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 3. 给用户分发杠杆币
        // FortLeverToken(leverAddress).mint { 
        //     value: msg.value 
        // } (msg.sender, fortAmount, block.number + MIN_PERIOD, msg.sender);
        Account memory account = li.accounts[msg.sender];
        uint oraclePrice = _queryPrice(tokenAddress, msg.sender);

        // 更新接收账号信息
        account.balance = _toUInt128(_balanceOf(account, oraclePrice, li.orientation, uint(li.lever)) + fortAmount);
        account.price = _encodeFloat(oraclePrice);
        account.unlockBlock = uint32(block.number + MIN_PERIOD);
        
        li.accounts[msg.sender] = account;
    }

    /// @dev 买入杠杆币
    /// @param index 杠杆币编号
    /// @param fortAmount 支付的fort数量
    function buyDirect(
        uint index,
        uint fortAmount
    ) external payable override {

        require(fortAmount >= 100 ether, "FortLever:at least 100 FORT");

        require(index != 0, "FortLever:not exist");
        LeverInfo storage li = _levers[index];

        // 1. 销毁用户的fort
        FortDCU(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 2. 给用户分发杠杆币
        // FortLeverToken(leverAddress).mint { 
        //     value: msg.value 
        // } (msg.sender, fortAmount, block.number + MIN_PERIOD, msg.sender);

        Account memory account = li.accounts[msg.sender];
        uint oraclePrice = _queryPrice(li.tokenAddress, msg.sender);

        // 更新接收账号信息
        account.balance = _toUInt128(_balanceOf(account, oraclePrice, li.orientation, uint(li.lever)) + fortAmount);
        account.price = _encodeFloat(oraclePrice);
        account.unlockBlock = uint32(block.number + MIN_PERIOD);
        
        li.accounts[msg.sender] = account;
    }

    /// @dev 卖出杠杆币
    /// @param index 杠杆币编号
    /// @param amount 卖出数量
    function sell(
        uint index,
        uint amount
    ) external payable override {

        // 1. 销毁用户的杠杆币
        // FortLeverToken(leverAddress).burn { 
        //     value: msg.value 
        // } (msg.sender, amount, msg.sender);
        require(index != 0, "FortLever:not exist");
        LeverInfo storage li = _levers[index];

        // 更新目标账号信息
        Account memory account = li.accounts[msg.sender];
        uint oraclePrice = _queryPrice(li.tokenAddress, msg.sender);
        account.balance = _toUInt128(_balanceOf(account, oraclePrice, li.orientation, uint(li.lever)) - amount);
        account.price = _encodeFloat(oraclePrice);
        li.accounts[msg.sender] = account;

        // 2. 给用户分发fort
        FortDCU(FORT_TOKEN_ADDRESS).mint(msg.sender, amount);
    }

    /// @dev 清算
    /// @param index 杠杆币编号
    /// @param addresses 清算目标账号数组
    function settle(
        uint index,
        address[] calldata addresses
    ) external payable override {

        // 1. 销毁用户的杠杆币
        require(index != 0, "FortLever:not exist");
        LeverInfo storage li = _levers[index];

        if (uint(li.lever) > 1) {
            mapping(address=>Account) storage accounts = li.accounts;
            uint oraclePrice = _queryPrice(li.tokenAddress, msg.sender);
            uint reward = 0;
            for (uint i = addresses.length; i > 0;) {
                address acc = addresses[--i];

                // 更新目标账号信息
                Account memory account = accounts[acc];
                uint balance = _balanceOf(account, oraclePrice, li.orientation, uint(li.lever));

                // 杠杆倍数大于1，并且余额小于最小额度时，可以清算
                if (balance < MIN_VALUE) {
                    
                    accounts[acc] = Account(uint128(0), uint64(0), uint32(0));

                    //emit Transfer(acc, address(0), balance);

                    reward += balance;
                }
            }

            // 2. 跟用户分发fort
            if (reward > 0) {
                FortDCU(FORT_TOKEN_ADDRESS).mint(msg.sender, reward);
            }
        } else {
            if (msg.value > 0) {
                payable(msg.sender).transfer(msg.value);
            }
        }
    }

    /// @dev 触发更新价格，获取FORT奖励
    /// @param leverAddressArray 要更新的杠杆币合约地址
    /// @param payback 多余的预言机费用退回地址
    function updateLeverInfo(
        address[] memory leverAddressArray, 
        address payback
    ) external payable override {
        // uint unitFee = msg.value / leverAddressArray.length;
        // uint blocks = 0;
        // for (uint i = leverAddressArray.length; i > 0; ) {
        //     blocks += FortLeverToken(leverAddressArray[--i]).update { value: unitFee } (payback);
        // }
        // FortDCU(FORT_TOKEN_ADDRESS).mint(msg.sender, blocks * 0.1 ether);
    }

    // 根据杠杆信息计算索引key
    function _getKey(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress, lever, orientation));
    }

    function _queryPrice(address tokenAddress, address payback) private returns (uint oraclePrice) {
        // 获取token相对于eth的价格
        uint tokenAmount = 1 ether;
        uint fee = msg.value;

        if (tokenAddress != address(0)) {
            fee = msg.value >> 1;
            (, tokenAmount) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).triggeredPrice {
                value: fee
            } (tokenAddress, payback);
        }

        // 获取usdt相对于eth的价格
        (, uint usdtAmount) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).triggeredPrice {
            value: fee
        } (USDT_TOKEN_ADDRESS, payback);

        // 将token价格转化为以usdt为单位计算的价格
        oraclePrice = usdtAmount * 10 ** ERC20(tokenAddress).decimals() / tokenAmount;
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint64) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint64((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint64 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }

    // 将uint转化为uint128，有截断检查
    function _toUInt128(uint value) private pure returns (uint128) {
        require(value < 0x100000000000000000000000000000000);
        return uint128(value);
    }
}
