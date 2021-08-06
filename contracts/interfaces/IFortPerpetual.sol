// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 永续合约
interface IFortPerpetual {
    
    /// @dev 表示一个永续合约
    struct Order {
        address owner;
        uint88 lever;
        bool orientation;
        address tokenAddress;
        uint96 bond;
        uint price;
    }

    /// @dev 列出永续合约
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return orderArray List of orders
    function list(uint offset, uint count, uint order) external view returns (Order[] memory orderArray);

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
    ) external view returns (Order[] memory orderArray);

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
    ) external payable;

    /// @dev 平仓
    /// @param index 目标合约编号
    /// @param bond 平仓数量
    function close(uint index,uint bond) external payable;

    /// @dev 补仓
    /// @param index 目标合约编号
    /// @param bond 补仓数量
    function replenish(uint index, uint bond) external payable;

    /// @dev 清算
    /// @param index 清算目标合约单编号
    /// @param bond 清算数量
    function settle(uint index,uint bond) external payable;
}
