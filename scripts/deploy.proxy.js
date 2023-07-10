// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestToken = await ethers.getContractFactory('NestToken');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestVault = await ethers.getContractFactory('NestVault');
    const NestOptions = await ethers.getContractFactory('NestOptions');
    const NestFutures = await ethers.getContractFactory('NestFutures');
    const NestProbability = await ethers.getContractFactory('NestProbability');
    const NestBuybackPool = await ethers.getContractFactory('NestBuybackPool');
    const NestCyberInk = await ethers.getContractFactory('NestCyberInk');
    const NestNFTAuction = await ethers.getContractFactory('NestNFTAuction');
    const NestTrustFuturesV1 = await ethers.getContractFactory('NestTrustFuturesV1');
    const NestTrustFuturesV2 = await ethers.getContractFactory('NestTrustFuturesV2');
    const NestTrustFuturesV3 = await ethers.getContractFactory('NestTrustFuturesV3');
    const NestFutures4V3 = await ethers.getContractFactory('NestFutures4V3');
    const NestFutures4V4 = await ethers.getContractFactory('NestFutures4V4');
    const NestFutures4V5 = await ethers.getContractFactory('NestFutures4V5');
    const NestFutures4V6 = await ethers.getContractFactory('NestFutures4V6');
    const NestMarket = await ethers.getContractFactory('NestMarket');
    const NestFuturesProxy = await ethers.getContractFactory('NestFuturesProxy');
    const PancakeFactory = await ethers.getContractFactory('PancakeFactory');
    const PancakeRouter = await ethers.getContractFactory('PancakeRouter');
    const Gatling = await ethers.getContractFactory('Gatling');

    console.log('** Deploy: deploy.proxy.js **');
    
    const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    //const hbtc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('hbtc: ' + hbtc.address);

    const dcu = await TestERC20.deploy('DCU', 'DCU', 18);
    //const dcu = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('dcu: ' + dcu.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await NestToken.deploy();
    //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);

    const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    //const nestPriceFacade = await NestPriceFacade.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const nestGovernance = await NestGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('nestGovernance: ' + nestGovernance.address);

    const nestVault = await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    //const nestVault = await NestVault.attach('0x0000000000000000000000000000000000000000');
    console.log('nestVault: ' + nestVault.address);

    const nestOptions = await upgrades.deployProxy(NestOptions, [nestGovernance.address], { initializer: 'initialize' });
    //const nestOptions = await NestOptions.attach('0x0000000000000000000000000000000000000000');
    console.log('nestOptions: ' + nestOptions.address);

    const nestFutures = await upgrades.deployProxy(NestFutures, [nestGovernance.address], { initializer: 'initialize' });
    //const nestFutures = await NestFutures.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures: ' + nestFutures.address);

    const nestTrustFuturesV1 = await upgrades.deployProxy(NestTrustFuturesV1, [nestGovernance.address], { initializer: 'initialize' });
    //const nestTrustFuturesV1 = await NestTrustFuturesV1.attach('0x0000000000000000000000000000000000000000');
    console.log('nestTrustFuturesV1: ' + nestTrustFuturesV1.address);

    const nestTrustFuturesV2 = await upgrades.deployProxy(NestTrustFuturesV2, [nestGovernance.address], { initializer: 'initialize' });
    //const nestTrustFuturesV2 = await NestTrustFuturesV2.attach('0x0000000000000000000000000000000000000000');
    console.log('nestTrustFuturesV2: ' + nestTrustFuturesV2.address);

    const nestTrustFuturesV3 = await upgrades.deployProxy(NestTrustFuturesV3, [nestGovernance.address], { initializer: 'initialize' });
    //const nestTrustFuturesV3 = await NestTrustFuturesV3.attach('0x0000000000000000000000000000000000000000');
    console.log('nestTrustFuturesV3: ' + nestTrustFuturesV3.address);

    const nestFutures4V3 = await upgrades.deployProxy(NestFutures4V3, [nestGovernance.address], { initializer: 'initialize' });
    //const nestFutures4V3 = await NestFutures4V3.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures4V3: ' + nestFutures4V3.address);

    const nestFutures4V4 = await upgrades.deployProxy(NestFutures4V4, [nestGovernance.address], { initializer: 'initialize' });
    //const nestFutures4V4 = await NestFutures4V4.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures4V4: ' + nestFutures4V4.address);

    const nestFutures4V5 = await upgrades.deployProxy(NestFutures4V5, [nestGovernance.address], { initializer: 'initialize' });
    //const nestFutures4V5 = await NestFutures4V5.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures4V5: ' + nestFutures4V5.address);

    const nestFutures4V6 = await upgrades.deployProxy(NestFutures4V6, [nestGovernance.address], { initializer: 'initialize' });
    //const nestFutures4V6 = await NestFutures4V6.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures4V6: ' + nestFutures4V6.address);

    const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    //const nestProbability = await NestProbability.attach('0x0000000000000000000000000000000000000000');
    console.log('nestProbability: ' + nestProbability.address);
    
    const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    // const nestBuybackPool = await NestBuybackPool.attach('0x0000000000000000000000000000000000000000');
    console.log('nestBuybackPool: ' + nestBuybackPool.address);

    const nestCyberInk = await upgrades.deployProxy(NestCyberInk, [nestGovernance.address], { initializer: 'initialize' });
    // const nestCyberInk = await NestCyberInk.attach('0x0000000000000000000000000000000000000000');
    console.log('nestCyberInk: ' + nestCyberInk.address);

    const nestNFTAuction = await upgrades.deployProxy(NestNFTAuction, [nestGovernance.address], { initializer: 'initialize' });
    // const nestNFTAuction = await NestNFTAuction.attach('0x0000000000000000000000000000000000000000');
    console.log('nestNFTAuction: ' + nestNFTAuction.address);

    const nestMarket = await upgrades.deployProxy(NestMarket, [nestGovernance.address], { initializer: 'initialize' });
    //const nestMarket = await NestMarket.attach('0x0000000000000000000000000000000000000000');
    console.log('nestMarket: ' + nestMarket.address);

    const nestFuturesProxy = await upgrades.deployProxy(NestFuturesProxy, [nestGovernance.address], { initializer: 'initialize' });
    //const nestFuturesProxy = await NestFuturesProxy.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFuturesProxy: ' + nestFuturesProxy.address);

    const gatling = await Gatling.deploy();
    console.log('gatling: ' + gatling.address);

    // -------- TEST --------
    const pancakeFactory = await PancakeFactory.deploy('0x0000000000000000000000000000000000000000');
    console.log('pancakeFactory: ' + pancakeFactory.address);

    const pancakeRouter = await PancakeRouter.deploy(pancakeFactory.address, '0x0000000000000000000000000000000000000000');
    console.log('pancakeRouter: ' + pancakeRouter.address);

    await pancakeFactory.createPair(usdt.address, nest.address);

    // -------- TEST --------

    console.log('2. nestGovernance.setBuiltinAddress()');
    await nestGovernance.setBuiltinAddress(
        nest.address,
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000'
    );
    await nestGovernance.registerAddress('nest.v4.openPrice', nestPriceFacade.address);
    await nestGovernance.registerAddress('nest.app.vault', nestVault.address);
    await nestGovernance.registerAddress('nest.app.futures', nestTrustFuturesV1.address);
    await nestGovernance.registerAddress('nest.app.futuresProxy', nestFuturesProxy.address);
    await nestGovernance.registerAddress('nest.app.dcu', dcu.address);
    await nestGovernance.registerAddress('nest.app.prc', nestProbability.address);
    await nestGovernance.registerAddress('nest.app.cyberink', nestCyberInk.address);
    await nestGovernance.registerAddress('nest.app.directPoster', (await ethers.getSigners())[0].address)
    await nestGovernance.registerAddress('nest.app.maintains', (await ethers.getSigners())[0].address);
    await nestGovernance.registerAddress('pancake.app.router', pancakeRouter.address);
    await nestGovernance.registerAddress('pancake.pair.nestusdt', await pancakeFactory.getPair(usdt.address, nest.address));
    await nestGovernance.registerAddress('common.token.usdt', usdt.address);

    console.log('4. nestVault.update()');
    await nestVault.update(nestGovernance.address);
    console.log('5. nestOptions.update()');
    await nestOptions.update(nestGovernance.address);
    console.log('6. nestFutures.update()');
    await nestFutures.update(nestGovernance.address);
    console.log('7. nestTrustFuturesV1.update()');
    await nestTrustFuturesV1.update(nestGovernance.address);
    console.log('7. nestTrustFuturesV2.update()');
    await nestTrustFuturesV2.update(nestGovernance.address);
    console.log('7. nestTrustFuturesV3.update()');
    await nestTrustFuturesV3.update(nestGovernance.address);
    console.log('7. nestFutures4V3.update()');
    await nestFutures4V3.update(nestGovernance.address);
    console.log('7. nestFutures4V4.update()');
    await nestFutures4V4.update(nestGovernance.address);
    console.log('7. nestFutures4V5.update()');
    await nestFutures4V5.update(nestGovernance.address);
    console.log('7. nestFutures4V6.update()');
    await nestFutures4V6.update(nestGovernance.address);
    console.log('8. nestProbability.update()');
    await nestProbability.update(nestGovernance.address);
    console.log('8. nestBuybackPool.update()');
    await nestBuybackPool.update(nestGovernance.address);
    console.log('9. nestCyberInk.update()');
    await nestCyberInk.update(nestGovernance.address);

    console.log('10. nestNFTAuction.update()');
    await nestNFTAuction.update(nestGovernance.address);
    console.log('11. nestMarket.update()');
    await nestMarket.update(nestGovernance.address);
    console.log('12. nestFuturesProxy.update()');
    await nestFuturesProxy.update(nestGovernance.address);

    // 2.4. Register ETH ans HBTC
    console.log('7. nestOptions.register(eth.address)');
    await nestOptions.register(eth.address, {
        channelId: 0,
        pairIndex: 0,
        
        sigmaSQ: 45659142400n,
        miuLong: 64051194700n,
        miuShort: 0n
    });

    console.log('8. nestOptions.register(hbtc.address)');
    await nestOptions.register(hbtc.address, {
        channelId: 0,
        pairIndex: 2,
        
        sigmaSQ: 31708924900n,
        miuLong: 64051194700n,
        miuShort: 0n
    });
    
    // 3.4. Register ETH and HBTC
    console.log('9. nestFutures.register(eth.address)');
    await nestFutures.register(eth.address, {
        channelId: 0,
        pairIndex: 0,
        
        sigmaSQ: 45659142400n,
        miuLong: 64051194700n,
        miuShort: 0n
    });
    console.log('10. nestFutures.register(hbtc.address)');
    await nestFutures.register(hbtc.address, {
        channelId: 0,
        pairIndex: 2,
        
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

    // await nestTrustFuturesV1.openChannel(0);
    // await nestTrustFuturesV1.openChannel(1);
    // await nestTrustFuturesV1.openChannel(2);
    // await nestTrustFuturesV2.openChannel(0);
    // await nestTrustFuturesV2.openChannel(1);
    // await nestTrustFuturesV2.openChannel(2);
    // await nestTrustFuturesV3.openChannel(0);
    // await nestTrustFuturesV3.openChannel(1);
    // await nestTrustFuturesV3.openChannel(2);

    await nestVault.approve(nestOptions.address, 100000000000000000000000000n);
    await nestVault.approve(nestFutures.address, 100000000000000000000000000n);
    await nestVault.approve(nestTrustFuturesV1.address, 100000000000000000000000000n);
    await nestVault.approve(nestTrustFuturesV2.address, 100000000000000000000000000n);
    await nestVault.approve(nestTrustFuturesV3.address, 100000000000000000000000000n);
    await nestVault.approve(nestFutures4V3.address, 100000000000000000000000000n);
    await nestVault.approve(nestFutures4V4.address, 100000000000000000000000000n);
    await nestVault.approve(nestFutures4V5.address, 100000000000000000000000000n);
    await nestVault.approve(nestProbability.address, 100000000000000000000000000n);
    
    await nest.mintTo(nestVault.address, 100000000000000000000000000n);
    await nest.approve(nestOptions.address, 100000000000000000000000000n);
    await nest.approve(nestFutures.address, 100000000000000000000000000n);
    await nest.approve(nestTrustFuturesV1.address, 100000000000000000000000000n);
    await nest.approve(nestTrustFuturesV2.address, 100000000000000000000000000n);
    await nest.approve(nestTrustFuturesV3.address, 100000000000000000000000000n);
    await nest.approve(nestFutures4V3.address, 100000000000000000000000000n);
    await nest.approve(nestFutures4V4.address, 100000000000000000000000000n);
    await nest.approve(nestFutures4V5.address, 100000000000000000000000000n);
    await nest.approve(nestFutures4V6.address, 100000000000000000000000000n);
    await nest.approve(nestProbability.address, 100000000000000000000000000n);

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
        nestTrustFuturesV1: nestTrustFuturesV1,
        nestTrustFuturesV2: nestTrustFuturesV2,
        nestTrustFuturesV3: nestTrustFuturesV3,
        nestFutures4V3: nestFutures4V3,
        nestFutures4V4: nestFutures4V4,
        nestFutures4V5: nestFutures4V5,
        nestFutures4V6: nestFutures4V6,
        nestMarket: nestMarket,
        nestVault: nestVault,
        nestFuturesProxy: nestFuturesProxy,
        pancakeFactory: pancakeFactory,
        pancakeRouter: pancakeRouter,
        gatling: gatling,

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