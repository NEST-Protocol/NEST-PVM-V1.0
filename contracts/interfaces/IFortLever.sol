// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 杠杆币交易
interface IFortLever {
    
    /// @dev 列出历史杠杆币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return leverArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (address[] memory leverArray);

    /// @dev 获取杠杆币信息
    function getLeverToken(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view returns (address);

    /// @dev 买入杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌2个方向
    /// @param fortAmount 支付的fort数量
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint fortAmount
    ) external payable;

    /// @dev 卖出杠杆币
    /// @param leverAddress 目标合约地址
    /// @param amount 卖出数量
    function sell(
        address leverAddress,
        uint amount
    ) external payable;

    /// @dev 清算
    /// @param leverAddress 目标合约地址
    /// @param account 清算账号
    function settle(
        address leverAddress,
        address account
    ) external payable;
}
