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

    console.log('** Deploy: bsc@20220729.js **');

    // PETH: 0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB
    // NEST: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // PBTC: 0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b
    // PUSD: 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2
    // PETH&NEST&PBTC|PUSD

    // ** Deploy: bsc@20220729.js **
    // nestVault: 0x65e7506244CDdeFc56cD43dC711470F8B0C43beE
    // pusd: 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2
    // pbtc: 0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // nest: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // nestPriceFacade: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
    // nestGovernance: 0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb
    // nestOptions: 0x12858F7f24AA830EeAdab2437480277E92B0723a
    // nestFutures: 0x8e32C33814271bD64D5138bE9d47Cd55025074CD
    // nestProbability: 0xCA52f25f37d213CeD3dDE81a539e64464dEa8f3C
    // nestBuybackPool: 0x8AA36CF9CD7e88b63F32c53C66BFaDd409367B2f
    // proxyAdmin: 0x42557CAc22ED9933b5E91c8a285167586153A0EB

    //const nestVault = await NestVault.deploy(); //await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0x65e7506244CDdeFc56cD43dC711470F8B0C43beE');
    console.log('nestVault: ' + nestVault.address);

    const pusd = await TestERC20.attach('0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2');
    console.log('pusd: ' + pusd.address);

    const pbtc = await TestERC20.attach('0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b');
    console.log('pbtc: ' + pbtc.address);

    //const dcu = await TestERC20.deploy('DCU', 'DCU', 18);
    const dcu = await TestERC20.attach('0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF');
    console.log('dcu: ' + dcu.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7');
    console.log('nest: ' + nest.address);

    //const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    const nestPriceFacade = await NestPriceFacade.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestOptions = await upgrades.deployProxy(NestOptions, [nestGovernance.address], { initializer: 'initialize' });
    const nestOptions = await NestOptions.attach('0x12858F7f24AA830EeAdab2437480277E92B0723a');
    console.log('nestOptions: ' + nestOptions.address);

    //const nestFutures = await upgrades.deployProxy(NestFutures, [nestGovernance.address], { initializer: 'initialize' });
    const nestFutures = await NestFutures.attach('0x8e32C33814271bD64D5138bE9d47Cd55025074CD');
    console.log('nestFutures: ' + nestFutures.address);

    //const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    const nestProbability = await NestProbability.attach('0xCA52f25f37d213CeD3dDE81a539e64464dEa8f3C');
    console.log('nestProbability: ' + nestProbability.address);
    
    //const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    const nestBuybackPool = await NestBuybackPool.attach('0x8AA36CF9CD7e88b63F32c53C66BFaDd409367B2f');
    console.log('nestBuybackPool: ' + nestBuybackPool.address);

    // // 2.4. Register ETH ans PBTC
    // console.log('7. nestOptions.register(eth.address)');
    // await nestOptions.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });

    // console.log('8. nestOptions.register(pbtc.address)');
    // await nestOptions.register(pbtc.address, {
    //     channelId: 0,
    //     pairIndex: 2,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });
    
    // // 3.4. Register ETH and PBTC
    // console.log('9. nestFutures.register(eth.address)');
    // await nestFutures.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });
    // console.log('10. nestFutures.register(pbtc.address)');
    // await nestFutures.register(pbtc.address, {
    //     channelId: 0,
    //     pairIndex: 2,
        
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
    
    // // 3.5. Register levels for PBTC
    // console.log('13. create pbtc long lever');
    // await nestFutures.create(pbtc.address, [1, 2, 3, 4, 5], true);
    // console.log('14. create pbtc short lever');
    // await nestFutures.create(pbtc.address, [1, 2, 3, 4, 5], false);

    // await nestVault.approve(nestOptions.address, 100000000000000000000000000n);
    // await nestVault.approve(nestFutures.address, 100000000000000000000000000n);
    // await nestVault.approve(nestProbability.address, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        pusd: pusd,
        pbtc: pbtc,
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