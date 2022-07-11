// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for Nest Vault
interface INestVault {

    /// @dev Approve allowance amount to target contract address
    /// @dev target Target contract address
    /// @dev limit Amount limit can transferred once
    function approve(address target, uint limit) external;

    /// @dev Transfer to by allowance
    /// @param to Target receive address
    /// @param amount Transfer amount
    function transferTo(address to, uint amount) external;
}
