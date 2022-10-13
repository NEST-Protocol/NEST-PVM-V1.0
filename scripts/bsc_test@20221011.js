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
    const NestBlindBox = await ethers.getContractFactory('NestBlindBox');
    const NestNFTAuction = await ethers.getContractFactory('NestNFTAuction');
    const NestFuturesWithPrice = await ethers.getContractFactory('NestFuturesWithPrice');

    console.log('** Deploy: bsc_test@20221011.js **');
    
    // ** Deploy: bsc_test@20220711.js **
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
    // cofixRouter: 0x4A448cBb12e449D7031f36C8122eCE6dDdf9cc84
    // proxyAdmin: 0xB5604C3C3AE902513731037B9c7368842582642e
    // nestBlindBox: 0xEED27D6CBf6F013dd861F4D7C08fce84a7ae08F5
    // nestNFTAuction: 0x48aDA25925ee3FC6961A3bFFe197E568bAf5f703
    // nestFuturesWithPrice: 0xA2D58989ef9981065f749C217984DB21970fF0b7
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

    //const nestFuturesWithPrice = await upgrades.deployProxy(NestFuturesWithPrice, [nestGovernance.address], { initializer: 'initialize' });
    const nestFuturesWithPrice = await NestFuturesWithPrice.attach('0xA2D58989ef9981065f749C217984DB21970fF0b7');
    console.log('nestFuturesWithPrice: ' + nestFuturesWithPrice.address);

    //const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    const nestProbability = await NestProbability.attach('0x9AeE80A1df3cA0c5B859d94bCCf16d0440f1691d');
    console.log('nestProbability: ' + nestProbability.address);

    //const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    const nestBuybackPool = await NestBuybackPool.attach('0xB82c97436C3ae453cd21Ef68Ec6900D2e0380Bcd');
    console.log('nestBuybackPool: ' + nestBuybackPool.address);

    //const nestBlindBox = await NestBlindBox.deploy();
    const nestBlindBox = await NestBlindBox.attach('0xEED27D6CBf6F013dd861F4D7C08fce84a7ae08F5');
    console.log('nestBlindBox: ' + nestBlindBox.address);

    // const nestNFTAuction = await NestNFTAuction.deploy();
    const nestNFTAuction = await NestNFTAuction.attach('0x48aDA25925ee3FC6961A3bFFe197E568bAf5f703');
    console.log('nestNFTAuction: ' + nestNFTAuction.address);

    // console.log('7. nestFuturesWithPrice.update()');
    // await nestFuturesWithPrice.update(nestGovernance.address);

    // // 3.4. Register ETH and HBTC
    // console.log('9. nestFuturesWithPrice.register(eth.address)');
    // await nestFuturesWithPrice.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });
    // console.log('10. nestFuturesWithPrice.register(hbtc.address)');
    // await nestFuturesWithPrice.register(hbtc.address, {
    //     channelId: 0,
    //     pairIndex: 2,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });

    // // 3.5. Register levels for ETH
    // console.log('13. create eth long lever');
    // await nestFuturesWithPrice.create(eth.address, [1, 2, 3, 4, 5], true);
    // console.log('14. create eth short lever');
    // await nestFuturesWithPrice.create(eth.address, [1, 2, 3, 4, 5], false);
    
    // // 3.5. Register levels for HBTC
    // console.log('13. create hbtc long lever');
    // await nestFuturesWithPrice.create(hbtc.address, [1, 2, 3, 4, 5], true);
    // console.log('14. create hbtc short lever');
    // await nestFuturesWithPrice.create(hbtc.address, [1, 2, 3, 4, 5], false);

    // await nestVault.approve(nestFuturesWithPrice.address, 100000000000000000000000000n);
    // await nest.approve(nestFuturesWithPrice.address, 100000000000000000000000000n);

    // const newNestFuturesWithPrice = await NestFuturesWithPrice.deploy();
    // console.log('newNestFuturesWithPrice: ' + newNestFuturesWithPrice.address);

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
        nestBlindBox: nestBlindBox,
        nestNFTAuction: nestNFTAuction,
        nestFuturesWithPrice: nestFuturesWithPrice,

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