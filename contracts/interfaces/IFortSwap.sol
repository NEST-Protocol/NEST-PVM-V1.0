// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for FortSwap
interface IFortSwap {

    /// @dev Swap for dcu with exact token amount
    /// @param tokenAmount Amount of token
    /// @return dcuAmount Amount of dcu acquired
    function swapForDCU(uint tokenAmount) external returns (uint dcuAmount);

    /// @dev Swap for token with exact dcu amount
    /// @param dcuAmount Amount of dcu
    /// @return tokenAmount Amount of token acquired
    function swapForToken(uint dcuAmount) external returns (uint tokenAmount);

    /// @dev Swap for exact amount of dcu
    /// @param dcuAmount Amount of dcu expected
    /// @return tokenAmount Amount of token paid
    function swapExactDCU(uint dcuAmount) external returns (uint tokenAmount);

    /// @dev Swap for exact amount of token
    /// @param tokenAmount Amount of token expected
    /// @return dcuAmount Amount of dcu paid
    function swapExactToken(uint tokenAmount) external returns (uint dcuAmount);
}
