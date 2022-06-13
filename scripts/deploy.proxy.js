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
    const FortDAO = await ethers.getContractFactory('FortDAO');
    const FortOptions = await ethers.getContractFactory('FortOptions');
    const FortFutures = await ethers.getContractFactory('FortFutures');
    const FortVaultForStaking = await ethers.getContractFactory('FortVaultForStaking');
    const HedgeSwap = await ethers.getContractFactory('HedgeSwap');

    console.log('** Deploy: deploy.proxy.js **');
    
    // const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    // //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    // console.log('nest: ' + nest.address);

    // const nhbtc = await TestERC20.deploy('NHBTC', 'NEST', 18);
    // //const nhbtc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    // console.log('nhbtc: ' + nhbtc.address);

    // const cofi = await TestERC20.deploy('COFI', 'COFI', 18);
    // //const cofi = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    // console.log('cofi: ' + cofi.address);

    // const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    // //const pusd = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    // console.log('pusd: ' + pusd.address);

    // const fortube = await TestERC20.deploy('FORTUBE', 'FORTUBE', 18);
    // //const fortube = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    // console.log('fortube: ' + fortube.address);

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

    const hedgeSwap = await upgrades.deployProxy(HedgeSwap, [fortGovernance.address], { initializer: 'initialize' });
    //const hedgeSwap = await HedgeSwap.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeSwap: ' + hedgeSwap.address);

    // await fortGovernance.initialize('0x0000000000000000000000000000000000000000');
    console.log('1. dcu.initialize(fortGovernance.address)');
    await dcu.initialize(fortGovernance.address);
    // await fortDAO.initialize(fortGovernance.address);
    // await fortOptions.initialize(fortGovernance.address);
    // await fortFutures.initialize(fortGovernance.address);
    // await fortVaultForStaking.initialize(fortGovernance.address);

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
    console.log('8. fortVaultForStaking.update()');
    await hedgeSwap.update(fortGovernance.address);

    // console.log('8. fortOptions.setConfig()');
    // await fortOptions.setConfig(eth.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });
    // console.log('8.1. fortOptions.setConfig()');
    // await fortOptions.setConfig(hbtc.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });

    console.log('9. dcu.setMinter(fortOptions.address, 1)');
    await dcu.setMinter(fortOptions.address, 1);
    console.log('10. dcu.setMinter(fortFutures.address, 1)');
    await dcu.setMinter(fortFutures.address, 1);
    console.log('11. dcu.setMinter(fortVaultForStaking.address, 1)');
    await dcu.setMinter(fortVaultForStaking.address, 1);

    //await usdt.transfer(usdt.address, 0);
    //await usdt.transfer(usdt.address, 0);
    //await fortOptions.setUsdtTokenAddress(usdt.address);
    //await fortFutures.setUsdtTokenAddress(usdt.address);

    console.log('8.2 create lever');
    await fortFutures.create(eth.address, 1, true , 0, 0);
    await fortFutures.create(eth.address, 2, true , 0, 0);
    await fortFutures.create(eth.address, 3, true , 0, 0);
    await fortFutures.create(eth.address, 4, true , 0, 0);
    await fortFutures.create(eth.address, 5, true , 0, 0);
    await fortFutures.create(eth.address, 1, false, 0, 0);
    await fortFutures.create(eth.address, 2, false, 0, 0);
    await fortFutures.create(eth.address, 3, false, 0, 0);
    await fortFutures.create(eth.address, 4, false, 0, 0);
    await fortFutures.create(eth.address, 5, false, 0, 0);

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
        nestPriceFacade: nestPriceFacade,
        hedgeSwap: hedgeSwap,

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