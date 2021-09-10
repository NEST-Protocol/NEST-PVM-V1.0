// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/ABDKMath64x64.sol";

import "./interfaces/IFortEuropeanOption.sol";
import "./interfaces/INestPriceFacade.sol";

import "./FortDCU.sol";
import "./FortOptionToken.sol";

// TODO: 测试代码
import "hardhat/console.sol";

/// @dev 杠杆币交易
contract FortLeverToken {

    // 用户账本
    struct Account {
        // 账本-余额
        uint128 balance;
        // 账本-价格
        uint64 price;
        // 解锁区块
        uint32 unlockBlock;
    }

    // USDT代币的基数
    uint constant USDT_BASE = 1000000;

    // 杠杆币创建者
    address immutable OWNER;
    
    // USDT代币地址
    address immutable USDT_TOKEN_ADDRESS;

    // 目标代币地址
    address immutable TOKEN_ADDRESS;

    // 代币基数
    uint immutable TOKEN_BASE;

    // 杠杆倍数
    uint immutable LEVER;

    // 方向，看涨/看跌
    bool immutable ORIENTATION;

    // 代币名称
    string _name;

    // 期权代币映射
    mapping(address=>Account) _accounts;

    // 价格查询合约地址
    address _nestPriceFacade;

    // 最后更新的价格
    uint64 _price;
    
    // 最后更新的区块
    uint32 _updateBlock;

    constructor(
        string memory name_, 
        address usdtTokenAddress, 
        address tokenAddress, 
        uint lever, 
        bool orientation,
        uint tokenBase
    ) {

        _name = name_;
        OWNER = msg.sender;
        USDT_TOKEN_ADDRESS = usdtTokenAddress;
        TOKEN_ADDRESS = tokenAddress;
        LEVER = lever;
        ORIENTATION = orientation;
        TOKEN_BASE = tokenBase;
    }
    
    modifier onlyOwner {
        require(msg.sender == OWNER, "FLT:not owner");
        _;
    }

    /// @dev 获取代币名称
    /// @return 代币名称
    function name() external view returns (string memory) { return _name; }

    /// @dev 设置价格查询合约地址
    /// @param nestPriceFacade 价格查询合约地址
    function setNestPriceFacade(address nestPriceFacade) external onlyOwner {
        _nestPriceFacade = nestPriceFacade;
    }

    // TODO: 主动触发更新的人，按照区块奖励FORT
    /// @dev 触发更新杠杆币全局信息
    /// @param payback 多余的预言机费用退回地址
    /// @return 触发更新的区块间隔（以此作为奖励依据）
    function update(address payback) external payable returns (uint) {

        uint blockNumber = uint(_updateBlock);
        (uint newBlock,) = _update(payback);
        return newBlock - blockNumber;
    }

    // 更新杠杆币全局信息
    function _update(address payback) private returns (uint blockNumber, uint oraclePrice) {

        // 获取token相对于eth的价格
        uint tokenAmount = 1 ether;
        uint fee = msg.value;
        address NEST_PRICE_FACADE_ADDRESS = _nestPriceFacade;
        if (TOKEN_ADDRESS != address(0)) {
            fee = msg.value >> 1;
            (, tokenAmount) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).triggeredPrice {
                value: fee
            } (TOKEN_ADDRESS, payback);
        }

        // 获取usdt相对于eth的价格
        (, uint usdtAmount) = INestPriceFacade(NEST_PRICE_FACADE_ADDRESS).triggeredPrice {
            value: fee
        } (USDT_TOKEN_ADDRESS, payback);

        // 将token价格转化为以usdt为单位计算的价格
        oraclePrice = usdtAmount * TOKEN_BASE / tokenAmount;

        _price = _encodeFloat(oraclePrice);
        _updateBlock = uint32(block.number);
        blockNumber = block.number;
    }

    /// @dev 获取杠杆币信息
    /// @return tokenAddress 目标代币地址
    /// @return price 已经更新的最新价格
    /// @return blockNumber 已经更新的最新价格所在区块
    function getLeverInfo() external view returns (address tokenAddress, uint price, uint blockNumber) {
        return (TOKEN_ADDRESS, _decodeFloat(_price), uint(_updateBlock));
    }

    /// @dev 查看余额
    /// @param acc 目标账号
    /// @return balance 余额
    function balanceOf(address acc) external view returns (uint balance) {
        balance = _balanceOf(_accounts[acc], _decodeFloat(_price));
    }

    /// @dev 根据指定的预言机价格估算余额
    /// @param acc 目标账号
    /// @param oraclePrice 预言机价格
    /// @return balance 余额
    function estimateBalance(address acc, uint oraclePrice) external view returns (uint balance) {
        balance = _balanceOf(_accounts[acc], oraclePrice);
    }

    // 根据新价格计算账户余额
    function _balanceOf(Account memory account, uint oraclePrice) private view returns (uint balance) {

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

    /// @dev 转账
    /// @param to 接收地址
    /// @param value 转账金额
    function transfer(address to, uint value) external payable {

        // TODO: 用户铸币会锁定全部资产，确定此逻辑是否可行
        require(LEVER == 1, "FLT:only for lever 1");
        require(block.number > uint(_accounts[msg.sender].unlockBlock), "FLT:period not expired");

        // 更新杠杆币信息
        (, uint oraclePrice) = _update(msg.sender);

        mapping(address=>Account) storage accounts = _accounts;
        Account memory fromAccount = accounts[msg.sender];
        Account memory toAccount = accounts[to];

        // 更新余额
        fromAccount.balance = _toUInt128(_balanceOf(fromAccount, oraclePrice) - value);
        toAccount.balance = _toUInt128(_balanceOf(toAccount, oraclePrice) + value);
        fromAccount.price = toAccount.price = _encodeFloat(oraclePrice);
        //fromAccount.blockNumber = toAccount.blockNumber = uint32(blockNumber);

        accounts[msg.sender] = fromAccount;
        accounts[to] = toAccount;
    }

    /// @dev 铸币
    /// @param to 接收地址
    /// @param value 铸币数量
    /// @param unlockBlock 解锁区块
    /// @param payback 多余的预言机费用退回地址
    function mint(address to, uint value, uint unlockBlock, address payback) external payable onlyOwner {

        // 更新杠杆币信息
        (, uint oraclePrice) = _update(payback);

        // 更新接收账号信息
        mapping(address=>Account) storage accounts = _accounts;
        Account memory account = accounts[to];
        account.balance = _toUInt128(_balanceOf(account, oraclePrice) + value);
        account.price = _encodeFloat(oraclePrice);
        //account.blockNumber = uint32(blockNumber);
        account.unlockBlock = uint32(unlockBlock);
        
        accounts[to] = account;
    }

    /// @dev 销毁
    /// @param from 目标地址
    /// @param value 销毁数量
    /// @param payback 多余的预言机费用退回地址
    function burn(address from, uint value, address payback) external payable onlyOwner {

        require(block.number > uint(_accounts[from].unlockBlock), "FLT:period not expired");
        require(msg.sender == OWNER, "FLT:not owner");

        // 更新杠杆币信息
        (, uint oraclePrice) = _update(payback);

        // 更新目标账号信息
        mapping(address=>Account) storage accounts = _accounts;
        Account memory account = accounts[from];
        account.balance = _toUInt128(_balanceOf(account, oraclePrice) - value);
        account.price = _encodeFloat(oraclePrice);
        //account.blockNumber = uint32(blockNumber);

        accounts[from] = account;
    }

    /// @dev 清算账号
    /// @param acc 清算目标账号
    /// @param payback 多余的预言机费用退回地址
    /// @param minValue 最小余额，杠杆倍数超过一时，余额小于此值会被清算
    /// @return 清算可以获得的奖励数量
    function settle(address acc, uint minValue, address payback) external payable onlyOwner returns (uint) {

        // 更新杠杆币信息
        (, uint oraclePrice) = _update(payback);

        // 更新目标账号信息
        Account memory account = _accounts[acc];
        uint balance = _balanceOf(account, oraclePrice);

        // 杠杆倍数大于1，并且余额小于最小额度时，可以清算
        if (LEVER > 1 && balance < minValue) {
            
            _accounts[acc] = Account(uint128(0), uint64(0), uint32(0));
            return balance;
        }
        
        // 不能清算
        return 0;
    }

    // TODO: 以下方发定义为public的是为了测试，发布时需要改为私有的
    
    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) public pure returns (uint64) {

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
    function _decodeFloat(uint64 floatValue) public pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }

    // 将uint转化为uint128，有截断检查
    function _toUInt128(uint value) public pure returns (uint128) {
        require(value < 0x100000000000000000000000000000000);
        return uint128(value);
    }
}
