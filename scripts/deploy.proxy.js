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
    const NestFuturesWithPrice = await ethers.getContractFactory('NestFutures2');
    const NestMarket = await ethers.getContractFactory('NestMarket');
    const NestFuturesProxy = await ethers.getContractFactory('NestFuturesProxy');

    console.log('** Deploy: deploy.proxy.js **');
    
    const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    //const hbtc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('hbtc: ' + hbtc.address);

    const dcu = await TestERC20.deploy('DCU', 'DCU', 18);
    //const dcu = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('dcu: ' + dcu.address);

    const nest = await TestERC20.deploy('NEST', 'NEST', 18);
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

    const nestFuturesWithPrice = await upgrades.deployProxy(NestFuturesWithPrice, [nestGovernance.address], { initializer: 'initialize' });
    //const nestFuturesWithPrice = await NestFuturesWithPrice.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFuturesWithPrice: ' + nestFuturesWithPrice.address);

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
    await nestGovernance.registerAddress('nest.app.futures', nestFuturesWithPrice.address);
    await nestGovernance.registerAddress('nest.app.futuresProxy', nestFuturesProxy.address);
    await nestGovernance.registerAddress('nest.app.dcu', dcu.address);
    await nestGovernance.registerAddress('nest.app.prc', nestProbability.address);
    await nestGovernance.registerAddress('nest.app.cyberink', nestCyberInk.address);
    await nestGovernance.registerAddress('nest.app.directPoster', (await ethers.getSigners())[0].address)

    console.log('4. nestVault.update()');
    await nestVault.update(nestGovernance.address);
    console.log('5. nestOptions.update()');
    await nestOptions.update(nestGovernance.address);
    console.log('6. nestFutures.update()');
    await nestFutures.update(nestGovernance.address);
    console.log('7. nestFuturesWithPrice.update()');
    await nestFuturesWithPrice.update(nestGovernance.address);
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

    // 3.4. Register ETH and HBTC
    console.log('9. nestFuturesWithPrice.register(eth.address)');
    await nestFuturesWithPrice.register(eth.address, {
        channelId: 0,
        pairIndex: 0,
        
        sigmaSQ: 45659142400n,
        miuLong: 64051194700n,
        miuShort: 0n
    });
    console.log('10. nestFuturesWithPrice.register(hbtc.address)');
    await nestFuturesWithPrice.register(hbtc.address, {
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

    // 3.5. Register levels for ETH
    console.log('13. create eth long lever');
    await nestFuturesWithPrice.create(eth.address, [1, 2, 3, 4, 5], true);
    console.log('14. create eth short lever');
    await nestFuturesWithPrice.create(eth.address, [1, 2, 3, 4, 5], false);
    
    // 3.5. Register levels for HBTC
    console.log('13. create hbtc long lever');
    await nestFuturesWithPrice.create(hbtc.address, [1, 2, 3, 4, 5], true);
    console.log('14. create hbtc short lever');
    await nestFuturesWithPrice.create(hbtc.address, [1, 2, 3, 4, 5], false);

    await nestVault.approve(nestOptions.address, 100000000000000000000000000n);
    await nestVault.approve(nestFutures.address, 100000000000000000000000000n);
    await nestVault.approve(nestFuturesWithPrice.address, 100000000000000000000000000n);
    await nestVault.approve(nestProbability.address, 100000000000000000000000000n);
    
    await nest.transfer(nestVault.address, 100000000000000000000000000n);
    await nest.approve(nestOptions.address, 100000000000000000000000000n);
    await nest.approve(nestFutures.address, 100000000000000000000000000n);
    await nest.approve(nestFuturesWithPrice.address, 100000000000000000000000000n);
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
        nestFuturesWithPrice: nestFuturesWithPrice,
        nestMarket: nestMarket,
        nestVault: nestVault,
        nestFuturesProxy: nestFuturesProxy,

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