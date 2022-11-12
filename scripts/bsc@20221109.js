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
    const NestFuturesWithPrice = await ethers.getContractFactory('NestFuturesWithPrice');
    const NestCyberInk = await ethers.getContractFactory('NestCyberInk');
    const NestNFTAuction = await ethers.getContractFactory('NestNFTAuction');
    const NestMarket = await ethers.getContractFactory('NestMarket');

    console.log('** Deploy: bsc@20221109.js **');

    // PETH: 0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB
    // NEST: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // PBTC: 0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b
    // PUSD: 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2
    // PETH&NEST&PBTC|PUSD

    // ** Deploy: bsc@20221109.js **
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
    // nestCyberInk: 0xCBB79049675F06AFF618CFEB74c2B0Bf411E064a
    // proxyAdmin: 0x42557CAc22ED9933b5E91c8a285167586153A0EB
    // nestNFTAuction: 0x84DC9B49b09d2eB07Cb2D78D2F11bA5b04CeaDf3
    // nestMarket: 0x8b2bc5A2B20acd6a2A71E1dc8D78F6964C65a472

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

    //const nestCyberInk = await upgrades.deployProxy(NestCyberInk, [nestGovernance.address], { initializer: 'initialize' });
    const nestCyberInk = await NestCyberInk.attach('0xCBB79049675F06AFF618CFEB74c2B0Bf411E064a');
    console.log('nestCyberInk: ' + nestCyberInk.address);

    //const nestNFTAuction = await upgrades.deployProxy(NestNFTAuction, [nestGovernance.address], { initializer: 'initialize' });
    const nestNFTAuction = await NestNFTAuction.attach('0x84DC9B49b09d2eB07Cb2D78D2F11bA5b04CeaDf3');
    console.log('nestNFTAuction: ' + nestNFTAuction.address);

    //const nestMarket = await upgrades.deployProxy(NestMarket, [nestGovernance.address], { initializer: 'initialize' });
    const nestMarket = await NestMarket.attach('0x8b2bc5A2B20acd6a2A71E1dc8D78F6964C65a472');
    console.log('nestMarket: ' + nestMarket.address);

    // // Release to element address
    // console.log('Release to element, 150|75|15');
    // await nestCyberInk.safeRelease('0x573b88376e044603e0876E446d63d9047441A446', ((10000 + 0  ) << 8) | 0x0a, 256, 150);
    // await nestCyberInk.safeRelease('0x94A5CE1B502Adc36b8A44B8d6Cd6fC6fDd30Ac6F', ((10000 + 0  ) << 8) | 0x05, 256, 75);
    // await nestCyberInk.safeRelease('0x13C31CA2D073C5E46FF3dc585A2ca944C6772Cc0', ((10000 + 0  ) << 8) | 0x01, 256, 15);

    // // Release to pearDAO address
    // console.log('Release to pearDAO, 150|75|15');
    // await nestCyberInk.safeRelease('0x3b267A908E7DeC6F2e637054Fa1623BCe473E6f6', ((10000 + 150) << 8) | 0x0a, 256, 150);
    // await nestCyberInk.safeRelease('0xCFa2F81885F15F1Ea6EE0aa4CE03c9D630Aecb29', ((10000 + 75 ) << 8) | 0x05, 256, 75);
    // await nestCyberInk.safeRelease('0x51Cc035Dd1B00131eebd142DA9f734eE88183F1c', ((10000 + 15 ) << 8) | 0x01, 256, 15);

    // Release to nestMarket address
    //console.log('Release to nestMarket, 151|150|51');
    //await nestCyberInk.release(nestMarket.address, ((10000 + 300) << 8) | 0x0a, 256, 151);
    //await nestCyberInk.release(nestMarket.address, ((10000 + 150) << 8) | 0x05, 256, 150);
    //await nestCyberInk.release(nestMarket.address, ((10000 + 30 ) << 8) | 0x01, 256, 51);
        
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
        nestMarket: nestMarket,

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