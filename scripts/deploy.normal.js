// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');

exports.deploy = async function() {
    
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const HedgeGovernance = await ethers.getContractFactory('HedgeGovernance');
    const DCU = await ethers.getContractFactory('DCU');
    const HedgeDAO = await ethers.getContractFactory('HedgeDAO');
    const HedgeOptions = await ethers.getContractFactory('HedgeOptions');
    const HedgeFutures = await ethers.getContractFactory('HedgeFutures');
    const HedgeVaultForStaking = await ethers.getContractFactory('HedgeVaultForStaking');

    console.log('** Deploy: deploy.normal.js **');
    
    const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const nestPriceFacade = await NestPriceFacade.deploy();
    //const nestPriceFacade = await NestPriceFacade.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    const hedgeGovernance = await HedgeGovernance.deploy();
    //const hedgeGovernance = await HedgeGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeGovernance: ' + hedgeGovernance.address);

    const dcu = await DCU.deploy();
    //const dcu = await DCU.attach('0x0000000000000000000000000000000000000000');
    console.log('dcu: ' + dcu.address);

    const hedgeDAO = await HedgeDAO.deploy();
    //const hedgeDAO = await HedgeDAO.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeDAO: ' + hedgeDAO.address);

    const hedgeOptions = await HedgeOptions.deploy();
    //const hedgeOptions = await HedgeOptions.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeOptions: ' + hedgeOptions.address);

    const hedgeFutures = await HedgeFutures.deploy();
    //const hedgeFutures = await HedgeFutures.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeFutures: ' + hedgeFutures.address);

    const hedgeVaultForStaking = await HedgeVaultForStaking.deploy();
    //const hedgeVaultForStaking = await HedgeVaultForStaking.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeVaultForStaking: ' + hedgeVaultForStaking.address);

    await hedgeGovernance.initialize('0x0000000000000000000000000000000000000000');
    await dcu.initialize(hedgeGovernance.address);
    await hedgeDAO.initialize(hedgeGovernance.address);
    await hedgeOptions.initialize(hedgeGovernance.address);
    await hedgeFutures.initialize(hedgeGovernance.address);
    await hedgeVaultForStaking.initialize(hedgeGovernance.address);

    await hedgeGovernance.setBuiltinAddress(
        dcu.address,
        hedgeDAO.address,
        hedgeOptions.address,
        hedgeFutures.address,
        hedgeVaultForStaking.address,
        nestPriceFacade.address
    );

    await dcu.update(hedgeGovernance.address);
    await hedgeDAO.update(hedgeGovernance.address);
    await hedgeOptions.update(hedgeGovernance.address);
    await hedgeFutures.update(hedgeGovernance.address);
    await hedgeVaultForStaking.update(hedgeGovernance.address);

    await hedgeOptions.setConfig('4168125400', '175482725206', 10000);
    
    await dcu.setMinter(hedgeOptions.address, 1);
    await dcu.setMinter(hedgeFutures.address, 1);
    await dcu.setMinter(hedgeVaultForStaking.address, 1);

    //await hedgeOptions.setUsdtTokenAddress(usdt.address);
    //await hedgeFutures.setUsdtTokenAddress(usdt.address);

    console.log('---------- OK ----------');

    const contracts = {
        usdt: usdt,

        dcu: dcu,
        hedgeDAO: hedgeDAO,
        hedgeOptions: hedgeOptions,
        hedgeFutures: hedgeFutures,
        hedgeVaultForStaking: hedgeVaultForStaking,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
}