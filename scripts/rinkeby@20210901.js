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
    const FortLeverToken = await ethers.getContractFactory('FortLeverToken');
    const FortVaultForStaking = await ethers.getContractFactory('FortVaultForStaking');

    console.log('** 开始部署合约 rinkeby@20210901.js **');
    
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838

    // ** 开始部署合约 rinkeby@20210901.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // fortGovernance: 0xDD61E5604580AfeEe202d533eefE688091b8127e
    // fort: 0xDB7b4FdF99eEE8E4Cb8373630c923c51c1275382
    // fortDAO: 0xe7012078Cfa3E083d3Fe7B79bA4d8913Be48362F
    // fortEuropeanOption: 0x5bA7CBD3cC7C3ced0f94FC3CFd331260569E19Ca
    // fortLever: 0x1820A4c392d71B65C3C32c1a6E8d94A3FB785fae
    // fortVaultForStaking: 0xF06Ca516B6e11AB7843FB0B1a7eECBf0e57B3B64
    // ETH/USDT+F1: 0x1BcD7C075C6b94ef4D6a1aEE4496828d61B5f5F1
    // ETH/USDT+F2: 0x1B7D9daDBE37Eb6dF32c8682Ee3090b630D24F3e
    // ETH/USDT+F5: 0x6A308373912a73Fe17AB40637061A5eeeDD16975
    // ETH/USDT-F1: 0x9a1Aea23230447Da01E66Caa9D0D96c039805f89
    // ETH/USDT-F2: 0x502eAfEB2e8b14C22118e0F5a15427Edc4D3B2bB
    // ETH/USDT-F5: 0xD46880A5bA1cA2167D71582d8f2D5acdB441aBD5
    // HBTC/USDT+F1: 0xD8295D21a9Cec684eC05BAbBECe5c3AAB30eC46D
    // HBTC/USDT+F2: 0x88F422a7b43162BB106ce84D33f6252B838f7567
    // HBTC/USDT+F5: 0x545E158aaBAd59fd487eEf7edaA12c776868E83B
    // HBTC/USDT-F1: 0xd4eefB03b110f51FD7E28D728CF24BCA067D77EC
    // HBTC/USDT-F2: 0xA673cc52107c377F2701e7B5dC0aEffAc125a300
    // HBTC/USDT-F5: 0x2aDEb401D16eE0c102a6358Bb15570330Ac49075

    // 1. 部署依赖合约
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x2d750210c0b5343a0b79beff8F054C9add7d2411');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const fortGovernance = await FortGovernance.attach('0xDD61E5604580AfeEe202d533eefE688091b8127e');
    console.log('fortGovernance: ' + fortGovernance.address);

    //const fort = await FortDCU.deploy();
    const fort = await FortDCU.attach('0xDB7b4FdF99eEE8E4Cb8373630c923c51c1275382');
    console.log('fort: ' + fort.address);

    //const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    const fortDAO = await FortDAO.attach('0xe7012078Cfa3E083d3Fe7B79bA4d8913Be48362F');
    console.log('fortDAO: ' + fortDAO.address);

    //const fortEuropeanOption = await upgrades.deployProxy(FortEuropeanOption, [fortGovernance.address], { initializer: 'initialize' });
    const fortEuropeanOption = await FortEuropeanOption.attach('0x5bA7CBD3cC7C3ced0f94FC3CFd331260569E19Ca');
    console.log('fortEuropeanOption: ' + fortEuropeanOption.address);

    //const fortLever = await upgrades.deployProxy(FortLever, [fortGovernance.address], { initializer: 'initialize' });
    const fortLever = await FortLever.attach('0x1820A4c392d71B65C3C32c1a6E8d94A3FB785fae');
    console.log('fortLever: ' + fortLever.address);

    //const fortVaultForStaking = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    const fortVaultForStaking = await FortVaultForStaking.attach('0xF06Ca516B6e11AB7843FB0B1a7eECBf0e57B3B64');
    console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

    // // await fortGovernance.initialize('0x0000000000000000000000000000000000000000');
    // console.log('1. fort.initialize(fortGovernance.address)');
    // await fort.initialize(fortGovernance.address);
    // await fortDAO.initialize(fortGovernance.address);
    // await fortEuropeanOption.initialize(fortGovernance.address);
    // await fortLever.initialize(fortGovernance.address);
    // await fortVaultForStaking.initialize(fortGovernance.address);

    // console.log('2. fortGovernance.setBuiltinAddress()');
    // await fortGovernance.setBuiltinAddress(
    //     fort.address,
    //     fortDAO.address,
    //     fortEuropeanOption.address,
    //     fortLever.address,
    //     fortVaultForStaking.address,
    //     nestPriceFacade.address
    // );

    // console.log('3. fort.update()');
    // await fort.update(fortGovernance.address);
    // console.log('4. fortDAO.update()');
    // await fortDAO.update(fortGovernance.address);
    // console.log('5. fortEuropeanOption.update()');
    // await fortEuropeanOption.update(fortGovernance.address);
    // console.log('6. fortLever.update()');
    // await fortLever.update(fortGovernance.address);
    // console.log('7. fortVaultForStaking.update()');
    // await fortVaultForStaking.update(fortGovernance.address);

    // console.log('8. fortEuropeanOption.setConfig()');
    // await fortEuropeanOption.setConfig(eth.address, { 
    //     sigmaSQ: '4168125400', 
    //     miu: '175482725206', 
    //     minPeriod: 10000 
    // });
    // console.log('8.1. fortEuropeanOption.setConfig()');
    // await fortEuropeanOption.setConfig(hbtc.address, { 
    //     sigmaSQ: '4168125400', 
    //     miu: '175482725206', 
    //     minPeriod: 10000 
    // });

    // console.log('9. fort.setMinter(fortEuropeanOption.address, 1)');
    // await fort.setMinter(fortEuropeanOption.address, 1);
    // console.log('10. fort.setMinter(fortLever.address, 1)');
    // await fort.setMinter(fortLever.address, 1);
    // console.log('11. fort.setMinter(fortVaultForStaking.address, 1)');
    // await fort.setMinter(fortVaultForStaking.address, 1);

    // await fortEuropeanOption.setUsdtTokenAddress(usdt.address);
    // await fortLever.setUsdtTokenAddress(usdt.address);

    // console.log('8.2 create lever');
    // await fortLever.create(eth.address, 1, true);
    // await fortLever.create(eth.address, 2, true);
    // await fortLever.create(eth.address, 5, true);
    // await fortLever.create(eth.address, 1, false);
    // await fortLever.create(eth.address, 2, false);
    // await fortLever.create(eth.address, 5, false);
    // await fortLever.create(hbtc.address, 1, true);
    // await fortLever.create(hbtc.address, 2, true);
    // await fortLever.create(hbtc.address, 5, true);
    // await fortLever.create(hbtc.address, 1, false);
    // await fortLever.create(hbtc.address, 2, false);
    // await fortLever.create(hbtc.address, 5, false);

    // let lot;
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(eth.address, 1, true)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(eth.address, 2, true)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(eth.address, 5, true)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(eth.address, 1, false)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(eth.address, 2, false)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(eth.address, 5, false)); console.log(await lot.name() + ': ' + await lot.address);

    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(hbtc.address, 1, true)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(hbtc.address, 2, true)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(hbtc.address, 5, true)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(hbtc.address, 1, false)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(hbtc.address, 2, false)); console.log(await lot.name() + ': ' + await lot.address);
    // lot = await FortLeverToken.attach(await fortLever.getLeverToken(hbtc.address, 5, false)); console.log(await lot.name() + ': ' + await lot.address);

    console.log('---------- OK ----------');
    
    const contracts = {
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
}