// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Base contract of Hedge
contract CommonParameter {

    // σ-usdt	0.00021368		波动率，每个币种独立设置（年化120%）
    uint constant SIGMA_SQ = 45659142400;

    // μ-usdt-long 看涨漂移系数，每天0.03%
    uint constant MIU_LONG = 64051194700;

    // μ-usdt-short 看跌漂移系数，0
    uint constant MIU_SHORT= 0;
}
