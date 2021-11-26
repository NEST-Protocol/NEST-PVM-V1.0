// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev DCU分发合约
interface IHedgeSwap {

    // /// @dev 通过存入nest来初始化资金池，没存入x个nest，资金池增加x个dcu和x个nest，同时用户得到x个dcu
    // /// @param amount 存入数量
    // function deposit(uint amount) external;
    
    /// @dev 使用确定数量的nest兑换dcu
    /// @param nestAmount nest数量
    /// @return dcuAmount 兑换到的dcu数量
    function swapForDCU(uint nestAmount) external returns (uint dcuAmount);

    /// @dev 使用确定数量的dcu兑换nest
    /// @param dcuAmount dcu数量
    /// @return nestAmount 兑换到的nest数量
    function swapForNEST(uint dcuAmount) external returns (uint nestAmount);

    /// @dev 使用nest兑换确定数量的dcu
    /// @param dcuAmount 预期得到的dcu数量
    /// @return nestAmount 支付的nest数量
    function swapExactDCU(uint dcuAmount) external returns (uint nestAmount);

    /// @dev 使用dcu兑换确定数量的nest
    /// @param nestAmount 预期得到的nest数量
    /// @return dcuAmount 支付的dcu数量
    function swapExactNEST(uint nestAmount) external returns (uint dcuAmount);
}
