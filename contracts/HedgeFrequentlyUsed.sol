// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IHedgeGovernance.sol";

import "./HedgeBase.sol";

/// @dev Base contract of Hedge
contract HedgeFrequentlyUsed is HedgeBase {

    // TODO: 改为正确的地址
    // TODO: 先部署DCU，确定地址后，再修改
      
    // Address of DCU contract
    //address constant DCU_TOKEN_ADDRESS = ;
    address DCU_TOKEN_ADDRESS;

    // Address of NestPriceFacade contract
    address NEST_PRICE_FACADE_ADDRESS;
    
    // USDT代币地址
    //address constant USDT_TOKEN_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address USDT_TOKEN_ADDRESS;

    // USDT代币的基数
    uint constant USDT_BASE = 1000000;

    // Genesis block number of dcu
    uint constant DCU_GENESIS_BLOCK = 0;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IHedgeGovernance implementation contract address
    function update(address newGovernance) public override {

        super.update(newGovernance);
        (
            DCU_TOKEN_ADDRESS,//address dcuToken,
            ,//address hedgeDAO,
            ,//address hedgeOptions,
            ,//address hedgeFutures,
            ,//address hedgeVaultForStaking,
            NEST_PRICE_FACADE_ADDRESS //address nestPriceFacade
        ) = IHedgeGovernance(newGovernance).getBuiltinAddress();
    }

    // TODO: 测试方法
    function setUsdtTokenAddress(address usdtTokenAddress) external {
        USDT_TOKEN_ADDRESS = usdtTokenAddress;
    }
}
