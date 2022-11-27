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
    const NestFuturesWithPrice = await ethers.getContractFactory('NestFuturesWithPrice');
    const NestMarket = await ethers.getContractFactory('NestMarket');
    const NestPVM = await ethers.getContractFactory('NestPVM');

    console.log('** Deploy: bsc_test@20221127.js **');
    
    // ** Deploy: bsc_test@20221127.js **
    // dcu: 0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // nestPriceFacade: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestOptions: 0x8bBd5db40F61C628a8F62ba75752227b1BFbF6a8
    // nestFutures: 0xb8B5b3CDdC5DA7F4B75Bd4B408389b923962ee98
    // nestFuturesWithPrice: 0xA2D58989ef9981065f749C217984DB21970fF0b7
    // nestProbability: 0x9AeE80A1df3cA0c5B859d94bCCf16d0440f1691d
    // nestBuybackPool: 0xB82c97436C3ae453cd21Ef68Ec6900D2e0380Bcd
    // nestCyberInk: 0x0b933B3a74ADd67e0690f7962e2AbbE975048326
    // nestNFTAuction: 0xF61Dd2B661184FAE507475d03ED561593f1882d4
    // nestMarket: 0xd435489F3BB3b6004230b67bb122bac22419Fdfd
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A
    // nestPVM: 0x3f42A4Ba6bdcCD025B5BEb2598d3a9993635dA38

    // const dcu = await TestERC20.attach('0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb');
    // console.log('dcu: ' + dcu.address);

    // const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    // console.log('hbtc: ' + hbtc.address);

    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);

    // //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    // const usdt = await TestERC20.attach('0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc');
    // console.log('usdt: ' + usdt.address);

    // //const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    // const nestPriceFacade = await NestPriceFacade.attach('0xF2f9E62f52389EF223f5Fa8b9926e95386935277');
    // console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x5691dc0770D55B9469a3242DA282754687687935');
    console.log('nestGovernance: ' + nestGovernance.address);

    // //const nestVault = await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    // const nestVault = await NestVault.attach('0x0649A02C15229Cb970CDcE456f9dd52248023520');
    // console.log('nestVault: ' + nestVault.address);

    // //const nestOptions = await upgrades.deployProxy(NestOptions, [nestGovernance.address], { initializer: 'initialize' });
    // const nestOptions = await NestOptions.attach('0x8bBd5db40F61C628a8F62ba75752227b1BFbF6a8');
    // console.log('nestOptions: ' + nestOptions.address);

    // //const nestFutures = await upgrades.deployProxy(NestFutures, [nestGovernance.address], { initializer: 'initialize' });
    // const nestFutures = await NestFutures.attach('0xb8B5b3CDdC5DA7F4B75Bd4B408389b923962ee98');
    // console.log('nestFutures: ' + nestFutures.address);

    //const nestFuturesWithPrice = await upgrades.deployProxy(NestFuturesWithPrice, [nestGovernance.address], { initializer: 'initialize' });
    const nestFuturesWithPrice = await NestFuturesWithPrice.attach('0xA2D58989ef9981065f749C217984DB21970fF0b7');
    console.log('nestFuturesWithPrice: ' + nestFuturesWithPrice.address);

    // //const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    // const nestProbability = await NestProbability.attach('0x9AeE80A1df3cA0c5B859d94bCCf16d0440f1691d');
    // console.log('nestProbability: ' + nestProbability.address);

    // //const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    // const nestBuybackPool = await NestBuybackPool.attach('0xB82c97436C3ae453cd21Ef68Ec6900D2e0380Bcd');
    // console.log('nestBuybackPool: ' + nestBuybackPool.address);

    // //const nestCyberInk = await upgrades.deployProxy(NestCyberInk, [nestGovernance.address], { initializer: 'initialize' });
    // const nestCyberInk = await NestCyberInk.attach('0x0b933B3a74ADd67e0690f7962e2AbbE975048326');
    // console.log('nestCyberInk: ' + nestCyberInk.address);

    // //const nestNFTAuction = await upgrades.deployProxy(NestNFTAuction, [nestGovernance.address], { initializer: 'initialize' });
    // const nestNFTAuction = await NestNFTAuction.attach('0xF61Dd2B661184FAE507475d03ED561593f1882d4');
    // console.log('nestNFTAuction: ' + nestNFTAuction.address);

    // //const nestMarket = await upgrades.deployProxy(NestMarket, [nestGovernance.address], { initializer: 'initialize' });
    // const nestMarket = await NestMarket.attach('0xd435489F3BB3b6004230b67bb122bac22419Fdfd');
    // console.log('nestMarket: ' + nestMarket.address);

    //const nestPVM = await upgrades.deployProxy(NestPVM, [nestGovernance.address], { initializer: 'initialize' });
    const nestPVM = await NestPVM.attach('0x3f42A4Ba6bdcCD025B5BEb2598d3a9993635dA38');
    console.log('nestPVM: ' + nestPVM.address);

    // //await nestPVM.update(nestGovernance.address);
    // await nestPVM.setNestFutures(nestFuturesWithPrice.address);

    // await nestPVM.register('PI', 3141592653590000000n | (1n << 248n));
    // await nestPVM.register('E',  2718281828459000000n | (1n << 248n));
    // await nestPVM.registerAddress('P0', nestPVM.address);
    // await nestPVM.registerAddress('P1', nestPVM.address);
    // await nestPVM.registerAddress('P2', nestPVM.address);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        // usdt: usdt,
        // hbtc: hbtc,
        // dcu: dcu,
        nest: nest,

        nestGovernance: nestGovernance,
        // nestOptions: nestOptions,
        // nestFutures: nestFutures,
        // nestProbability: nestProbability,
        // nestPriceFacade: nestPriceFacade,
        // nestBuybackPool: nestBuybackPool,
        // nestCyberInk: nestCyberInk,
        // nestNFTAuction: nestNFTAuction,
        // nestFuturesWithPrice: nestFuturesWithPrice,
        // nestNFTAuction: nestNFTAuction,
        // nestMarket: nestMarket,
        nestPVM: nestPVM,

        BLOCK_TIME: BLOCK_TIME,
        USDT_DECIMALS: 18,

        MIU_LONG: MIU_LONG,
        MIU_SHORT: MIU_SHORT,
        miuT: function(orientation, blocks) {
            return Math.exp((orientation ? MIU_LONG : MIU_SHORT) * blocks * BLOCK_TIME);
        }
    };

