// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IFortPerpetual.sol";
import "./FortToken.sol";
import "./FortOptionToken.sol";

/// @dev 永续合约
contract FortPerpetual is IFortPerpetual {
    
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

    struct Account {
        uint64[] orders;
    }

    Order[] _orders;

    mapping(address=>Account) _accounts; 

    /// @dev 列出永续合约
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function list(uint offset, uint count, uint order) external view override returns (Order[] memory orderArray) {

        Order[] storage orders = _orders;
        orderArray = new Order[](count);

        if (order == 0) {
            uint length = orders.length - offset - 1;
            for (uint i = 0; i < count; ++i) {
                orderArray[i] = orders[length - i];
            }
        } else {
            for (uint i = 0; i < count; ++i) {
                orderArray[i] = orders[i + offset];
            }
        }
    }

    /// @dev 列出用户的永续合约
    /// @param owner 目标用户
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function find(
        address owner, 
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (Order[] memory orderArray) {

        Order[] storage orders = _orders;
        uint64[] storage indexes = _accounts[owner].orders;
        orderArray = new Order[](count);

        if (order == 0) {
            uint length = indexes.length - offset - 1;
            for (uint i = 0; i < count; ++i) {
                orderArray[i] = orders[indexes[length - i]];
            }
        } else {
            for (uint i = 0; i < count; ++i) {
                orderArray[i] = orders[indexes[i + offset]];
            }
        }
    }

    // 币种对 Y/X 、开仓价P1、杠杆倍数L、保证金数量A、方向Ks、清算率C、手续费F、持有时间T
    /// @dev 开仓
    /// @param tokenAddress 目前Fort系统支持ETH/USDT、NEST/ETH、COFI/ETH、HBTC/ETH
    /// @param lever 杠杆倍数
    /// @param bond 保证金数量
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    function open(
        address tokenAddress,
        uint lever,
        uint bond,
        bool orientation
    ) external payable override {

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
    /// @param index 目标合约编号
    /// @param bond 平仓数量
    function close(
        uint index,
        uint bond
    ) external payable override {

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
    /// @param index 目标合约编号
    /// @param bond 补仓数量
    function replenish(uint index, uint bond) external payable override {

        FortToken(_fortToken).burn(msg.sender, bond); 
        Order storage order = _orders[index];
        order.bond = uint96(uint(order.bond) + bond);
    }

    /// @dev 清算
    /// @param index 清算目标合约单编号
    /// @param bond 清算数量
    function settle(uint index,uint bond) external payable override {
        
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
