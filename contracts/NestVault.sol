// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestVault.sol";

// import "./NestBase.sol";

// /// @dev Nest Vault
// contract NestVault is NestBase, INestVault {

//     // ETH:
//     // Address of nest token
//     address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;

//     // // BSC:
//     // // Address of nest token
//     // address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;

//     // Allowances amount of each contract can transferred once
//     mapping(address=>uint) _allowances;

//     /// @dev Approve allowance amount to target contract address
//     /// @dev target Target contract address
//     /// @dev limit Amount limit can transferred once
//     function approve(address target, uint limit) external override onlyGovernance {
//         _allowances[target] = limit;
//         emit Approved(target, limit);
//     }

//     /// @dev Transfer to by allowance
//     /// @param to Target receive address
//     /// @param amount Transfer amount
//     function transferTo(address to, uint amount) external override {
//         require(_allowances[msg.sender] >= amount, "NV:exceeded allowance");
//         TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, to, amount);
//     }
// }

import "./custom/NestFrequentlyUsed.sol";

// TODO: Use NestBase
/// @dev Nest Vault
contract NestVault is NestFrequentlyUsed, INestVault {

    // ETH:
    // Address of nest token
    // address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;

    // // BSC:
    // // Address of nest token
    // address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;

    // Allowances amount of each contract can transferred once
    mapping(address=>uint) _allowances;

    /// @dev Approve allowance amount to target contract address
    /// @dev target Target contract address
    /// @dev limit Amount limit can transferred once
    function approve(address target, uint limit) external override onlyGovernance {
        _allowances[target] = limit;
        emit Approved(target, limit);
    }

    /// @dev Transfer to by allowance
    /// @param to Target receive address
    /// @param amount Transfer amount
    function transferTo(address to, uint amount) external override {
        require(_allowances[msg.sender] >= amount, "NV:exceeded allowance");
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, to, amount);
    }
}
