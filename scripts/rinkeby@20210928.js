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

    console.log('** Deploy: rinkeby@20210928.js **');
    
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // dcu: 0xDB7b4FdF99eEE8E4Cb8373630c923c51c1275382
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838

    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // dcu: 0xDB7b4FdF99eEE8E4Cb8373630c923c51c1275382
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // fortGovernance: 0x45F2387A06e2c0659c5aA757c3421e26398c1c35
    // fortDAO: 0xBd0b5800398FcB35a11e45291B28E7f32c1D435D
    // fortOptions: 0xAB7B4a58078A76CEBd3f9DeB7cf308C34AAb71F2
    // fortFutures: 0x269382F35b76C6d7C30980A9E835D7e6831e0D84
    // fortVaultForStaking: 0x8A68626A4c37481b4941f9a4137C94FDa41e9D91

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x2d750210c0b5343a0b79beff8F054C9add7d2411');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xDB7b4FdF99eEE8E4Cb8373630c923c51c1275382');
    console.log('dcu: ' + dcu.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const fortGovernance = await FortGovernance.attach('0x45F2387A06e2c0659c5aA757c3421e26398c1c35');
    console.log('fortGovernance: ' + fortGovernance.address);

    //const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    const fortDAO = await FortDAO.attach('0xBd0b5800398FcB35a11e45291B28E7f32c1D435D');
    console.log('fortDAO: ' + fortDAO.address);

    //const fortOptions = await upgrades.deployProxy(FortOptions, [fortGovernance.address], { initializer: 'initialize' });
    const fortOptions = await FortOptions.attach('0xAB7B4a58078A76CEBd3f9DeB7cf308C34AAb71F2');
    console.log('fortOptions: ' + fortOptions.address);

    //const fortFutures = await upgrades.deployProxy(FortFutures, [fortGovernance.address], { initializer: 'initialize' });
    const fortFutures = await FortFutures.attach('0x269382F35b76C6d7C30980A9E835D7e6831e0D84');
    console.log('fortFutures: ' + fortFutures.address);

    //const fortVaultForStaking = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    const fortVaultForStaking = await FortVaultForStaking.attach('0x8A68626A4c37481b4941f9a4137C94FDa41e9D91');
    console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

    console.log('---------- OK ----------');
    
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
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
};