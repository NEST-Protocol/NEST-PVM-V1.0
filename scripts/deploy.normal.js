// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');

exports.deploy = async function() {
    
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const FortGovernance = await ethers.getContractFactory('FortGovernance');
    const DCU = await ethers.getContractFactory('DCU');
    const FortDAO = await ethers.getContractFactory('FortDAO');
    const FortOptions = await ethers.getContractFactory('FortOptions');
    const FortFutures = await ethers.getContractFactory('FortFutures');
    const FortVaultForStaking = await ethers.getContractFactory('FortVaultForStaking');

    console.log('** Deploy: deploy.normal.js **');
    
    const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const nestPriceFacade = await NestPriceFacade.deploy();
    //const nestPriceFacade = await NestPriceFacade.attach('0x0000000000000000000000000000000000000000');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    const fortGovernance = await FortGovernance.deploy();
    //const fortGovernance = await FortGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('fortGovernance: ' + fortGovernance.address);

    const dcu = await DCU.deploy();
    //const dcu = await DCU.attach('0x0000000000000000000000000000000000000000');
    console.log('dcu: ' + dcu.address);

    const fortDAO = await FortDAO.deploy();
    //const fortDAO = await FortDAO.attach('0x0000000000000000000000000000000000000000');
    console.log('fortDAO: ' + fortDAO.address);

    const fortOptions = await FortOptions.deploy();
    //const fortOptions = await FortOptions.attach('0x0000000000000000000000000000000000000000');
    console.log('fortOptions: ' + fortOptions.address);

    const fortFutures = await FortFutures.deploy();
    //const fortFutures = await FortFutures.attach('0x0000000000000000000000000000000000000000');
    console.log('fortFutures: ' + fortFutures.address);

    const fortVaultForStaking = await FortVaultForStaking.deploy();
    //const fortVaultForStaking = await FortVaultForStaking.attach('0x0000000000000000000000000000000000000000');
    console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

    await fortGovernance.initialize('0x0000000000000000000000000000000000000000');
    await dcu.initialize(fortGovernance.address);
    await fortDAO.initialize(fortGovernance.address);
    await fortOptions.initialize(fortGovernance.address);
    await fortFutures.initialize(fortGovernance.address);
    await fortVaultForStaking.initialize(fortGovernance.address);

    await fortGovernance.setBuiltinAddress(
        dcu.address,
        fortDAO.address,
        fortOptions.address,
        fortFutures.address,
        fortVaultForStaking.address,
        nestPriceFacade.address
    );

    await dcu.update(fortGovernance.address);
    await fortDAO.update(fortGovernance.address);
    await fortOptions.update(fortGovernance.address);
    await fortFutures.update(fortGovernance.address);
    await fortVaultForStaking.update(fortGovernance.address);

    await fortOptions.setConfig('4168125400', '175482725206', 10000);
    
    await dcu.setMinter(fortOptions.address, 1);
    await dcu.setMinter(fortFutures.address, 1);
    await dcu.setMinter(fortVaultForStaking.address, 1);

    //await fortOptions.setUsdtTokenAddress(usdt.address);
    //await fortFutures.setUsdtTokenAddress(usdt.address);

    console.log('---------- OK ----------');

    const contracts = {
        usdt: usdt,

        dcu: dcu,
        fortDAO: fortDAO,
        fortOptions: fortOptions,
        fortFutures: fortFutures,
        fortVaultForStaking: fortVaultForStaking,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
}