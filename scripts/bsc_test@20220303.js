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
    const FortSwap = await ethers.getContractFactory('FortSwap');

    console.log('** Deploy: bsc_test@20220303.js **');
    
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // pusd: 0x3DA5c9aafc6e6D6839E62e2fB65825869019F291
    // peth: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestLedger: 0x78D5E2fC85969e51580fd2C0Fd6D056a444167cE
    // nestOpenMining: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277

    //     ** Deploy: bsc_test@20211123.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // pusd: 0x3DA5c9aafc6e6D6839E62e2fB65825869019F291
    // peth: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestLedger: 0x78D5E2fC85969e51580fd2C0Fd6D056a444167cE
    // nestOpenMining: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // dcu: 0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb
    // nestPriceFacade: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // fortGovernance: 0x38831FF0d6133D2d45C2eb876602C0249BA601eE
    // fortDAO: 0x81c952c4EEE91DF16A7908E1869a31E438FbCE44
    // fortSwap: 0xc61409835E6A23e31f2fb06F76ae13A1b4c5fD26
    // fortOptions: 0x19465d54ba7c492174127244cc26dE49F0cC1F1f
    // fortFutures: 0xFD42E41B96BC69e8B0763B2Ed75CD50347b9778D
    // proxyAdmin: 0xB5604C3C3AE902513731037B9c7368842582642e

    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc');
    console.log('usdt: ' + usdt.address);

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb');
    console.log('dcu: ' + dcu.address);

    //const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    const nestPriceFacade = await NestPriceFacade.attach('0xF2f9E62f52389EF223f5Fa8b9926e95386935277');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const fortGovernance = await FortGovernance.attach('0x38831FF0d6133D2d45C2eb876602C0249BA601eE');
    console.log('fortGovernance: ' + fortGovernance.address);

    //const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    const fortDAO = await FortDAO.attach('0x81c952c4EEE91DF16A7908E1869a31E438FbCE44');
    console.log('fortDAO: ' + fortDAO.address);

    //const fortOptions = await upgrades.deployProxy(FortOptions, [fortGovernance.address], { initializer: 'initialize' });
    const fortOptions = await FortOptions.attach('0x19465d54ba7c492174127244cc26dE49F0cC1F1f');
    console.log('fortOptions: ' + fortOptions.address);

    //const fortFutures = await upgrades.deployProxy(FortFutures, [fortGovernance.address], { initializer: 'initialize' });
    const fortFutures = await FortFutures.attach('0xFD42E41B96BC69e8B0763B2Ed75CD50347b9778D');
    console.log('fortFutures: ' + fortFutures.address);

    // const fortVaultForStaking = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    // //const fortVaultForStaking = await FortVaultForStaking.attach('0x0000000000000000000000000000000000000000');
    // console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

    //const hedgeSwap = await upgrades.deployProxy(HedgeSwap, [fortGovernance.address], { initializer: 'initialize' });
    const hedgeSwap = await HedgeSwap.attach('0xD83C860d3A27cC5EddaB68EaBFCF9cc8ad38F15D');
    console.log('hedgeSwap: ' + hedgeSwap.address);

    //const fortSwap = await upgrades.deployProxy(FortSwap, [fortGovernance.address], { initializer: 'initialize' });
    const fortSwap = await FortSwap.attach('0xc61409835E6A23e31f2fb06F76ae13A1b4c5fD26');
    console.log('fortSwap: ' + fortSwap.address);

    // // await fortGovernance.initialize('0x0000000000000000000000000000000000000000');
    // console.log('1. dcu.initialize(fortGovernance.address)');
    // await dcu.initialize(fortGovernance.address);
    // // await fortDAO.initialize(fortGovernance.address);
    // // await fortOptions.initialize(fortGovernance.address);
    // // await fortFutures.initialize(fortGovernance.address);
    // // await fortVaultForStaking.initialize(fortGovernance.address);

    // console.log('2. fortGovernance.setBuiltinAddress()');
    // await fortGovernance.setBuiltinAddress(
    //     dcu.address,
    //     fortDAO.address,
    //     fortOptions.address,
    //     fortFutures.address,
    //     '0x0000000000000000000000000000000000000000', //fortVaultForStaking.address,
    //     nestPriceFacade.address
    // );

    // console.log('3. dcu.update()');
    // await dcu.update(fortGovernance.address);
    // console.log('4. fortDAO.update()');
    // await fortDAO.update(fortGovernance.address);
    // console.log('5. fortOptions.update()');
    // await fortOptions.update(fortGovernance.address);
    // console.log('6. fortFutures.update()');
    // await fortFutures.update(fortGovernance.address);
    // // console.log('7. fortVaultForStaking.update()');
    // // await fortVaultForStaking.update(fortGovernance.address);
    // console.log('8. fortVaultForStaking.update()');
    // await hedgeSwap.update(fortGovernance.address);

    // // console.log('8. fortOptions.setConfig()');
    // // await fortOptions.setConfig(eth.address, { 
    // //     sigmaSQ: '45659142400', 
    // //     miu: '467938556917', 
    // //     minPeriod: 6000 
    // // });
    // // console.log('8.1. fortOptions.setConfig()');
    // // await fortOptions.setConfig(hbtc.address, { 
    // //     sigmaSQ: '45659142400', 
    // //     miu: '467938556917', 
    // //     minPeriod: 6000 
    // // });

    // console.log('9. dcu.setMinter(fortOptions.address, 1)');
    // await dcu.setMinter(fortOptions.address, 1);
    // console.log('10. dcu.setMinter(fortFutures.address, 1)');
    // await dcu.setMinter(fortFutures.address, 1);
    // console.log('11. dcu.setMinter(hedgeSwap.address, 1)');
    // await dcu.setMinter(hedgeSwap.address, 1);

    // //await usdt.transfer(usdt.address, 0);
    // //await usdt.transfer(usdt.address, 0);
    // await fortOptions.setUsdtTokenAddress(usdt.address);
    // await fortFutures.setUsdtTokenAddress(usdt.address);

    // console.log('8.2 create lever');
    // await fortFutures.create(eth.address, 1, true);
    // await fortFutures.create(eth.address, 2, true);
    // await fortFutures.create(eth.address, 3, true);
    // await fortFutures.create(eth.address, 4, true);
    // await fortFutures.create(eth.address, 5, true);
    // await fortFutures.create(eth.address, 1, false);
    // await fortFutures.create(eth.address, 2, false);
    // await fortFutures.create(eth.address, 3, false);
    // await fortFutures.create(eth.address, 4, false);
    // await fortFutures.create(eth.address, 5, false);

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        usdt: usdt,
        nest: nest,
        hbtc: hbtc,

        fortGovernance: fortGovernance,
        dcu: dcu,
        fortDAO: fortDAO,
        fortOptions: fortOptions,
        fortFutures: fortFutures,
        //fortVaultForStaking: fortVaultForStaking,
        nestPriceFacade: nestPriceFacade,
        hedgeSwap: hedgeSwap,
        fortSwap: fortSwap,

        BLOCK_TIME: 3
    };

    return contracts;
};