// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../HedgeBase.sol";

/// @dev Base contract of Hedge
contract HedgeFrequentlyUsed is HedgeBase {

    // Address of DCU contract
    address constant DCU_TOKEN_ADDRESS = 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF;

    // NEST代币地址
    address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;

    // Address of NestOpenPrice contract
    address constant NEST_OPEN_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;
    
    // USDT代币的基数
    uint constant USDT_BASE = 1 ether;
}

// import "../interfaces/IHedgeGovernance.sol";
// // 主网部署时，需要使用上面的常量版本
// /// @dev Base contract of Hedge
// contract HedgeFrequentlyUsed is HedgeBase {

//     // NEST代币地址
//     address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;

//     // Address of DCU contract
//     //address constant DCU_TOKEN_ADDRESS = ;
//     address DCU_TOKEN_ADDRESS;

//     // Address of NestPriceFacade contract
//     //address constant NEST_OPEN_PRICE = 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A;
//     address NEST_OPEN_PRICE;

//     // USDT代币地址（占位符，无用）
//     //address constant USDT_TOKEN_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
//     //address USDT_TOKEN_ADDRESS;

//     // USDT代币的基数
//     uint constant USDT_BASE = 1 ether;

//     /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
//     ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
//     /// @param newGovernance IHedgeGovernance implementation contract address
//     function update(address newGovernance) public override {

//         super.update(newGovernance);
//         (
//             DCU_TOKEN_ADDRESS,//address dcuToken,
//             ,//address hedgeDAO,
//             ,//address hedgeOptions,
//             ,//address hedgeFutures,
//             ,//address hedgeVaultForStaking,
//             NEST_OPEN_PRICE //address nestPriceFacade
//         ) = IHedgeGovernance(newGovernance).getBuiltinAddress();
//     }
// }
