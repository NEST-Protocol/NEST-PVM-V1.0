// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IHedgeGovernance.sol";

import "./HedgeBase.sol";

// /// @dev Base contract of Hedge
// contract HedgeFrequentlyUsed is HedgeBase {

//     // Address of DCU contract
//     address constant DCU_TOKEN_ADDRESS = 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF;

//     // Address of NestOpenPrice contract
//     address constant NEST_OPEN_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;
    
//     // USDT代币的基数
//     uint constant USDT_BASE = 1 ether;
// }

/// @dev Base contract of Hedge
contract HedgeFrequentlyUsed is HedgeBase {

    // TODO: 改为正确的地址
    // TODO: 先部署DCU，确定地址后，再修改
      
    // Address of DCU contract
    //address constant DCU_TOKEN_ADDRESS = ;
    address DCU_TOKEN_ADDRESS;

    // Address of NestPriceFacade contract
    //address constant NEST_OPEN_PRICE = 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A;
    address NEST_OPEN_PRICE;

    // // USDT代币地址
    // //address constant USDT_TOKEN_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // address USDT_TOKEN_ADDRESS;

    // TODO: 修改为1e18
    // USDT代币的基数
    uint constant USDT_BASE = 1 ether;

    // // ETH/USDT报价通道id
    // uint constant ETH_USDT_CHANNEL_ID = 0;

    // // σ-usdt	0.00021368		波动率，每个币种独立设置（年化120%）
    // uint constant SIGMA_SQ = 45659142400;

    // // μ-usdt	0.000000025367		漂移系数，每个币种独立设置（年化80%）
    // uint constant MIU = 467938556917;
    
    // // 区块时间
    // uint constant BLOCK_TIME = 3;

    // function _toUSDTPrice(uint rawPrice) internal pure returns (uint) {
    //     return 2000 ether * 1 ether / rawPrice;
    // }

    // TODO: 删除
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
            NEST_OPEN_PRICE //address nestPriceFacade
        ) = IHedgeGovernance(newGovernance).getBuiltinAddress();
    }

    // // TODO: 测试方法
    // function setUsdtTokenAddress(address usdtTokenAddress) external {
    //     USDT_TOKEN_ADDRESS = usdtTokenAddress;
    // }
}
