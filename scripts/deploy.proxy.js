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
    const HedgeGovernance = await ethers.getContractFactory('HedgeGovernance');
    const DCU = await ethers.getContractFactory('DCU');
    const HedgeDAO = await ethers.getContractFactory('HedgeDAO');
    const HedgeOptions = await ethers.getContractFactory('HedgeOptions');
    const HedgeFutures = await ethers.getContractFactory('HedgeFutures');
    const HedgeVaultForStaking = await ethers.getContractFactory('HedgeVaultForStaking');
    const HedgeSwap = await ethers.getContractFactory('HedgeSwap');

    console.log('** 开始部署合约 deploy.proxy.js **');
    
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

    // 1. 部署依赖合约
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

    const hedgeGovernance = await upgrades.deployProxy(HedgeGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const hedgeGovernance = await HedgeGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeGovernance: ' + hedgeGovernance.address);

    const hedgeDAO = await upgrades.deployProxy(HedgeDAO, [hedgeGovernance.address], { initializer: 'initialize' });
    //const hedgeDAO = await HedgeDAO.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeDAO: ' + hedgeDAO.address);

    const hedgeOptions = await upgrades.deployProxy(HedgeOptions, [hedgeGovernance.address], { initializer: 'initialize' });
    //const hedgeOptions = await HedgeOptions.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeOptions: ' + hedgeOptions.address);

    const hedgeFutures = await upgrades.deployProxy(HedgeFutures, [hedgeGovernance.address], { initializer: 'initialize' });
    //const hedgeFutures = await HedgeFutures.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeFutures: ' + hedgeFutures.address);

    const hedgeVaultForStaking = await upgrades.deployProxy(HedgeVaultForStaking, [hedgeGovernance.address], { initializer: 'initialize' });
    //const hedgeVaultForStaking = await HedgeVaultForStaking.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeVaultForStaking: ' + hedgeVaultForStaking.address);

    const hedgeSwap = await upgrades.deployProxy(HedgeSwap, [hedgeGovernance.address], { initializer: 'initialize' });
    //const hedgeSwap = await HedgeSwap.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeSwap: ' + hedgeSwap.address);

    // await hedgeGovernance.initialize('0x0000000000000000000000000000000000000000');
    console.log('1. dcu.initialize(hedgeGovernance.address)');
    await dcu.initialize(hedgeGovernance.address);
    // await hedgeDAO.initialize(hedgeGovernance.address);
    // await hedgeOptions.initialize(hedgeGovernance.address);
    // await hedgeFutures.initialize(hedgeGovernance.address);
    // await hedgeVaultForStaking.initialize(hedgeGovernance.address);

    console.log('2. hedgeGovernance.setBuiltinAddress()');
    await hedgeGovernance.setBuiltinAddress(
        dcu.address,
        hedgeDAO.address,
        hedgeOptions.address,
        hedgeFutures.address,
        hedgeVaultForStaking.address,
        nestPriceFacade.address
    );

    console.log('3. dcu.update()');
    await dcu.update(hedgeGovernance.address);
    console.log('4. hedgeDAO.update()');
    await hedgeDAO.update(hedgeGovernance.address);
    console.log('5. hedgeOptions.update()');
    await hedgeOptions.update(hedgeGovernance.address);
    console.log('6. hedgeFutures.update()');
    await hedgeFutures.update(hedgeGovernance.address);
    console.log('7. hedgeVaultForStaking.update()');
    await hedgeVaultForStaking.update(hedgeGovernance.address);
    console.log('8. hedgeVaultForStaking.update()');
    await hedgeSwap.update(hedgeGovernance.address);

    // console.log('8. hedgeOptions.setConfig()');
    // await hedgeOptions.setConfig(eth.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });
    // console.log('8.1. hedgeOptions.setConfig()');
    // await hedgeOptions.setConfig(hbtc.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });

    console.log('9. dcu.setMinter(hedgeOptions.address, 1)');
    await dcu.setMinter(hedgeOptions.address, 1);
    console.log('10. dcu.setMinter(hedgeFutures.address, 1)');
    await dcu.setMinter(hedgeFutures.address, 1);
    console.log('11. dcu.setMinter(hedgeVaultForStaking.address, 1)');
    await dcu.setMinter(hedgeVaultForStaking.address, 1);

    //await usdt.transfer(usdt.address, 0);
    //await usdt.transfer(usdt.address, 0);
    //await hedgeOptions.setUsdtTokenAddress(usdt.address);
    //await hedgeFutures.setUsdtTokenAddress(usdt.address);

    console.log('8.2 create lever');
    await hedgeFutures.create(eth.address, 1, true);
    await hedgeFutures.create(eth.address, 2, true);
    await hedgeFutures.create(eth.address, 3, true);
    await hedgeFutures.create(eth.address, 4, true);
    await hedgeFutures.create(eth.address, 5, true);
    await hedgeFutures.create(eth.address, 1, false);
    await hedgeFutures.create(eth.address, 2, false);
    await hedgeFutures.create(eth.address, 3, false);
    await hedgeFutures.create(eth.address, 4, false);
    await hedgeFutures.create(eth.address, 5, false);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        usdt: usdt,
        hbtc: hbtc,

        hedgeGovernance: hedgeGovernance,
        dcu: dcu,
        hedgeDAO: hedgeDAO,
        hedgeOptions: hedgeOptions,
        hedgeFutures: hedgeFutures,
        hedgeVaultForStaking: hedgeVaultForStaking,
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