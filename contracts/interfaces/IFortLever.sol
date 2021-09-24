// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 定义杠杆币交易接口
interface IFortLever {
    
    struct LeverView {
        uint index;
        address tokenAddress;
        uint lever;
        bool orientation;
        
        uint balance;
    }

    /// @dev 列出历史杠杆币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return leverArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (LeverView[] memory leverArray);

    /// @dev 创建杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external;

    /// @dev 获取已经开通的杠杆币数量
    /// @return 已经开通的杠杆币数量
    function getTokenCount() external view returns (uint);

    /// @dev 获取杠杆币地址
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 杠杆币地址
    function getLeverToken(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view returns (LeverView memory);

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
    ) external payable;

    /// @dev 买入杠杆币
    /// @param index 杠杆币编号
    /// @param fortAmount 支付的fort数量
    function buyDirect(
        uint index,
        uint fortAmount
    ) external payable;

    /// @dev 卖出杠杆币
    /// @param index 杠杆币编号
    /// @param amount 卖出数量
    function sell(
        uint index,
        uint amount
    ) external payable;

    /// @dev 清算
    /// @param index 杠杆币编号
    /// @param addresses 清算目标账号数组
    function settle(
        uint index,
        address[] calldata addresses
    ) external payable;

    /// @dev 触发更新价格，获取FORT奖励
    /// @param leverAddressArray 要更新的杠杆币合约地址
    /// @param payback 多余的预言机费用退回地址
    function updateLeverInfo(
        address[] memory leverAddressArray, 
        address payback
    ) external payable;
}
