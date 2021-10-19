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

    console.log('** 开始部署合约 part3-mainnet@20211020.js **');
    
    // nest     0x04abEdA201850aC0124161F037Efd70c74ddC74C  一月    2000000
    // nhbtc    0x1F832091fAf289Ed4f50FE7418cFbD2611225d46  一月    500000
    // cofi     0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1  一月    500000
    // pusd     0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0  一月    500000
    // fortube  0x1FCdcE58959f536621d76f5b7FfB955baa5A672F  ----    0
    // nest     0x04abEdA201850aC0124161F037Efd70c74ddC74C  两年    36000000
    // peth     0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD  一月    500000
    // 2021-10-14 12:02


    //     ** 开始部署合约 part3-mainnet@20211020.js **
    // nest: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
    // nhbtc: 0x1F832091fAf289Ed4f50FE7418cFbD2611225d46
    // cofi: 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1
    // pusd: 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0
    // fortube: 0x1FCdcE58959f536621d76f5b7FfB955baa5A672F
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // nestPriceFacade: 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A
    // hedgeGovernance: 0xfD6dF48df7E0989355B23f200d0D454b9101d17D
    // hedgeVaultForStaking: 0xE3940A3E94bca34B9175d156a5E9C5728dFE922F

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
    console.log('nest: ' + nest.address);

    //const nhbtc = await TestERC20.deploy('NHBTC', 'NEST', 18);
    const nhbtc = await TestERC20.attach('0x1F832091fAf289Ed4f50FE7418cFbD2611225d46');
    console.log('nhbtc: ' + nhbtc.address);

    //const cofi = await TestERC20.deploy('COFI', 'COFI', 18);
    const cofi = await TestERC20.attach('0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1');
    console.log('cofi: ' + cofi.address);

    //const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0');
    console.log('pusd: ' + pusd.address);

    //const fortube = await TestERC20.deploy('FORTUBE', 'FORTUBE', 18);
    const fortube = await TestERC20.attach('0x1FCdcE58959f536621d76f5b7FfB955baa5A672F');
    console.log('fortube: ' + fortube.address);

    //const peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD');
    console.log('peth: ' + peth.address);

    // 1. 部署依赖合约
    // //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    // const usdt = await TestERC20.attach('0xdAC17F958D2ee523a2206206994597C13D831ec7');
    // console.log('usdt: ' + usdt.address);

    // //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    // const hbtc = await TestERC20.attach('0x0316EB71485b0Ab14103307bf65a021042c6d380');
    // console.log('hbtc: ' + hbtc.address);

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF');
    console.log('dcu: ' + dcu.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const hedgeGovernance = await upgrades.deployProxy(HedgeGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const hedgeGovernance = await HedgeGovernance.attach('0xfD6dF48df7E0989355B23f200d0D454b9101d17D');
    console.log('hedgeGovernance: ' + hedgeGovernance.address);

    // const hedgeDAO = await upgrades.deployProxy(HedgeDAO, [hedgeGovernance.address], { initializer: 'initialize' });
    // //const hedgeDAO = await HedgeDAO.attach('0x0000000000000000000000000000000000000000');
    // console.log('hedgeDAO: ' + hedgeDAO.address);

    const hedgeOptions = await upgrades.deployProxy(HedgeOptions, [hedgeGovernance.address], { initializer: 'initialize' });
    //const hedgeOptions = await HedgeOptions.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeOptions: ' + hedgeOptions.address);

    const hedgeFutures = await upgrades.deployProxy(HedgeFutures, [hedgeGovernance.address], { initializer: 'initialize' });
    //const hedgeFutures = await HedgeFutures.attach('0x0000000000000000000000000000000000000000');
    console.log('hedgeFutures: ' + hedgeFutures.address);

    //const hedgeVaultForStaking = await upgrades.deployProxy(HedgeVaultForStaking, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeVaultForStaking = await HedgeVaultForStaking.attach('0xE3940A3E94bca34B9175d156a5E9C5728dFE922F');
    console.log('hedgeVaultForStaking: ' + hedgeVaultForStaking.address);

    // // await hedgeGovernance.initialize('0x0000000000000000000000000000000000000000');
    // //console.log('1. dcu.initialize(hedgeGovernance.address)');
    // //await dcu.initialize(hedgeGovernance.address, { nonce: 9 });
    // // await hedgeDAO.initialize(hedgeGovernance.address);
    // // await hedgeOptions.initialize(hedgeGovernance.address);
    // // await hedgeFutures.initialize(hedgeGovernance.address);
    // // await hedgeVaultForStaking.initialize(hedgeGovernance.address);

    console.log('2. hedgeGovernance.setBuiltinAddress()');
    await hedgeGovernance.setBuiltinAddress(
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000', //hedgeDAO.address,
        hedgeOptions.address, //hedgeOptions.address,
        hedgeFutures.address, //hedgeFutures.address,
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000'
    );

    // console.log('3. dcu.update()');
    // await dcu.update(hedgeGovernance.address, { nonce: 12 });
    // console.log('4. hedgeDAO.update()');
    // await hedgeDAO.update(hedgeGovernance.address);
    console.log('5. hedgeOptions.update()');
    await hedgeOptions.update(hedgeGovernance.address);
    console.log('6. hedgeFutures.update()');
    await hedgeFutures.update(hedgeGovernance.address);
    // console.log('7. hedgeVaultForStaking.update()');
    // await hedgeVaultForStaking.update(hedgeGovernance.address, { nonce: 12 });

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

    // TODO: 2021-10-20 15:30执行
    // console.log('9. dcu.setMinter(hedgeOptions.address, 1)');
    // await dcu.setMinter(hedgeOptions.address, 1);
    // console.log('10. dcu.setMinter(hedgeFutures.address, 1)');
    // await dcu.setMinter(hedgeFutures.address, 1);

    // console.log('11. dcu.setMinter(hedgeVaultForStaking.address, 1)');
    // await dcu.setMinter(hedgeVaultForStaking.address, 1, { nonce: 13 });

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        nest: nest,
        nhbtc: nhbtc,
        cofi: cofi,
        pusd: pusd,
        fortube: fortube,
        peth,

        hedgeGovernance: hedgeGovernance,
        dcu: dcu,
        // hedgeDAO: hedgeDAO,
        // hedgeOptions: hedgeOptions,
        // hedgeFutures: hedgeFutures,
        hedgeVaultForStaking: hedgeVaultForStaking,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
};