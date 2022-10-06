// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../NestBase.sol";

// /// @dev This contract include frequently used data
// contract NestFrequentlyUsed is NestBase {

//     // ETH:
//     // Address of nest token
//     address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
//     // Address of NestOpenPrice contract
//     address constant NEST_OPEN_PRICE = 0xE544cF993C7d477C7ef8E91D28aCA250D135aa03;
//     // Address of nest vault
//     address constant NEST_VAULT_ADDRESS;

//     // BSC:
//     // Address of nest token
//     address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;
//     // Address of NestOpenPrice contract
//     address constant NEST_OPEN_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;
//     // Address of nest vault
//     address constant NEST_VAULT_ADDRESS;

//     // Polygon:
//     // Address of nest token
//     address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;
//     // Address of NestOpenPrice contract
//     address constant NEST_OPEN_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;
//     // Address of nest vault
//     address constant NEST_VAULT_ADDRESS;

//     // KCC:
//     // Address of nest token
//     address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;
//     // Address of NestOpenPrice contract
//     address constant NEST_OPEN_PRICE = 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6;
//     // Address of nest vault
//     address constant NEST_VAULT_ADDRESS;

//     // USDT base
//     uint constant USDT_BASE = 1 ether;
// }

import "../interfaces/INestGovernance.sol";

// TODO:
/// @dev This contract include frequently used data
contract NestFrequentlyUsed is NestBase {

    // Address of nest token
    address NEST_TOKEN_ADDRESS;
    // Address of NestOpenPrice contract
    address NEST_OPEN_PRICE;
    // Address of nest vault
    address NEST_VAULT_ADDRESS;

    // USDT base
    uint constant USDT_BASE = 1 ether;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        NEST_TOKEN_ADDRESS = INestGovernance(newGovernance).getNestTokenAddress();
        NEST_OPEN_PRICE = INestGovernance(newGovernance).checkAddress("nest.v4.openPrice");
        NEST_VAULT_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.vault");
    }
}
