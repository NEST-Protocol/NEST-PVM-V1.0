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
    // hedgeGovernance: 0xDD61E5604580AfeEe202d533eefE688091b8127e
    // dcu: 0xDB7b4FdF99eEE8E4Cb8373630c923c51c1275382
    // hedgeDAO: 0xe7012078Cfa3E083d3Fe7B79bA4d8913Be48362F
    // hedgeOptions: 0x5bA7CBD3cC7C3ced0f94FC3CFd331260569E19Ca
    // hedgeFutures: 0x1820A4c392d71B65C3C32c1a6E8d94A3FB785fae
    // hedgeVaultForStaking: 0xF06Ca516B6e11AB7843FB0B1a7eECBf0e57B3B64
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

    //const hedgeGovernance = await upgrades.deployProxy(HedgeGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const hedgeGovernance = await HedgeGovernance.attach('0xDD61E5604580AfeEe202d533eefE688091b8127e');
    console.log('hedgeGovernance: ' + hedgeGovernance.address);

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xDB7b4FdF99eEE8E4Cb8373630c923c51c1275382');
    console.log('dcu: ' + dcu.address);

    //const hedgeDAO = await upgrades.deployProxy(HedgeDAO, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeDAO = await HedgeDAO.attach('0xe7012078Cfa3E083d3Fe7B79bA4d8913Be48362F');
    console.log('hedgeDAO: ' + hedgeDAO.address);

    //const hedgeOptions = await upgrades.deployProxy(HedgeOptions, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeOptions = await HedgeOptions.attach('0x5bA7CBD3cC7C3ced0f94FC3CFd331260569E19Ca');
    console.log('hedgeOptions: ' + hedgeOptions.address);

    //const hedgeFutures = await upgrades.deployProxy(HedgeFutures, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeFutures = await HedgeFutures.attach('0x1820A4c392d71B65C3C32c1a6E8d94A3FB785fae');
    console.log('hedgeFutures: ' + hedgeFutures.address);

    //const hedgeVaultForStaking = await upgrades.deployProxy(HedgeVaultForStaking, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeVaultForStaking = await HedgeVaultForStaking.attach('0xF06Ca516B6e11AB7843FB0B1a7eECBf0e57B3B64');
    console.log('hedgeVaultForStaking: ' + hedgeVaultForStaking.address);

    // // await hedgeGovernance.initialize('0x0000000000000000000000000000000000000000');
    // console.log('1. dcu.initialize(hedgeGovernance.address)');
    // await dcu.initialize(hedgeGovernance.address);
    // await hedgeDAO.initialize(hedgeGovernance.address);
    // await hedgeOptions.initialize(hedgeGovernance.address);
    // await hedgeFutures.initialize(hedgeGovernance.address);
    // await hedgeVaultForStaking.initialize(hedgeGovernance.address);

    // console.log('2. hedgeGovernance.setBuiltinAddress()');
    // await hedgeGovernance.setBuiltinAddress(
    //     dcu.address,
    //     hedgeDAO.address,
    //     hedgeOptions.address,
    //     hedgeFutures.address,
    //     hedgeVaultForStaking.address,
    //     nestPriceFacade.address
    // );

    // console.log('3. dcu.update()');
    // await dcu.update(hedgeGovernance.address);
    // console.log('4. hedgeDAO.update()');
    // await hedgeDAO.update(hedgeGovernance.address);
    // console.log('5. hedgeOptions.update()');
    // await hedgeOptions.update(hedgeGovernance.address);
    // console.log('6. hedgeFutures.update()');
    // await hedgeFutures.update(hedgeGovernance.address);
    // console.log('7. hedgeVaultForStaking.update()');
    // await hedgeVaultForStaking.update(hedgeGovernance.address);

    // console.log('8. hedgeOptions.setConfig()');
    // await hedgeOptions.setConfig(eth.address, { 
    //     sigmaSQ: '4168125400', 
    //     miu: '175482725206', 
    //     minPeriod: 10000 
    // });
    // console.log('8.1. hedgeOptions.setConfig()');
    // await hedgeOptions.setConfig(hbtc.address, { 
    //     sigmaSQ: '4168125400', 
    //     miu: '175482725206', 
    //     minPeriod: 10000 
    // });

    // console.log('9. dcu.setMinter(hedgeOptions.address, 1)');
    // await dcu.setMinter(hedgeOptions.address, 1);
    // console.log('10. dcu.setMinter(hedgeFutures.address, 1)');
    // await dcu.setMinter(hedgeFutures.address, 1);
    // console.log('11. dcu.setMinter(hedgeVaultForStaking.address, 1)');
    // await dcu.setMinter(hedgeVaultForStaking.address, 1);

    // await hedgeOptions.setUsdtTokenAddress(usdt.address);
    // await hedgeFutures.setUsdtTokenAddress(usdt.address);

    // console.log('8.2 create lever');
    // await hedgeFutures.create(eth.address, 1, true);
    // await hedgeFutures.create(eth.address, 2, true);
    // await hedgeFutures.create(eth.address, 5, true);
    // await hedgeFutures.create(eth.address, 1, false);
    // await hedgeFutures.create(eth.address, 2, false);
    // await hedgeFutures.create(eth.address, 5, false);
    // await hedgeFutures.create(hbtc.address, 1, true);
    // await hedgeFutures.create(hbtc.address, 2, true);
    // await hedgeFutures.create(hbtc.address, 5, true);
    // await hedgeFutures.create(hbtc.address, 1, false);
    // await hedgeFutures.create(hbtc.address, 2, false);
    // await hedgeFutures.create(hbtc.address, 5, false);

    console.log('---------- OK ----------');
    
    const contracts = {
        usdt: usdt,
        hbtc: hbtc,

        hedgeGovernance: hedgeGovernance,
        dcu: dcu,
        hedgeDAO: hedgeDAO,
        hedgeOptions: hedgeOptions,
        hedgeFutures: hedgeFutures,
        hedgeVaultForStaking: hedgeVaultForStaking,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
}