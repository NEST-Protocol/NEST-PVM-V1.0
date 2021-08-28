// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/ABDKMath64x64.sol";

import "./interfaces/IFortEuropeanOption.sol";
import "./interfaces/INestPriceFacade.sol";

import "./FortToken.sol";
import "./FortOptionToken.sol";

import "hardhat/console.sol";

/// @dev 杠杆币交易
contract FortLeverToken {

    // 用户账本
    struct Account {
        // 账本-价格
        uint price;
        // 账本-余额
        uint balance;
        // 账本-价格所在区块号
        uint block;
        // 最后的铸币区块
        uint lastMintBlock;
    }

    // 最小余额数量，余额小于此值会被清算
    uint constant MIN_VALUE = 1 ether;

    // 买入杠杆币和其他交易之间最小的间隔区块数
    uint constant MIN_PERIOD = 10;

    // 杠杆币创建者
    address immutable OWNER;
    
    // 目标代币地址
    address immutable TOKEN_ADDRESS;

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
    uint _price;
    
    // 最后更新的区块
    uint _block;

    constructor(string memory name_, address tokenAddress, uint lever, bool orientation) {

        _name = name_;
        OWNER = msg.sender;
        TOKEN_ADDRESS = tokenAddress;
        LEVER = lever;
        ORIENTATION = orientation;
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
    function updateLeverInfo(address payback) external payable returns (uint) {

        uint blockNumber = _block;
        (uint newBlock,) = _updateLeverInfo(payback);
        return newBlock - blockNumber;
    }

    function _updateLeverInfo(address payback) private returns (uint blockNumber, uint oraclePrice) {

        (
            blockNumber, 
            oraclePrice
        ) = INestPriceFacade(_nestPriceFacade).triggeredPrice {
            value: msg.value
        } (
            TOKEN_ADDRESS, 
            payback
        );

        _price = oraclePrice;
        _block = blockNumber;
    }

    /// @dev 获取杠杆币信息
    /// @return tokenAddress 目标代币地址
    /// @return price 已经更新的最新价格
    /// @return blockNumber 已经更新的最新价格所在区块
    function getLeverInfo() external view returns (address tokenAddress, uint price, uint blockNumber) {
        return (TOKEN_ADDRESS, _price, _block);
    }

    // function getTokenAddress() external view returns (address) {
    //     return TOKEN_ADDRESS;
    // }

    /// @dev 查看余额
    /// @param acc 目标账号
    /// @return 余额
    function balanceOf(address acc) external view returns (uint) {

        Account storage account = _accounts[acc];
        uint oraclePrice = _price;
        uint price = account.price;
        uint balance = account.balance;

        uint left;
        uint right;
        // 看涨
        if (ORIENTATION) {
            left = balance + balance * price * LEVER / oraclePrice;
            right = balance * LEVER;
        } 
        // 看跌
        else {
            left = balance * (1 + LEVER);
            right = balance * price * LEVER / oraclePrice;
        }

        if (left > right) {
            return left - right;
        }
        return 0;
    }

    /// @dev 转账
    /// @param to 接收地址
    /// @param value 转账金额
    function transfer(address to, uint value) external payable {

        // TODO: 用户铸币会锁定全部资产，确定此逻辑是否可行
        require(LEVER == 1, "FLT:only for lever 1");
        require(block.number > _accounts[msg.sender].lastMintBlock + MIN_PERIOD, "FLT:period not expired");

        // 更新杠杆币信息
        (uint blockNumber, uint oraclePrice) = _updateLeverInfo(msg.sender);

        // 更新发送账号信息
        _update(msg.sender, blockNumber, oraclePrice);
        // 更新接收账号信息
        _update(to, blockNumber, oraclePrice);

        // 更新余额
        _accounts[msg.sender].balance -= value;
        _accounts[to].balance += value;
    }

    /// @dev 铸币
    /// @param to 接收地址
    /// @param value 铸币数量
    /// @param payback 多余的预言机费用退回地址
    function mint(address to, uint value, address payback) external payable onlyOwner {

        // 更新杠杆币信息
        (uint blockNumber, uint oraclePrice) = _updateLeverInfo(payback);

        // 更新接收账号信息
        _update(to, blockNumber, oraclePrice);

        // 更新账户信息
        Account storage account = _accounts[to];
        account.balance += value;
        //account.price = oraclePrice;
        //account.block = blockNumber;
        account.lastMintBlock = block.number;
    }

    /// @dev 销毁
    /// @param from 目标地址
    /// @param value 销毁数量
    /// @param payback 多余的预言机费用退回地址
    function burn(address from, uint value, address payback) external payable onlyOwner {

        require(block.number > _accounts[from].lastMintBlock + MIN_PERIOD, "FLT:period not expired");
        require(msg.sender == OWNER, "FLT:not owner");

        // 更新杠杆币信息
        (uint blockNumber, uint oraclePrice) = _updateLeverInfo(payback);

        // 更新目标账号信息
        _update(from, blockNumber, oraclePrice);

        // 更新账户信息
        Account storage account = _accounts[from];
        account.balance -= value;
        //account.price = price;
        //account.block = block;
    }

    // 更新目标账号信息
    function _update(address acc, uint blockNumber, uint oraclePrice) private returns (uint balance) {

        // TODO: 结算逻辑
        Account storage account = _accounts[acc];
        uint price = account.price;
        balance = account.balance;

        uint left;
        uint right;
        // 看涨
        if (ORIENTATION) {
            left = balance + balance * price * LEVER / oraclePrice;
            right = balance * LEVER;
        } 
        // 看跌
        else {
            left = balance * (1 + LEVER);
            right = balance * price * LEVER / oraclePrice;
        }

        if (left > right) {
            balance = left - right;
        } else {
            balance = 0;
        }

        account.balance = balance;
        account.price = oraclePrice;
        account.block = blockNumber;
    }

    /// @dev 清算账号
    /// @param acc 清算目标账号
    /// @param payback 多余的预言机费用退回地址
    /// @return 清算可以获得的奖励数量
    function settle(address acc, address payback) external payable returns (uint) {

        // 更新杠杆币信息
        (uint blockNumber, uint oraclePrice) = _updateLeverInfo(payback);

        // 更新目标账号信息
        uint balance = _update(acc, blockNumber, oraclePrice);

        // 杠杆倍数大于1，并且余额小于最小额度时，可以清算
        if (LEVER > 1 && balance < MIN_VALUE) {
            Account storage account = _accounts[acc];
            account.balance = 0;
            account.block = 0;
            account.price = 0;

            return balance;
        }
        
        // 不能清算
        return 0;
    }
}
