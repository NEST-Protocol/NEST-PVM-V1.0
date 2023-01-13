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
    const NestFutures2 = await ethers.getContractFactory('NestFutures2');
    const NestFuturesProxy = await ethers.getContractFactory('NestFuturesProxy');

    console.log('** Deploy: bsc@20230113.js **');

    // PETH: 0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB
    // NEST: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // PBTC: 0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b
    // PUSD: 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2
    // PETH&NEST&PBTC|PUSD

    // ** Deploy: bsc@20230113.js **
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
    // nestFuturesProxy: 0x8b2A11F6C5cEbB00793dCE502a9B08741eDBcb96
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

    // 0. Prepare
    // Resolve all TODO task

    // 1. Deploy nestFuturesProxy with proxy
    //const nestFuturesProxy = await upgrades.deployProxy(NestFuturesProxy, [nestGovernance.address], { initializer: 'initialize' });
    const nestFuturesProxy = await NestFuturesProxy.attach('0x8b2A11F6C5cEbB00793dCE502a9B08741eDBcb96');
    console.log('nestFuturesProxy: ' + nestFuturesProxy.address);

    // 2. Deploy nestFutures2
    // TODO: Make sure nestFutures2.FUTURES_PROXY_ADDRESS set (After nestFuturesProxy deployed)
    // TODO: Make sure nestFutures2.MAINTAINS_ADDRESS set (Ask for wll)
    // const newNestFutures2 = await NestFutures2.deploy();
    // console.log('newNestFutures2: ' + newNestFutures2.address);

    // 3. Verify code on bscscan

    // 4. Upgrade nestFutures2 and check
    // proxyAdmin: 0x42557CAc22ED9933b5E91c8a285167586153A0EB
    // nestFutures2: 0x8e32C33814271bD64D5138bE9d47Cd55025074CD

    // 5. Call nestFutures2.init()

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