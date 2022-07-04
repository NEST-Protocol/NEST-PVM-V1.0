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
    const FortGovernance = await ethers.getContractFactory('FortGovernance');
    const DCU = await ethers.getContractFactory('DCU');
    const FortDAO = await ethers.getContractFactory('FortVault');
    const FortOptions = await ethers.getContractFactory('NestOptions');
    const FortFutures = await ethers.getContractFactory('NestFutures');
    const FortVaultForStaking = await ethers.getContractFactory('FortVaultForStaking');
    const FortSwap = await ethers.getContractFactory('FortSwap');
    const FortLPGuarantee = await ethers.getContractFactory('FortLPGuarantee');
    const FortPRC44 = await ethers.getContractFactory('NestPRC44');
    const FortPRCSwap = await ethers.getContractFactory('FortPRCSwap');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');

    console.log('** Deploy: deploy.proxy.js **');
    
    const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    //const hbtc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('hbtc: ' + hbtc.address);

    const dcu = await DCU.deploy();
    //const dcu = await DCU.attach('0x0000000000000000000000000000000000000000');
    console.log('dcu: ' + dcu.address);

    const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    //const nestPriceFacade = await NestPriceFacade.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const fortGovernance = await FortGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('fortGovernance: ' + fortGovernance.address);

    const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    //const fortDAO = await FortDAO.attach('0x0000000000000000000000000000000000000000');
    console.log('fortDAO: ' + fortDAO.address);

    const fortOptions = await upgrades.deployProxy(FortOptions, [fortGovernance.address], { initializer: 'initialize' });
    //const fortOptions = await FortOptions.attach('0x0000000000000000000000000000000000000000');
    console.log('fortOptions: ' + fortOptions.address);

    const fortFutures = await upgrades.deployProxy(FortFutures, [fortGovernance.address], { initializer: 'initialize' });
    //const fortFutures = await FortFutures.attach('0x0000000000000000000000000000000000000000');
    console.log('fortFutures: ' + fortFutures.address);

    const fortVaultForStaking = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    //const fortVaultForStaking = await FortVaultForStaking.attach('0x0000000000000000000000000000000000000000');
    console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

    const fortSwap = await upgrades.deployProxy(FortSwap, [fortGovernance.address], { initializer: 'initialize' });
    //const fortSwap = await FortSwap.attach('0x0000000000000000000000000000000000000000');
    console.log('fortSwap: ' + fortSwap.address);

    const fortLPGuarantee = await upgrades.deployProxy(FortLPGuarantee, [fortGovernance.address], { initializer: 'initialize' });
    //const fortLPGuarantee = await FortLPGuarantee.attach('0x0000000000000000000000000000000000000000');
    console.log('fortLPGuarantee: ' + fortLPGuarantee.address);

    const fortPRC44 = await upgrades.deployProxy(FortPRC44, [fortGovernance.address], { initializer: 'initialize' });
    //const fortPRC44 = await FortPRC44.attach('0x0000000000000000000000000000000000000000');
    console.log('fortPRC44: ' + fortPRC44.address);
    
    const fortPRCSwap = await upgrades.deployProxy(FortPRCSwap, [fortGovernance.address], { initializer: 'initialize' });
    //const fortPRCSwap = await FortPRCSwap.attach('0x0000000000000000000000000000000000000000');
    console.log('fortPRCSwap: ' + fortPRCSwap.address);

    const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [fortGovernance.address], { initializer: 'initialize' });
    //const cofixRouter = await CoFiXRouter.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixRouter: ' + cofixRouter.address);

    // await fortGovernance.initialize('0x0000000000000000000000000000000000000000');
    console.log('1. dcu.initialize(fortGovernance.address)');
    await dcu.initialize(fortGovernance.address);

    console.log('2. fortGovernance.setBuiltinAddress()');
    await fortGovernance.setBuiltinAddress(
        dcu.address,
        fortDAO.address,
        fortOptions.address,
        fortFutures.address,
        fortVaultForStaking.address,
        nestPriceFacade.address
    );

    console.log('3. dcu.update()');
    await dcu.update(fortGovernance.address);
    console.log('4. fortDAO.update()');
    await fortDAO.update(fortGovernance.address);
    console.log('5. fortOptions.update()');
    await fortOptions.update(fortGovernance.address);
    console.log('6. fortFutures.update()');
    await fortFutures.update(fortGovernance.address);
    console.log('7. fortVaultForStaking.update()');
    await fortVaultForStaking.update(fortGovernance.address);
    console.log('7.1. fortSwap.update()');
    await fortSwap.update(fortGovernance.address);
    console.log('7.2. fortLPGuarantee.update()');
    await fortLPGuarantee.update(fortGovernance.address);
    console.log('8. fortPRC44.update()');
    await fortPRC44.update(fortGovernance.address);
    console.log('9. fortPRCSwap.update()');
    await fortPRCSwap.update(fortGovernance.address);

    // 2.4. Register ETH ans HBTC
    console.log('7. fortOptions.register(eth.address)');
    await fortOptions.register(eth.address, {
        channelId: 0,
        pairIndex: 0,
        
        sigmaSQ: 45659142400n,
        miuLong: 64051194700n,
        miuShort: 0n
    });

    console.log('8. fortOptions.register(hbtc.address)');
    await fortOptions.register(hbtc.address, {
        channelId: 0,
        pairIndex: 2,
        
        sigmaSQ: 31708924900n,
        miuLong: 64051194700n,
        miuShort: 0n
    });
    
    // 3.4. Register ETH and HBTC
    console.log('9. fortFutures.register(eth.address)');
    await fortFutures.register(eth.address, {
        channelId: 0,
        pairIndex: 0,
        
        sigmaSQ: 45659142400n,
        miuLong: 64051194700n,
        miuShort: 0n
    });
    console.log('10. fortFutures.register(hbtc.address)');
    await fortFutures.register(hbtc.address, {
        channelId: 0,
        pairIndex: 2,
        
        sigmaSQ: 31708924900n,
        miuLong: 64051194700n,
        miuShort: 0n
    });

    await fortLPGuarantee.register(eth.address, {
        channelId: 0,
        pairIndex: 0,
        
        sigmaSQ: 45659142400n,
        miuLong: 64051194700n,
        miuShort: 0n
    });

    console.log('9. dcu.setMinter(fortOptions.address, 1)');
    await dcu.setMinter(fortOptions.address, 1);
    console.log('10. dcu.setMinter(fortFutures.address, 1)');
    await dcu.setMinter(fortFutures.address, 1);
    console.log('11. dcu.setMinter(fortVaultForStaking.address, 1)');
    await dcu.setMinter(fortVaultForStaking.address, 1);
    console.log('12. dcu.setMinter(fortPRC44.address, 1)');
    await dcu.setMinter(fortPRC44.address, 1);
    console.log('13. dcu.setMinter(fortLPGuarantee.address, 1)');
    await dcu.setMinter(fortLPGuarantee.address, 1);

    console.log('8.2 create lever');
    
    // 3.5. Register levels for ETH
    console.log('13. create eth long lever');
    await fortFutures.create(eth.address, [1, 2, 3, 4, 5], true);
    console.log('14. create eth short lever');
    await fortFutures.create(eth.address, [1, 2, 3, 4, 5], false);
    
    // 3.5. Register levels for HBTC
    console.log('13. create hbtc long lever');
    await fortFutures.create(hbtc.address, [1, 2, 3, 4, 5], true);
    console.log('14. create hbtc short lever');
    await fortFutures.create(hbtc.address, [1, 2, 3, 4, 5], false);


    await cofixRouter.registerPair(fortPRC44.address, dcu.address, fortPRCSwap.address);
    await fortPRCSwap.setAddress(cofixRouter.address, fortPRC44.address);
    await fortDAO.setAddress(dcu.address);

    await dcu.approve(fortOptions.address, 100000000000000000000000000n);
    await dcu.approve(fortFutures.address, 100000000000000000000000000n);
    await fortDAO.approve(fortOptions.address, 100000000000000000000000000n);
    await fortDAO.approve(fortFutures.address, 100000000000000000000000000n);
    await dcu.approve(fortFutures.address, 100000000000000000000000000n);

    var [owner, addr1, addr2] = await ethers.getSigners();
    await dcu.setMinter(owner.address, 1);
    await dcu.mint(fortDAO.address, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        usdt: usdt,
        hbtc: hbtc,

        fortGovernance: fortGovernance,
        dcu: dcu,
        fortDAO: fortDAO,
        fortOptions: fortOptions,
        fortFutures: fortFutures,
        fortVaultForStaking: fortVaultForStaking,
        fortSwap: fortSwap,
        fortLPGuarantee: fortLPGuarantee,
        fortPRC44: fortPRC44,
        fortPRCSwap: fortPRCSwap,
        nestPriceFacade: nestPriceFacade,
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