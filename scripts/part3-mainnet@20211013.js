// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const HedgeGovernance = await ethers.getContractFactory('HedgeGovernance');
    const DCU = await ethers.getContractFactory('DCU');
    const HedgeDAO = await ethers.getContractFactory('HedgeDAO');
    const HedgeOptions = await ethers.getContractFactory('HedgeOptions');
    const HedgeFutures = await ethers.getContractFactory('HedgeFutures');
    const HedgeVaultForStaking = await ethers.getContractFactory('HedgeVaultForStaking');

    console.log('** 开始部署合约 part3-mainnet@20211013.js **');
    
    // TODO:
    const hedgeVaultForStaking = await HedgeVaultForStaking.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeVaultForStaking: ' + hedgeVaultForStaking.address);

    // 2. 设置挖矿启动参数
    // 取一个好数字，锁仓准备取为 13408888 ~ 13492888
    await hedgeVaultForStaking.setConfig(toBigInt(1), 13408888, 13492888);

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        hedgeVaultForStaking: hedgeVaultForStaking,
    };

    return contracts;
};