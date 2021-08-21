// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IFortGovernance.sol";

import "./FortBase.sol";

/// @dev Base contract of Fort
contract FortFrequentlyUsed is FortBase {

    // Address of FortToken contract
    //address constant FORT_TOKEN_ADDRESS = ;
    address FORT_TOKEN_ADDRESS;

    // Address of NestPriceFacade contract
    address NEST_PRICE_FACADE_ADDRESS;

    // Genesis block number of fort

    // FortToken contract is created at block height TODO: 11040156. However, because the mining algorithm of Fort v1.0
    // is different from that at present, a new mining algorithm is adopted from Fort v2.1. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the fort begins to decay. According to the circulation when Fort v1.0 is online, the new mining
    // algorithm is used to deduce and convert the fort, and the new algorithm is used to mine the Fort2.1
    // on-line flow, the actual block is TODO: 11040688
    uint constant FORT_GENESIS_BLOCK = 0;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IFortGovernance implementation contract address
    function update(address newGovernance) public override {

        super.update(newGovernance);
        (
            FORT_TOKEN_ADDRESS,//address fortToken,
            ,//address fortDAO,
            ,//address fortEuropeanOption,
            ,//address fortLever,
            ,//address fortVaultForStaking,
            NEST_PRICE_FACADE_ADDRESS //address nestPriceFacade
        ) = IFortGovernance(newGovernance).getBuiltinAddress();
    }
}
