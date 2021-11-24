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

    console.log('** 开始部署合约 bsc_test@20211123.js **');
    
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // pusd: 0x3DA5c9aafc6e6D6839E62e2fB65825869019F291
    // peth: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestLedger: 0x78D5E2fC85969e51580fd2C0Fd6D056a444167cE
    // nestOpenMining: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277

    //     ** 开始部署合约 bsc_test@20211123.js **
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // dcu: 0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb
    // nestPriceFacade: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // hedgeGovernance: 0x38831FF0d6133D2d45C2eb876602C0249BA601eE
    // hedgeDAO: 0x81c952c4EEE91DF16A7908E1869a31E438FbCE44
    // hedgeOptions: 0x19465d54ba7c492174127244cc26dE49F0cC1F1f
    // hedgeFutures: 0xFD42E41B96BC69e8B0763B2Ed75CD50347b9778D
    // hedgeSwap: 0xD83C860d3A27cC5EddaB68EaBFCF9cc8ad38F15D

    // 1. 部署依赖合约
    const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const dcu = await DCU.deploy();
    //const dcu = await DCU.attach('0x0000000000000000000000000000000000000000');
    console.log('dcu: ' + dcu.address);

    //const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    const nestPriceFacade = await NestPriceFacade.attach('0xF2f9E62f52389EF223f5Fa8b9926e95386935277');
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

    // const hedgeVaultForStaking = await upgrades.deployProxy(HedgeVaultForStaking, [hedgeGovernance.address], { initializer: 'initialize' });
    // //const hedgeVaultForStaking = await HedgeVaultForStaking.attach('0x0000000000000000000000000000000000000000');
    // console.log('hedgeVaultForStaking: ' + hedgeVaultForStaking.address);

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
        '0x0000000000000000000000000000000000000000', //hedgeVaultForStaking.address,
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
    // console.log('7. hedgeVaultForStaking.update()');
    // await hedgeVaultForStaking.update(hedgeGovernance.address);
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
    console.log('11. dcu.setMinter(hedgeSwap.address, 1)');
    await dcu.setMinter(hedgeSwap.address, 1);

    //await usdt.transfer(usdt.address, 0);
    //await usdt.transfer(usdt.address, 0);
    await hedgeOptions.setUsdtTokenAddress(usdt.address);
    await hedgeFutures.setUsdtTokenAddress(usdt.address);

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
    
    const contracts = {
        eth: eth,
        usdt: usdt,
        //hbtc: hbtc,

        hedgeGovernance: hedgeGovernance,
        dcu: dcu,
        hedgeDAO: hedgeDAO,
        hedgeOptions: hedgeOptions,
        hedgeFutures: hedgeFutures,
        //hedgeVaultForStaking: hedgeVaultForStaking,
        nestPriceFacade: nestPriceFacade,
        hedgeSwap: hedgeSwap,

        BLOCK_TIME: 3
    };

    return contracts;
};