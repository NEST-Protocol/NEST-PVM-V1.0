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

    // 先部署NestVault,然后更新到常量地址
    //const nestVault = await NestVault.deploy(); //await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0x12858F7f24AA830EeAdab2437480277E92B0723a');
    console.log('nestVault: ' + nestVault.address);
    return;
    // console.log('先在NestFrequentlyUsed中将常用地址设置为ETH的');
    return;
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

    const nestOptions = await upgrades.deployProxy(NestOptions, [nestGovernance.address], { initializer: 'initialize' });
    //const nestOptions = await NestOptions.attach('0x0000000000000000000000000000000000000000');
    console.log('nestOptions: ' + nestOptions.address);

    const nestFutures = await upgrades.deployProxy(NestFutures, [nestGovernance.address], { initializer: 'initialize' });
    //const nestFutures = await NestFutures.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures: ' + nestFutures.address);

    const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    //const nestProbability = await NestProbability.attach('0x0000000000000000000000000000000000000000');
    console.log('nestProbability: ' + nestProbability.address);
    
    const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    // const nestBuybackPool = await NestBuybackPool.attach('0x0000000000000000000000000000000000000000');
    console.log('nestBuybackPool: ' + nestBuybackPool.address);

    // 2.4. Register ETH ans HBTC
    console.log('7. nestOptions.register(eth.address)');
    await nestOptions.register(eth.address, {
        channelId: 0,
        pairIndex: 1,
        
        sigmaSQ: 45659142400n,
        miuLong: 64051194700n,
        miuShort: 0n
    });

    console.log('8. nestOptions.register(hbtc.address)');
    await nestOptions.register(hbtc.address, {
        channelId: 0,
        pairIndex: 0,
        
        sigmaSQ: 31708924900n,
        miuLong: 64051194700n,
        miuShort: 0n
    });
    
    // 3.4. Register ETH and HBTC
    console.log('9. nestFutures.register(eth.address)');
    await nestFutures.register(eth.address, {
        channelId: 0,
        pairIndex: 1,
        
        sigmaSQ: 45659142400n,
        miuLong: 64051194700n,
        miuShort: 0n
    });
    console.log('10. nestFutures.register(hbtc.address)');
    await nestFutures.register(hbtc.address, {
        channelId: 0,
        pairIndex: 0,
        
        sigmaSQ: 31708924900n,
        miuLong: 64051194700n,
        miuShort: 0n
    });

    console.log('8.2 create lever');
    
    // 3.5. Register levels for ETH
    console.log('13. create eth long lever');
    await nestFutures.create(eth.address, [1, 2, 3, 4, 5], true);
    console.log('14. create eth short lever');
    await nestFutures.create(eth.address, [1, 2, 3, 4, 5], false);
    
    // 3.5. Register levels for HBTC
    console.log('13. create hbtc long lever');
    await nestFutures.create(hbtc.address, [1, 2, 3, 4, 5], true);
    console.log('14. create hbtc short lever');
    await nestFutures.create(hbtc.address, [1, 2, 3, 4, 5], false);

    // await nestVault.approve(nestOptions.address, 100000000000000000000000000n);
    // await nestVault.approve(nestFutures.address, 100000000000000000000000000n);
    // await nestVault.approve(nestProbability.address, 100000000000000000000000000n);

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