// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestVault.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Nest Vault
contract NestVault is NestFrequentlyUsed, INestVault {

    // Allowances amount of each contract can transferred once
    mapping(address=>uint) _allowances;

    /// @dev Approve allowance amount to target contract address
    /// @dev target Target contract address
    /// @dev limit Amount limit can transferred once
    function approve(address target, uint limit) external override onlyGovernance {
        _allowances[target] = limit;
    }

    /// @dev Transfer to by allowance
    /// @param to Target receive address
    /// @param amount Transfer amount
    function transferTo(address to, uint amount) external override {
        require(_allowances[msg.sender] >= amount, "NV:exceeded allowance");
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, to, amount);
    }
}
