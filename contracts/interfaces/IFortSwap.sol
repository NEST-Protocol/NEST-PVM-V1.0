// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 定义dcu兑换合约接口
interface IFortSwap {

    /// @dev 使用确定数量的token兑换dcu
    /// @param tokenAmount token数量
    /// @return dcuAmount 兑换到的dcu数量
    function swapForDCU(uint tokenAmount) external returns (uint dcuAmount);

    /// @dev 使用确定数量的dcu兑换token
    /// @param dcuAmount dcu数量
    /// @return tokenAmount 兑换到的token数量
    function swapForToken(uint dcuAmount) external returns (uint tokenAmount);

    /// @dev 使用token兑换确定数量的dcu
    /// @param dcuAmount 预期得到的dcu数量
    /// @return tokenAmount 支付的token数量
    function swapExactDCU(uint dcuAmount) external returns (uint tokenAmount);

    /// @dev 使用dcu兑换确定数量的token
    /// @param tokenAmount 预期得到的token数量
    /// @return dcuAmount 支付的dcu数量
    function swapExactToken(uint tokenAmount) external returns (uint dcuAmount);
}
