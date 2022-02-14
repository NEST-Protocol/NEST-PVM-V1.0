// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for HedgeSwap
interface IHedgeSwap {

    /// @dev Swap for dcu with exact nest amount
    /// @param nestAmount Amount of nest
    /// @return dcuAmount Amount of dcu acquired
    function swapForDCU(uint nestAmount) external returns (uint dcuAmount);

    /// @dev Swap for token with exact dcu amount
    /// @param dcuAmount Amount of dcu
    /// @return nestAmount Amount of token acquired
    function swapForNEST(uint dcuAmount) external returns (uint nestAmount);

    /// @dev Swap for exact amount of dcu
    /// @param dcuAmount amount of dcu expected
    /// @return nestAmount Amount of token paid
    function swapExactDCU(uint dcuAmount) external returns (uint nestAmount);

    /// @dev Swap for exact amount of token
    /// @param nestAmount Amount of token expected
    /// @return dcuAmount Amount of dcu paid
    function swapExactNEST(uint nestAmount) external returns (uint dcuAmount);
}
