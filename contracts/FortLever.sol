// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";
import "./libs/ABDKMath64x64.sol";

import "./interfaces/IFortLever.sol";

import "./FortFrequentlyUsed.sol";
import "./FortDCU.sol";

/// @dev 杠杆币交易
contract FortLever is FortFrequentlyUsed, IFortLever {

    /// @dev 用户账本
    struct Account {
        // 账本-余额
        uint128 balance;
        // 基准价格
        uint64 basePrice;
        // 基准区块号
        uint32 baseBlock;
    }

    /// @dev 杠杆币信息
    struct LeverInfo {
        // 目标代币地址
        address tokenAddress; 
        // 杠杆倍数
        uint32 lever;
        // 看涨:true | 看跌:false
        bool orientation;
        
        // 账号信息
        mapping(address=>Account) accounts;
    }

    // 漂移系数，64位二进制小数。年华80%
    uint constant MIU = 467938556917;
    
    // 最小余额数量，余额小于此值会被清算
    uint constant MIN_VALUE = 5 ether;

    // 买入杠杆币和其他交易之间最小的间隔区块数
    uint constant MIN_PERIOD = 100;

    // 杠杆币映射
    mapping(bytes32=>uint) _leverMapping;

    // 缓存代币的基数值
    mapping(address=>uint) _bases;

    // 杠杆币数组
    LeverInfo[] _levers;

    constructor() {
    }

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IFortGovernance implementation contract address
    function initialize(address governance) public override {
        super.initialize(governance);
        _levers.push();
    }

    /// @dev 返回指定期权当前的价值
    /// @param index 目标期权索引号
    /// @param oraclePrice 预言机价格
    /// @param addr 目标地址
    function balanceOf(uint index, uint oraclePrice, address addr) external view override returns (uint) {
        LeverInfo storage li = _levers[index];
        Account memory account = li.accounts[addr];
        return _balanceOf(
            uint(account.balance), 
            _decodeFloat(account.basePrice), 
            uint(account.baseBlock),
            oraclePrice, 
            li.orientation, 
            uint(li.lever)
        );
    }

    /// @dev 查找目标账户的合约
    /// @param start 从给定的合约地址对应的索引向前查询（不包含start对应的记录）
    /// @param count 最多返回的记录条数
    /// @param maxFindCount 最多查找maxFindCount记录
    /// @param owner 目标账户地址
    /// @return leverArray 合约信息列表
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view override returns (LeverView[] memory leverArray) {
        
        leverArray = new LeverView[](count);
        
        // 计算查找区间i和end
        LeverInfo[] storage levers = _levers;
        uint i = levers.length;
        uint end = 0;
        if (start > 0) {
            i = start;
        }
        if (i > maxFindCount) {
            end = i - maxFindCount;
        }
        
        // 循环查找，将符合条件的记录写入缓冲区
        for (uint index = 0; index < count && i > end;) {
            LeverInfo storage li = levers[--i];
            if (uint(li.accounts[owner].balance) > 0) {
                leverArray[index++] = _toLeverView(li, i);
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
                leverArray[i++] = _toLeverView(li, index);
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
                leverArray[i++] = _toLeverView(levers[index], index);
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

        // 参数检查
        require(lever < 0x100000000, "FL:lever to large");
        // 检查杠杆币是否已经存在
        bytes32 key = _getKey(tokenAddress, lever, orientation);
        uint index = _leverMapping[key];
        require(index == 0, "FortLever:exists");

        // 创建杠杆币
        index = _levers.length;
        LeverInfo storage li = _levers.push();
        li.tokenAddress = tokenAddress;
        li.lever = uint32(lever);
        li.orientation = orientation;
        _leverMapping[key] = index;

        // 创建杠杆币事件
        emit New(tokenAddress, lever, orientation, index);
    }

    /// @dev 获取已经开通的杠杆币数量
    /// @return 已经开通的杠杆币数量
    function getLeverCount() external view override returns (uint) {
        return _levers.length;
    }

    /// @dev 获取杠杆币信息
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 杠杆币地址
    function getLeverInfo(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view override returns (LeverView memory) {
        uint index = _leverMapping[_getKey(tokenAddress, lever, orientation)];
        return _toLeverView(_levers[index], index);
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
        uint index = _leverMapping[_getKey(tokenAddress, lever, orientation)];
        require(index != 0, "FortLever:not exist");
        _buy(_levers[index], index, fortAmount, tokenAddress);
    }

    /// @dev 买入杠杆币
    /// @param index 杠杆币编号
    /// @param fortAmount 支付的fort数量
    function buyDirect(uint index, uint fortAmount) public payable override {
        require(index != 0, "FortLever:not exist");
        LeverInfo storage li = _levers[index];
        _buy(li, index, fortAmount, li.tokenAddress);
    }

    /// @dev 卖出杠杆币
    /// @param index 杠杆币编号
    /// @param amount 卖出数量
    function sell(uint index, uint amount) external payable override {

        // 1. 销毁用户的杠杆币
        // FortLeverToken(leverAddress).burn { 
        //     value: msg.value 
        // } (msg.sender, amount, msg.sender);
        require(index != 0, "FortLever:not exist");
        LeverInfo storage li = _levers[index];

        // 更新目标账号信息
        uint oraclePrice = _queryPrice(li.tokenAddress, msg.sender);

        Account memory account = li.accounts[msg.sender];

        account.balance -= _toUInt128(amount);
        li.accounts[msg.sender] = account;

        // 2. 给用户分发fort
        uint value = _balanceOf(
            amount, 
            _decodeFloat(account.basePrice), 
            uint(account.baseBlock),
            oraclePrice, 
            li.orientation, 
            uint(li.lever)
        );
        FortDCU(FORT_TOKEN_ADDRESS).mint(msg.sender, value);

        // 卖出事件
        emit Sell(index, amount, msg.sender, value);
    }

    /// @dev 清算
    /// @param index 杠杆币编号
    /// @param addresses 清算目标账号数组
    function settle(uint index, address[] calldata addresses) external payable override {

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
                uint balance = _balanceOf(
                    uint(account.balance), 
                    _decodeFloat(account.basePrice), 
                    uint(account.baseBlock),
                    oraclePrice, 
                    li.orientation, 
                    uint(li.lever)
                );

                // 杠杆倍数大于1，并且余额小于最小额度时，可以清算
                if (balance < MIN_VALUE) {
                    
                    accounts[acc] = Account(uint128(0), uint64(0), uint32(0));

                    //emit Transfer(acc, address(0), balance);

                    reward += balance;

                    emit Settle(index, acc, msg.sender, balance);
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

    // 根据杠杆信息计算索引key
    function _getKey(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress, lever, orientation));
    }

    // 买入杠杆币
    function _buy(LeverInfo storage li, uint index, uint fortAmount, address tokenAddress) private {

        require(fortAmount >= 100 ether, "FortLever:at least 100 FORT");

        // 1. 销毁用户的fort
        FortDCU(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 2. 给用户分发杠杆币
        uint oraclePrice = _queryPrice(tokenAddress, msg.sender);
        Account memory account = li.accounts[msg.sender];
        uint basePrice = _decodeFloat(account.basePrice);
        uint balance = uint(account.balance);
        uint newPrice = oraclePrice;
        if (uint(account.baseBlock) > 0) {
            newPrice = (balance + fortAmount) * oraclePrice * basePrice / (
                basePrice * fortAmount + (oraclePrice * balance << 64) / _expMiuT(uint(account.baseBlock))
            );
        }
        
        // 更新接收账号信息
        account.balance += _toUInt128(balance + fortAmount);
        account.basePrice = _encodeFloat(newPrice);
        account.baseBlock = uint32(block.number);
        
        li.accounts[msg.sender] = account;

        // 买入事件
        emit Buy(index, fortAmount, msg.sender);
    }

    // 查询预言机价格
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
        oraclePrice = usdtAmount * _getBase(tokenAddress) / tokenAmount;
    }

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
    
    // 根据新价格计算账户余额
    function _balanceOf(
        uint balance,
        uint basePrice,
        uint baseBlock,
        uint oraclePrice, 
        bool ORIENTATION, 
        uint LEVER
    ) private view returns (uint) {

        if (balance > 0) {
            //uint price = _decodeFloat(account.price);

            uint left;
            uint right;
            // 看涨
            if (ORIENTATION) {
                left = balance + (balance * oraclePrice * LEVER << 64) / basePrice / _expMiuT(baseBlock);
                right = balance * LEVER;
            } 
            // 看跌
            else {
                left = balance * (1 + LEVER);
                right = (balance * oraclePrice * LEVER << 64) / basePrice / _expMiuT(baseBlock);
            }

            if (left > right) {
                balance = left - right;
            } else {
                balance = 0;
            }
        }

        return balance;
    }

    // 计算 e^μT
    function _expMiuT(uint baseBlock) private view returns (uint) {
        return _toUInt(ABDKMath64x64.exp(_toInt128(MIU * (block.number - baseBlock) * 14)));
    }

    // 转换杠杆币信息
    function _toLeverView(LeverInfo storage li, uint index) private view returns (LeverView memory) {
        Account memory account = li.accounts[msg.sender];
        return LeverView(
            index,
            li.tokenAddress,
            uint(li.lever),
            li.orientation,
            uint(account.balance),
            _decodeFloat(account.basePrice),
            uint(account.baseBlock)
        );
    }
}
