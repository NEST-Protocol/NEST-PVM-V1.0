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
    const NestPRC44 = await ethers.getContractFactory('NestPRC44');
    const NestPRCSwap = await ethers.getContractFactory('NestPRCSwap');
    const NestBuyBackPool = await ethers.getContractFactory('NestBuyBackPool');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');

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

    const nestLPGuarantee = await upgrades.deployProxy(NestLPGuarantee, [nestGovernance.address], { initializer: 'initialize' });
    //const nestLPGuarantee = await NestLPGuarantee.attach('0x0000000000000000000000000000000000000000');
    console.log('nestLPGuarantee: ' + nestLPGuarantee.address);

    const nestPRC44 = await upgrades.deployProxy(NestPRC44, [nestGovernance.address], { initializer: 'initialize' });
    //const nestPRC44 = await NestPRC44.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPRC44: ' + nestPRC44.address);
    
    const nestPRCSwap = await upgrades.deployProxy(NestPRCSwap, [nestGovernance.address], { initializer: 'initialize' });
    //const nestPRCSwap = await NestPRCSwap.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPRCSwap: ' + nestPRCSwap.address);

    const nestBuyBackPool = await upgrades.deployProxy(NestBuyBackPool, [nestGovernance.address], { initializer: 'initialize' });
    // const nestBuyBackPool = await NestBuyBackPool.attach('0x0000000000000000000000000000000000000000');
    console.log('nestBuyBackPool: ' + nestBuyBackPool.address);

    const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [nestGovernance.address], { initializer: 'initialize' });
    //const cofixRouter = await CoFiXRouter.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixRouter: ' + cofixRouter.address);

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
    await nestGovernance.registerAddress('nest.app.dcu', dcu.address);
    await nestGovernance.registerAddress('nest.app.prc', nestPRC44.address);
    await nestGovernance.registerAddress('cofix.cofixRouter', cofixRouter.address);

    console.log('4. nestVault.update()');
    await nestVault.update(nestGovernance.address);
    console.log('5. nestOptions.update()');
    await nestOptions.update(nestGovernance.address);
    console.log('6. nestFutures.update()');
    await nestFutures.update(nestGovernance.address);
    console.log('7.2. nestLPGuarantee.update()');
    await nestLPGuarantee.update(nestGovernance.address);
    console.log('8. nestPRC44.update()');
    await nestPRC44.update(nestGovernance.address);
    console.log('8. nestBuyBackPool.update()');
    await nestBuyBackPool.update(nestGovernance.address);
    console.log('9. nestPRCSwap.update()');
    await nestPRCSwap.update(nestGovernance.address);

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

    await nestLPGuarantee.register(eth.address, {
        channelId: 0,
        pairIndex: 0,
        
        sigmaSQ: 45659142400n,
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

    await cofixRouter.registerPair(nestPRC44.address, nest.address, nestPRCSwap.address);
    await cofixRouter.registerPair(dcu.address, nest.address, nestBuyBackPool.address);

    await nest.transfer(nestVault.address, 100000000000000000000000000n);
    await nest.approve(nestOptions.address, 100000000000000000000000000n);
    await nest.approve(nestFutures.address, 100000000000000000000000000n);
    await nest.approve(nestLPGuarantee.address, 100000000000000000000000000n);
    await nestVault.approve(nestOptions.address, 100000000000000000000000000n);
    await nestVault.approve(nestFutures.address, 100000000000000000000000000n);
    await nestVault.approve(nestLPGuarantee.address, 100000000000000000000000000n);
    await nestVault.approve(nestPRC44.address, 100000000000000000000000000n);

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
        nestPRC44: nestPRC44,
        nestPRCSwap: nestPRCSwap,
        nestPriceFacade: nestPriceFacade,
        nestBuyBackPool: nestBuyBackPool,
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