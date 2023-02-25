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
    const NestLPGuarantee = await ethers.getContractFactory('NestLPGuarantee');
    const NestProbability = await ethers.getContractFactory('NestProbability');
    const NestPRCSwap = await ethers.getContractFactory('NestPRCSwap');
    const NestBuybackPool = await ethers.getContractFactory('NestBuybackPool');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');

    console.log('** Deploy: bsc_test@20220709.js **');
    
    // ** Deploy: bsc_test@20220709.js **
    // dcu: 0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // nestPriceFacade: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestOptions: 0x8bBd5db40F61C628a8F62ba75752227b1BFbF6a8
    // nestFutures: 0xb8B5b3CDdC5DA7F4B75Bd4B408389b923962ee98
    // nestLPGuarantee: 0x2a3f6b9E3e4259807b6c98ca7A87da19444cd76E
    // nestProbability: 0xb32e10a774428d47c016eeAc680793a79F1CFD7e
    // nestPRCSwap: 0xd65B764cA768B524753435DC0D30C2D0dCA12C5c
    // nestBuybackPool: 0xB82c97436C3ae453cd21Ef68Ec6900D2e0380Bcd
    // cofixRouter: 0x4A448cBb12e449D7031f36C8122eCE6dDdf9cc84
    // proxyAdmin: 0xB5604C3C3AE902513731037B9c7368842582642e

    const dcu = await TestERC20.attach('0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb');
    console.log('dcu: ' + dcu.address);

    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc');
    console.log('usdt: ' + usdt.address);

    //const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    const nestPriceFacade = await NestPriceFacade.attach('0xF2f9E62f52389EF223f5Fa8b9926e95386935277');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x5691dc0770D55B9469a3242DA282754687687935');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestVault = await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0x0649A02C15229Cb970CDcE456f9dd52248023520');
    console.log('nestVault: ' + nestVault.address);

    //const nestOptions = await upgrades.deployProxy(NestOptions, [nestGovernance.address], { initializer: 'initialize' });
    const nestOptions = await NestOptions.attach('0x8bBd5db40F61C628a8F62ba75752227b1BFbF6a8');
    console.log('nestOptions: ' + nestOptions.address);

    //const nestFutures = await upgrades.deployProxy(NestFutures, [nestGovernance.address], { initializer: 'initialize' });
    const nestFutures = await NestFutures.attach('0xb8B5b3CDdC5DA7F4B75Bd4B408389b923962ee98');
    console.log('nestFutures: ' + nestFutures.address);

    //const nestLPGuarantee = await upgrades.deployProxy(NestLPGuarantee, [nestGovernance.address], { initializer: 'initialize' });
    const nestLPGuarantee = await NestLPGuarantee.attach('0x2a3f6b9E3e4259807b6c98ca7A87da19444cd76E');
    console.log('nestLPGuarantee: ' + nestLPGuarantee.address);

    //const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    const nestProbability = await NestProbability.attach('0xb32e10a774428d47c016eeAc680793a79F1CFD7e');
    console.log('nestProbability: ' + nestProbability.address);

    //const nestPRCSwap = await upgrades.deployProxy(NestPRCSwap, [nestGovernance.address], { initializer: 'initialize' });
    const nestPRCSwap = await NestPRCSwap.attach('0xd65B764cA768B524753435DC0D30C2D0dCA12C5c');
    console.log('nestPRCSwap: ' + nestPRCSwap.address);

    //const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    const nestBuybackPool = await NestBuybackPool.attach('0xB82c97436C3ae453cd21Ef68Ec6900D2e0380Bcd');
    console.log('nestBuybackPool: ' + nestBuybackPool.address);

    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [nestGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0x4A448cBb12e449D7031f36C8122eCE6dDdf9cc84');
    console.log('cofixRouter: ' + cofixRouter.address);

    // await nestGovernance.registerAddress('nest.v4.openPrice', nestPriceFacade.address);
    // await nestGovernance.registerAddress('nest.app.vault', nestVault.address);
    // await nestGovernance.registerAddress('nest.app.dcu', dcu.address);
    // await nestGovernance.registerAddress('nest.app.prc', nestProbability.address);
    // await nestGovernance.registerAddress('cofix.cofixRouter', cofixRouter.address);

    // console.log('4. nestVault.update()');
    // await nestVault.update(nestGovernance.address);
    // console.log('5. nestOptions.update()');
    // await nestOptions.update(nestGovernance.address);
    // console.log('6. nestFutures.update()');
    // await nestFutures.update(nestGovernance.address);
    // console.log('7.2. nestLPGuarantee.update()');
    // await nestLPGuarantee.update(nestGovernance.address);
    // console.log('8. nestProbability.update()');
    // await nestProbability.update(nestGovernance.address);
    // console.log('8. nestBuybackPool.update()');
    // await nestBuybackPool.update(nestGovernance.address);
    // console.log('9. nestPRCSwap.update()');
    // await nestPRCSwap.update(nestGovernance.address);

    // // 2.4. Register ETH ans HBTC
    // console.log('7. nestOptions.register(eth.address)');
    // await nestOptions.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });

    // console.log('8. nestOptions.register(hbtc.address)');
    // await nestOptions.register(hbtc.address, {
    //     channelId: 0,
    //     pairIndex: 2,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });
    
    // // 3.4. Register ETH and HBTC
    // console.log('9. nestFutures.register(eth.address)');
    // await nestFutures.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });
    // console.log('10. nestFutures.register(hbtc.address)');
    // await nestFutures.register(hbtc.address, {
    //     channelId: 0,
    //     pairIndex: 2,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });

    // await nestLPGuarantee.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
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

    // await cofixRouter.registerPair(nestProbability.address, nest.address, nestPRCSwap.address);
    // await cofixRouter.registerPair(dcu.address, nest.address, nestBuybackPool.address);

    // await nestVault.approve(nestOptions.address, 100000000000000000000000000n);
    // await nestVault.approve(nestFutures.address, 100000000000000000000000000n);
    // await nestVault.approve(nestLPGuarantee.address, 100000000000000000000000000n);
    // await nestVault.approve(nestProbability.address, 100000000000000000000000000n);

    //await nest.transfer(nestBuybackPool.address, 10000000000000000000000n);
    // await nest.transfer(nestVault.address, 100000000000000000000000000n);
    // await nest.approve(nestOptions.address, 100000000000000000000000000n);
    // await nest.approve(nestFutures.address, 100000000000000000000000000n);
    // await nest.approve(nestLPGuarantee.address, 100000000000000000000000000n);
    // await dcu.approve(cofixRouter.address, 100000000000000000000000000n);
    //await nest.approve(cofixRouter.address, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        usdt: usdt,
        hbtc: hbtc,
        dcu: dcu,
        nest: nest,

        nestGovernance: nestGovernance,
        nestOptions: nestOptions,
        nestFutures: nestFutures,
        nestLPGuarantee: nestLPGuarantee,
        nestProbability: nestProbability,
        nestPRCSwap: nestPRCSwap,
        nestPriceFacade: nestPriceFacade,
        nestBuybackPool: nestBuybackPool,
        cofixRouter: cofixRouter,

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