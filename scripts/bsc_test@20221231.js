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
    const NestCyberInk = await ethers.getContractFactory('NestCyberInk');
    const NestNFTAuction = await ethers.getContractFactory('NestNFTAuction');
    const NestFutures2 = await ethers.getContractFactory('NestFutures2');
    const NestMarket = await ethers.getContractFactory('NestMarket');
    const NestFuturesProxy = await ethers.getContractFactory('NestFuturesProxy');
    const NestRedeem = await ethers.getContractFactory('NestRedeem');

    console.log('** Deploy: bsc_test@20221231.js **');
    
    // ** Deploy: bsc_test@20221231.js **
    // dcu: 0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // nestPriceFacade: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestOptions: 0x8bBd5db40F61C628a8F62ba75752227b1BFbF6a8
    // nestFutures: 0xb8B5b3CDdC5DA7F4B75Bd4B408389b923962ee98
    // nestProbability: 0x9AeE80A1df3cA0c5B859d94bCCf16d0440f1691d
    // nestBuybackPool: 0xB82c97436C3ae453cd21Ef68Ec6900D2e0380Bcd
    // nestCyberInk: 0x0b933B3a74ADd67e0690f7962e2AbbE975048326
    // nestNFTAuction: 0xF61Dd2B661184FAE507475d03ED561593f1882d4
    // nestMarket: 0xd435489F3BB3b6004230b67bb122bac22419Fdfd
    // nestFutures2: 0xA2D58989ef9981065f749C217984DB21970fF0b7
    // nestFuturesProxy: 0xd6C4BE39748510BB5b8B2eF0b0aF71B860691bcb
    // nhbtc: 0xDda3801487a8Bb5ec19dD1E3510b6340BA435863
    // nestRedeem: 0x6E9c1edACe6Fc03f9666769f09D557b1383f7F57
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

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

    //const nestFutures2 = await upgrades.deployProxy(NestFutures2, [nestGovernance.address], { initializer: 'initialize' });
    const nestFutures2 = await NestFutures2.attach('0xA2D58989ef9981065f749C217984DB21970fF0b7');
    console.log('nestFutures2: ' + nestFutures2.address);

    //const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    const nestProbability = await NestProbability.attach('0x9AeE80A1df3cA0c5B859d94bCCf16d0440f1691d');
    console.log('nestProbability: ' + nestProbability.address);

    //const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    const nestBuybackPool = await NestBuybackPool.attach('0xB82c97436C3ae453cd21Ef68Ec6900D2e0380Bcd');
    console.log('nestBuybackPool: ' + nestBuybackPool.address);

    //const nestCyberInk = await upgrades.deployProxy(NestCyberInk, [nestGovernance.address], { initializer: 'initialize' });
    const nestCyberInk = await NestCyberInk.attach('0x0b933B3a74ADd67e0690f7962e2AbbE975048326');
    console.log('nestCyberInk: ' + nestCyberInk.address);

    //const nestNFTAuction = await upgrades.deployProxy(NestNFTAuction, [nestGovernance.address], { initializer: 'initialize' });
    const nestNFTAuction = await NestNFTAuction.attach('0xF61Dd2B661184FAE507475d03ED561593f1882d4');
    console.log('nestNFTAuction: ' + nestNFTAuction.address);

    //const nestMarket = await upgrades.deployProxy(NestMarket, [nestGovernance.address], { initializer: 'initialize' });
    const nestMarket = await NestMarket.attach('0xd435489F3BB3b6004230b67bb122bac22419Fdfd');
    console.log('nestMarket: ' + nestMarket.address);

    //const nestFuturesProxy = await upgrades.deployProxy(NestFuturesProxy, [nestGovernance.address], { initializer: 'initialize' });
    const nestFuturesProxy = await NestFuturesProxy.attach('0xd6C4BE39748510BB5b8B2eF0b0aF71B860691bcb');
    console.log('nestFuturesProxy: ' + nestFuturesProxy.address);

    //const nhbtc = await TestERC20.deploy('NHBTC', 'NHBTC', 18);
    const nhbtc = await TestERC20.attach('0xDda3801487a8Bb5ec19dD1E3510b6340BA435863');
    console.log('nhbtc: ' + nhbtc.address);
    //const nestRedeem = await NestRedeem.deploy(nhbtc.address, nest.address, 500000000000000000n);
    const nestRedeem = await NestRedeem.attach('0x6E9c1edACe6Fc03f9666769f09D557b1383f7F57');
    console.log('nestRedeem: ' + nestRedeem.address);

    //await nestRedeem.initialize(nestGovernance.address);

    // await nestGovernance.registerAddress('nest.v4.openPrice', nestPriceFacade.address);
    // await nestGovernance.registerAddress('nest.app.vault', nestVault.address);
    // await nestGovernance.registerAddress('nest.app.dcu', dcu.address);
    // await nestGovernance.registerAddress('nest.app.prc', nestProbability.address);
    // await nestGovernance.registerAddress('nest.app.cyberink', nestCyberInk.address);
    //await nestGovernance.registerAddress('nest.app.maintains', '0xd9f3aa57576a6da995fb4b7e7272b4f16f04e681');
    //await nestGovernance.registerAddress('nest.app.futures', nestFutures2.address);
    //await nestGovernance.registerAddress('nest.app.futuresProxy', nestFuturesProxy.address);

    // console.log('9. nestCyberInk.update()');
    // await nestCyberInk.update(nestGovernance.address);

    // console.log('10. nestNFTAuction.update()');
    // await nestNFTAuction.update(nestGovernance.address);
    // console.log('11. nestMarket.update()');
    // await nestMarket.update(nestGovernance.address);

    //const newNestFutures2 = await NestFutures2.deploy({ nonce: 1235 });
    //console.log('newNestFutures2: ' + newNestFutures2.address);

    //await nestGovernance.registerAddress('nest.app.directPoster', '0xd9f3aa57576a6da995fb4b7e7272b4f16f04e681');
    // let dp = await nestGovernance.checkAddress('nest.app.directPoster');
    // console.log('dp: ' + dp);

    // let mt = await nestGovernance.checkAddress('nest.app.maintains');
    // console.log('mt: ' + mt);

    // await nestFutures2.update(nestGovernance.address);

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
        nestProbability: nestProbability,
        nestPriceFacade: nestPriceFacade,
        nestBuybackPool: nestBuybackPool,
        nestCyberInk: nestCyberInk,
        nestNFTAuction: nestNFTAuction,
        nestFutures2: nestFutures2,
        nestFuturesProxy: nestFuturesProxy,
        nestNFTAuction: nestNFTAuction,
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