/*
    // ** Deploy: bsc_test@20221127.js **
    // dcu: 0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // nestPriceFacade: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestOptions: 0x8bBd5db40F61C628a8F62ba75752227b1BFbF6a8
    // nestFutures: 0xb8B5b3CDdC5DA7F4B75Bd4B408389b923962ee98
    // nestFuturesWithPrice: 0xA2D58989ef9981065f749C217984DB21970fF0b7
    // nestProbability: 0x9AeE80A1df3cA0c5B859d94bCCf16d0440f1691d
    // nestBuybackPool: 0xB82c97436C3ae453cd21Ef68Ec6900D2e0380Bcd
    // nestCyberInk: 0x0b933B3a74ADd67e0690f7962e2AbbE975048326
    // nestNFTAuction: 0xF61Dd2B661184FAE507475d03ED561593f1882d4
    // nestMarket: 0xd435489F3BB3b6004230b67bb122bac22419Fdfd
    // nestPVM: 0x3f42A4Ba6bdcCD025B5BEb2598d3a9993635dA38

    已经在bsc测试网上部署了PVM的demo版本，可以通过表达式定制产品，主要有以下四个接口
    1. estimate(string memory expr). 计算产品表达式的价值，expr为表达式，表达式语法见末尾的表达式说明
    2. buy(string memory expr). 买入expr表示的产品，记录为订单，可以通过list接口查询
    3. sell(uint index). 卖出指定编号的订单
    4. list(uint offset, uint count, uint order). 查找买入的订单

    表达式说明：
    1. 表达式支持加（+）减（-）乘（*）除（/）以及指数运算（**）
    2. 表达式优先级 + -，* /，** 三个级别，
    3. 支持括号表达式，可以用括号改变计算优先级
    4. 支持字面值数字（可带小数点），计算过程中数字用18位小数表示，最多允许18位小数
    5. 不支持负数字面常量，如需负数，请用（0-47）这样的表达式
    6. 支持标识符，标识符以字母开头（区分大小写），后面可以跟字母或数字，最长31个字符
    7. 支持内置常量PI（3.14159265359)和E（2718281828459）
    8. 支持价格变量P0（ETH），P1（NEST），P2（BTC）的价格，价格是从nestFuturesWithPrice（0xA2D58989ef9981065f749C217984DB21970fF0b7）合约取的最新价格，是参考2000USD的价格
    9. 表达式中所有字符必须是英文半角字符
    10. 表达式中各部分之间允许空格
    11. 表达式计算结果为18位小数表示
    
    表达式实例：P1 ** 0.5 + PI * (E+ 9527)
*/

    return contracts;
};