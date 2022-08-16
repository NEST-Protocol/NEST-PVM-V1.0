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
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestVault = await ethers.getContractFactory('NestVault');
    const NestOptions = await ethers.getContractFactory('NestOptions');
    const NestFutures = await ethers.getContractFactory('NestFutures');
    const NestProbability = await ethers.getContractFactory('NestProbability');
    const NestBuybackPool = await ethers.getContractFactory('NestBuybackPool');

    console.log('** Deploy: mainnet@20220729.js **');
    
    // ** Deploy: mainnet@20220729.js **
    // nestVault: 0x12858F7f24AA830EeAdab2437480277E92B0723a
    // pusd: 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0
    // hbtc: 0x0316EB71485b0Ab14103307bf65a021042c6d380
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // nest: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
    // nestPriceFacade: 0xE544cF993C7d477C7ef8E91D28aCA250D135aa03
    // nestGovernance: 0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5
    // nestOptions: 0x10F7f08A278e495CBCa66388A2400fF0deFe3122
    // nestFutures: 0x0E48e068958b3E683a664FB81697F7046f83C3A8
    // nestProbability: 0x0ef5A21Aa062BA49c9c429b256d618d68FD2e008
    // nestBuybackPool: 0x7b65629A811eBB0d6CC99bDc4d1d606f8F707125
    // proxyAdmin: 0xCA52f25f37d213CeD3dDE81a539e64464dEa8f3C

    //const nestVault = await NestVault.deploy(); //await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0x12858F7f24AA830EeAdab2437480277E92B0723a');
    console.log('nestVault: ' + nestVault.address);

    // HBTC&ETH&NEST|PUSD

    const pusd = await TestERC20.attach('0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0');
    console.log('pusd: ' + pusd.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0x0316EB71485b0Ab14103307bf65a021042c6d380');
    console.log('hbtc: ' + hbtc.address);

    //const dcu = await TestERC20.deploy('DCU', 'DCU', 18);
    const dcu = await TestERC20.attach('0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF');
    console.log('dcu: ' + dcu.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
    console.log('nest: ' + nest.address);

    //const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    const nestPriceFacade = await NestPriceFacade.attach('0xE544cF993C7d477C7ef8E91D28aCA250D135aa03');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestOptions = await upgrades.deployProxy(NestOptions, [nestGovernance.address], { initializer: 'initialize' });
    const nestOptions = await NestOptions.attach('0x10F7f08A278e495CBCa66388A2400fF0deFe3122');
    console.log('nestOptions: ' + nestOptions.address);

    //const nestFutures = await upgrades.deployProxy(NestFutures, [nestGovernance.address], { initializer: 'initialize' });
    const nestFutures = await NestFutures.attach('0x0E48e068958b3E683a664FB81697F7046f83C3A8');
    console.log('nestFutures: ' + nestFutures.address);

    //const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    const nestProbability = await NestProbability.attach('0x0ef5A21Aa062BA49c9c429b256d618d68FD2e008');
    console.log('nestProbability: ' + nestProbability.address);
    
    //const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    const nestBuybackPool = await NestBuybackPool.attach('0x7b65629A811eBB0d6CC99bDc4d1d606f8F707125');
    console.log('nestBuybackPool: ' + nestBuybackPool.address);

    // // 2.4. Register ETH ans HBTC
    // console.log('7. nestOptions.register(eth.address)');
    // await nestOptions.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 1,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });

    // console.log('8. nestOptions.register(hbtc.address)');
    // await nestOptions.register(hbtc.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });
    
    // // 3.4. Register ETH and HBTC
    // console.log('9. nestFutures.register(eth.address)');
    // await nestFutures.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 1,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });
    // console.log('10. nestFutures.register(hbtc.address)');
    // await nestFutures.register(hbtc.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });

    // console.log('8.2 create lever');
    
    // // 3.5. Register levels for ETH
    // console.log('13. create eth long lever');
    // await nestFutures.create(eth.address, [1, 2, 3, 4, 5], true);
    // console.log('14. create eth short lever');
    // await nestFutures.create(eth.address, [1, 2, 3, 4, 5], false);
    
    // // 3.5. Register levels for HBTC
    // console.log('13. create hbtc long lever');
    // await nestFutures.create(hbtc.address, [1, 2, 3, 4, 5], true);
    // console.log('14. create hbtc short lever');
    // await nestFutures.create(hbtc.address, [1, 2, 3, 4, 5], false);

    // await nestVault.approve(nestOptions.address, 10000000000000000000000000n);
    // await nestVault.approve(nestFutures.address, 10000000000000000000000000n);
    await nestVault.approve(nestProbability.address, 500000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 14;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        pusd: pusd,
        hbtc: hbtc,
        dcu: dcu,
        nest: nest,

        nestGovernance: nestGovernance,
        nestOptions: nestOptions,
        nestFutures: nestFutures,
        nestProbability: nestProbability,
        nestPriceFacade: nestPriceFacade,
        nestBuybackPool: nestBuybackPool,

        BLOCK_TIME: BLOCK_TIME,
        USDT_DECIMALS: 18,

        MIU_LONG: MIU_LONG,
        MIU_SHORT: MIU_SHORT,
        miuT: function(orientation, blocks) {
            return Math.exp((orientation ? MIU_LONG : MIU_SHORT) * blocks * BLOCK_TIME);
        }
    };

    return contracts;
};