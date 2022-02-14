// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Base contract of Hedge
contract CommonParameter {

    // σ-usdt	0.00021368		volatility 120% per year
    uint constant SIGMA_SQ = 45659142400;

    // μ-usdt-long  call drift coefficient. 0.03% per day
    uint constant MIU_LONG = 64051194700;

    // μ-usdt-short put drift coefficient. 0
    uint constant MIU_SHORT= 0;
}
