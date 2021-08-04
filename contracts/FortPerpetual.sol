// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./FortToken.sol";
import "./BinaryOptionToken.sol";

/// @dev 永续合约
contract FortPerpetual {
    
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
    }

    function close(
        address tokenAddress,
        address bond
    ) external payable {

    }

    /// @dev 结算
    /// @param tokenAddress 期权合约地址
    /// @param amount 结算的期权分数
    function settle(
        address tokenAddress,
        uint amount
    ) external payable {
    }
}
