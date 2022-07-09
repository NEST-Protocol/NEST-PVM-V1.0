// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../NestBase.sol";

// /// @dev This contract include frequently used data
// contract NestFrequentlyUsed is NestBase {

//     // Address of nest token
//     address NEST_TOKEN_ADDRESS;

//     // Address of NestOpenPrice contract
//     address constant NEST_OPEN_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;

//     // Address of nest vault
//     address NEST_VAULT_ADDRESS;

//     // USDT base
//     uint constant USDT_BASE = 1 ether;
// }

import "../interfaces/INestGovernance.sol";

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

    // TODO:
    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        NEST_TOKEN_ADDRESS = INestGovernance(newGovernance).getNestTokenAddress();
        NEST_OPEN_PRICE = INestGovernance(newGovernance).checkAddress("nest.v4.openPrice");
        NEST_VAULT_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.vault");
    }
}
