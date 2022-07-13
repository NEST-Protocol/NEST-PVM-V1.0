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
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');

    console.log('** Deploy: rinkeby@20220712.js **');
    
    // ** Deploy: rinkeby@20220712.js **
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // dcu: 0xc408edF487e98bB932eD4A8983038FF19352eDbd
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0xc08E6A853241B9a08225EECf93F3b279FA7A1bE7
    // nestGovernance: 0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7
    // nestVault: 0xF0FF3D61cd7ECffe4529573Ec22E98c8E5F39EA1
    // nestOptions: 0x57dffD238fFe2b4cDEE9460D52F71b804E96AfA7
    // nestFutures: 0x56a07c76f6F91a97851013BF23ED8590070B656E
    // nestProbability: 0xF53C8f2E5c3c4DfFD2793785f54B90C8D47c1B98
    // nestBuybackPool: 0x39F0889254Cb5a87075CB0147053cc2301061b9c
    // cofixRouter: 0x9f7997EFb0aF6f5e370dea99b1941D73330825C9
    // proxyAdmin: 0xc1Bf75A3083e3202f86Fb83F32cEecaC5D559Ef9
    // HBTC&ETH&NEST|PUSD@2000

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    //const dcu = await TestERC20.deploy('DCU', 'DCU', 18);
    const dcu = await TestERC20.attach('0xc408edF487e98bB932eD4A8983038FF19352eDbd');
    console.log('dcu: ' + dcu.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25');
    console.log('nest: ' + nest.address);

    //const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    const nestPriceFacade = await NestPriceFacade.attach('0xc08E6A853241B9a08225EECf93F3b279FA7A1bE7');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestVault = await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0xF0FF3D61cd7ECffe4529573Ec22E98c8E5F39EA1');
    console.log('nestVault: ' + nestVault.address);

    //const nestOptions = await upgrades.deployProxy(NestOptions, [nestGovernance.address], { initializer: 'initialize' });
    const nestOptions = await NestOptions.attach('0x57dffD238fFe2b4cDEE9460D52F71b804E96AfA7');
    console.log('nestOptions: ' + nestOptions.address);

    //const nestFutures = await upgrades.deployProxy(NestFutures, [nestGovernance.address], { initializer: 'initialize' });
    const nestFutures = await NestFutures.attach('0x56a07c76f6F91a97851013BF23ED8590070B656E');
    console.log('nestFutures: ' + nestFutures.address);

    //const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    const nestProbability = await NestProbability.attach('0xF53C8f2E5c3c4DfFD2793785f54B90C8D47c1B98');
    console.log('nestProbability: ' + nestProbability.address);
    
    //const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    const nestBuybackPool = await NestBuybackPool.attach('0x39F0889254Cb5a87075CB0147053cc2301061b9c');
    console.log('nestBuybackPool: ' + nestBuybackPool.address);

    //const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [nestGovernance.address], { initializer: 'initialize' });
    const cofixRouter = await CoFiXRouter.attach('0x9f7997EFb0aF6f5e370dea99b1941D73330825C9');
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
    // console.log('8. nestProbability.update()');
    // await nestProbability.update(nestGovernance.address);
    // console.log('8. nestBuybackPool.update()');
    // await nestBuybackPool.update(nestGovernance.address);

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

    // await cofixRouter.registerPair(dcu.address, nest.address, nestBuybackPool.address);

    // await nest.transfer(nestVault.address, 100000000000000000000000n);
    // await nest.approve(nestOptions.address, 100000000000000000000000000n);
    // await nest.approve(nestFutures.address, 100000000000000000000000000n);
    // await nest.approve(nestProbability.address, 100000000000000000000000000n);
    // await nestVault.approve(nestOptions.address, 100000000000000000000000000n);
    // await nestVault.approve(nestFutures.address, 100000000000000000000000000n);
    // await nestVault.approve(nestProbability.address, 100000000000000000000000n);

    //await nest.transfer(nestBuybackPool.address, 100000000000000000000000n);
    await dcu.approve(cofixRouter.address, 100000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        hbtc: hbtc,
        dcu: dcu,
        nest: nest,

        nestGovernance: nestGovernance,
        nestOptions: nestOptions,
        nestFutures: nestFutures,
        nestProbability: nestProbability,
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