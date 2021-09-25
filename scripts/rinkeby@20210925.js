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
    const FortDCU = await ethers.getContractFactory('FortDCU');
    const FortDAO = await ethers.getContractFactory('FortDAO');
    const FortEuropeanOption = await ethers.getContractFactory('FortEuropeanOption');
    const FortLever = await ethers.getContractFactory('FortLever');
    const FortVaultForStaking = await ethers.getContractFactory('FortVaultForStaking');

    console.log('** 开始部署合约 rinkeby@20210925.js **');
    
    // ** 开始部署合约 rinkeby@20210925.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // fort: 0xDB7b4FdF99eEE8E4Cb8373630c923c51c1275382
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // fortGovernance: 0x43E8330d1725a2978122B49d41197e7Dc073cdf1
    // fortDAO: 0x57E481f193df1e69639171506b2c38136e53B7d1
    // fortEuropeanOption: 0x7557E34f05193b8Ee1edC1A4c0d4f8A158D1Ab61
    // fortLever: 0x183C6068f6e3c25912f0D054e2cC34D11f217f50
    // fortVaultForStaking: 0x3254D21C38c6b8ea4A256A5B474622852F8B6d2A
    
    // 1. 部署依赖合约
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x2d750210c0b5343a0b79beff8F054C9add7d2411');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    //const fort = await FortDCU.deploy();
    const fort = await FortDCU.attach('0xDB7b4FdF99eEE8E4Cb8373630c923c51c1275382');
    console.log('fort: ' + fort.address);
    
    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const fortGovernance = await FortGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('fortGovernance: ' + fortGovernance.address);

    const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    //const fortDAO = await FortDAO.attach('0x0000000000000000000000000000000000000000');
    console.log('fortDAO: ' + fortDAO.address);

    const fortEuropeanOption = await upgrades.deployProxy(FortEuropeanOption, [fortGovernance.address], { initializer: 'initialize' });
    //const fortEuropeanOption = await FortEuropeanOption.attach('0x0000000000000000000000000000000000000000');
    console.log('fortEuropeanOption: ' + fortEuropeanOption.address);

    const fortLever = await upgrades.deployProxy(FortLever, [fortGovernance.address], { initializer: 'initialize' });
    //const fortLever = await FortLever.attach('0x0000000000000000000000000000000000000000');
    console.log('fortLever: ' + fortLever.address);

    const fortVaultForStaking = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    //const fortVaultForStaking = await FortVaultForStaking.attach('0x0000000000000000000000000000000000000000');
    console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

    // await fortGovernance.initialize('0x0000000000000000000000000000000000000000');
    console.log('1. fort.initialize(fortGovernance.address)');
    await fort.initialize(fortGovernance.address);
    // await fortDAO.initialize(fortGovernance.address);
    // await fortEuropeanOption.initialize(fortGovernance.address);
    // await fortLever.initialize(fortGovernance.address);
    // await fortVaultForStaking.initialize(fortGovernance.address);

    console.log('2. fortGovernance.setBuiltinAddress()');
    await fortGovernance.setBuiltinAddress(
        fort.address,
        fortDAO.address,
        fortEuropeanOption.address,
        fortLever.address,
        fortVaultForStaking.address,
        nestPriceFacade.address
    );

    console.log('3. fort.update()');
    await fort.update(fortGovernance.address);
    console.log('4. fortDAO.update()');
    await fortDAO.update(fortGovernance.address);
    console.log('5. fortEuropeanOption.update()');
    await fortEuropeanOption.update(fortGovernance.address);
    console.log('6. fortLever.update()');
    await fortLever.update(fortGovernance.address);
    console.log('7. fortVaultForStaking.update()');
    await fortVaultForStaking.update(fortGovernance.address);

    console.log('8. fortEuropeanOption.setConfig()');
    await fortEuropeanOption.setConfig(eth.address, { 
        sigmaSQ: '45659142400', 
        miu: '467938556917', 
        minPeriod: 6000 
    });
    console.log('8.1. fortEuropeanOption.setConfig()');
    await fortEuropeanOption.setConfig(hbtc.address, { 
        sigmaSQ: '45659142400', 
        miu: '467938556917', 
        minPeriod: 6000 
    });

    console.log('9. fort.setMinter(fortEuropeanOption.address, 1)');
    await fort.setMinter(fortEuropeanOption.address, 1);
    console.log('10. fort.setMinter(fortLever.address, 1)');
    await fort.setMinter(fortLever.address, 1);
    console.log('11. fort.setMinter(fortVaultForStaking.address, 1)');
    await fort.setMinter(fortVaultForStaking.address, 1);

    await fortEuropeanOption.setUsdtTokenAddress(usdt.address);
    await fortLever.setUsdtTokenAddress(usdt.address);

    console.log('8.2 create lever');
    await fortLever.create(eth.address, 1, true);
    await fortLever.create(eth.address, 2, true);
    await fortLever.create(eth.address, 5, true);
    await fortLever.create(eth.address, 1, false);
    await fortLever.create(eth.address, 2, false);
    await fortLever.create(eth.address, 5, false);
    await fortLever.create(hbtc.address, 1, true);
    await fortLever.create(hbtc.address, 2, true);
    await fortLever.create(hbtc.address, 5, true);
    await fortLever.create(hbtc.address, 1, false);
    await fortLever.create(hbtc.address, 2, false);
    await fortLever.create(hbtc.address, 5, false);

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        usdt: usdt,
        hbtc: hbtc,

        fortGovernance: fortGovernance,
        fort: fort,
        fortDAO: fortDAO,
        fortEuropeanOption: fortEuropeanOption,
        fortLever: fortLever,
        fortVaultForStaking: fortVaultForStaking,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
};