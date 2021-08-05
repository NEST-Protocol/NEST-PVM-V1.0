// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./FortToken.sol";
import "./FortOptionToken.sol";

/// @dev 永续合约
contract FortPerpetual {
    
        // fort代币地址
    address _fortToken;

    // INestPriceFacade地址
    address _nestPriceFacade;

    constructor() {
    }

    function setFortToken(address fortToken) external {
        _fortToken = fortToken;
    }

    function setNestPriceFacade(address nestPriceFacade) external {
        _nestPriceFacade = nestPriceFacade;
    }

    /// @dev 表示一个永续合约
    struct Order {
        address owner;
        uint88 lever;
        bool orientation;
        address tokenAddress;
        uint96 bond;
        uint price;
    }

    struct Account {
        uint64[] orders;
    }

    Order[] _orders;

    mapping(address=>Account) _accounts; 

    // 币种对 Y/X 、开仓价P1、杠杆倍数L、保证金数量A、方向Ks、清算率C、手续费F、持有时间T
    /// @dev 开仓
    /// @param tokenAddress 目前Fort系统支持ETH/USDT、NEST/ETH、COFI/ETH、HBTC/ETH
    /// @param lever 杠杆倍数
    /// @param bond 保证金数量
    /// @param orientation 看涨/看跌2个方向
    function open(
        address tokenAddress,
        uint lever,
        uint bond,
        bool orientation
    ) external payable {

        // 1. 销毁保证金
        FortToken(_fortToken).burn(msg.sender, bond); 

        // 2. 获取预言机价格
        (
            ,//uint blockNumber, 
            uint oraclePrice
        ) = INestPriceFacade(_nestPriceFacade).triggeredPrice {
            value: msg.value
        } (
            tokenAddress, 
            msg.sender
        );

        // 3. 给用户分发持仓凭证
        Order[] storage orders = _orders;
        _accounts[msg.sender].orders.push(uint64(orders.length));
        orders.push(Order(
            msg.sender,
            uint88(lever),
            orientation,
            tokenAddress,
            uint96(bond),
            oraclePrice
        ));
    }

    /// @dev 平仓
    function close(
        uint index,
        uint bond
    ) external payable {
        Order storage order = _orders[index];
        require(msg.sender == order.owner, "FortPerpetual: must owner");

        uint orderBond = uint(order.bond);
        // 扣除保证金
        order.bond = uint96(orderBond - bond);

        // 计算收益
        uint earned = 0;
        
        FortToken(_fortToken).mint(msg.sender, earned);
    }

    /// @dev 补仓
    function replenish(uint index, uint bond) external {
        FortToken(_fortToken).burn(msg.sender, bond); 
        Order storage order = _orders[index];
        order.bond = uint96(uint(order.bond) + bond);
    }

    /// @dev 清算
    /// @param index 清算目标合约单编号
    /// @param bond 结算的份数
    function settle(
        uint index,
        uint bond
    ) external payable {
        Order storage order = _orders[index];
        // TODO: 检查清算条件
        uint orderBond = uint(order.bond);
        // 扣除保证金
        order.bond = uint96(orderBond - bond);

        // 计算清算收益
        uint earned = 0;
        FortToken(_fortToken).mint(msg.sender, earned);
    }
}
