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

    console.log('** Deploy: part2-mainnet@20211013.js **');
    
    // nest     0x04abEdA201850aC0124161F037Efd70c74ddC74C  One months    2000000
    // nhbtc    0x1F832091fAf289Ed4f50FE7418cFbD2611225d46  One months    500000
    // cofi     0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1  One months    500000
    // pusd     0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0  One months    500000
    // fortube  0x1FCdcE58959f536621d76f5b7FfB955baa5A672F  ----    0
    // nest     0x04abEdA201850aC0124161F037Efd70c74ddC74C  Two years     36000000
    // peth     0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD  One months    500000
    // 2021-10-14 12:02


    //     ** Deploy: part2-mainnet@20211013.js **
    // nest: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
    // nhbtc: 0x1F832091fAf289Ed4f50FE7418cFbD2611225d46
    // cofi: 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1
    // pusd: 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0
    // fortube: 0x1FCdcE58959f536621d76f5b7FfB955baa5A672F
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // nestPriceFacade: 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A
    // fortGovernance: 0xfD6dF48df7E0989355B23f200d0D454b9101d17D
    // fortVaultForStaking: 0xE3940A3E94bca34B9175d156a5E9C5728dFE922F
    // proxyAdmin: 0x39016AeAe6F975796BFC007c7aA655fB691Fc6e8

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

    //const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const fortGovernance = await FortGovernance.attach('0xfD6dF48df7E0989355B23f200d0D454b9101d17D');
    console.log('fortGovernance: ' + fortGovernance.address);

    // const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    // //const fortDAO = await FortDAO.attach('0x0000000000000000000000000000000000000000');
    // console.log('fortDAO: ' + fortDAO.address);

    // const fortOptions = await upgrades.deployProxy(FortOptions, [fortGovernance.address], { initializer: 'initialize' });
    // //const fortOptions = await FortOptions.attach('0x0000000000000000000000000000000000000000');
    // console.log('fortOptions: ' + fortOptions.address);

    // const fortFutures = await upgrades.deployProxy(FortFutures, [fortGovernance.address], { initializer: 'initialize' });
    // //const fortFutures = await FortFutures.attach('0x0000000000000000000000000000000000000000');
    // console.log('fortFutures: ' + fortFutures.address);

    //const fortVaultForStaking = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    const fortVaultForStaking = await FortVaultForStaking.attach('0xE3940A3E94bca34B9175d156a5E9C5728dFE922F');
    console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

    // // await fortGovernance.initialize('0x0000000000000000000000000000000000000000');
    // //console.log('1. dcu.initialize(fortGovernance.address)');
    // //await dcu.initialize(fortGovernance.address, { nonce: 9 });
    // // await fortDAO.initialize(fortGovernance.address);
    // // await fortOptions.initialize(fortGovernance.address);
    // // await fortFutures.initialize(fortGovernance.address);
    // // await fortVaultForStaking.initialize(fortGovernance.address);

    // console.log('2. fortGovernance.setBuiltinAddress()');
    // await fortGovernance.setBuiltinAddress(
    //     dcu.address,
    //     '0x0000000000000000000000000000000000000000', //fortDAO.address,
    //     '0x0000000000000000000000000000000000000000', //fortOptions.address,
    //     '0x0000000000000000000000000000000000000000', //fortFutures.address,
    //     fortVaultForStaking.address,
    //     nestPriceFacade.address,
    //     { nonce: 14 }
    // );

    // console.log('3. dcu.update()');
    // await dcu.update(fortGovernance.address, { nonce: 12 });
    // console.log('4. fortDAO.update()');
    // await fortDAO.update(fortGovernance.address);
    // console.log('5. fortOptions.update()');
    // await fortOptions.update(fortGovernance.address);
    // console.log('6. fortFutures.update()');
    //await fortFutures.update(fortGovernance.address);
    // console.log('7. fortVaultForStaking.update()');
    // await fortVaultForStaking.update(fortGovernance.address, { nonce: 12 });

    // console.log('8. fortOptions.setConfig()');
    // await fortOptions.setConfig(eth.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });
    // console.log('8.1. fortOptions.setConfig()');
    // await fortOptions.setConfig(hbtc.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });

    // // console.log('9. dcu.setMinter(fortOptions.address, 1)');
    // // await dcu.setMinter(fortOptions.address, 1);
    // // console.log('10. dcu.setMinter(fortFutures.address, 1)');
    // // await dcu.setMinter(fortFutures.address, 1);
    // console.log('11. dcu.setMinter(fortVaultForStaking.address, 1)');
    // await dcu.setMinter(fortVaultForStaking.address, 1, { nonce: 13 });

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

    // const ONE_MONTH = 200000;
    // // const ONE_YEAR = ONE_MONTH * 12;
    // // const TWO_YEAR = ONE_YEAR * 2;

    // let xtokens = [
    //     fortube.address,
    //     peth.address
    // ];

    // let cycles = [
    //     ONE_MONTH,
    //     ONE_MONTH
    // ];

    // let weights = [
    //     0,
    //     500000
    // ];
    
    // // console.log('9.fortVaultForStaking.setConfig()');
    // // await fortVaultForStaking.setConfig(1000000000000000000n, 13408888, 13458888, { nonce: 14 });

    //console.log('10.fortVaultForStaking.batchSetPoolWeight()');
    //await fortVaultForStaking.batchSetPoolWeight(xtokens, cycles, weights);

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        nest: nest,
        nhbtc: nhbtc,
        cofi: cofi,
        pusd: pusd,
        fortube: fortube,
        peth,

        fortGovernance: fortGovernance,
        dcu: dcu,
        // fortDAO: fortDAO,
        // fortOptions: fortOptions,
        // fortFutures: fortFutures,
        fortVaultForStaking: fortVaultForStaking,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
};