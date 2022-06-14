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

    console.log('** Deploy: part3-mainnet@20211020.js **');
    
    // nest     0x04abEdA201850aC0124161F037Efd70c74ddC74C  One months    2000000
    // nhbtc    0x1F832091fAf289Ed4f50FE7418cFbD2611225d46  One months    500000
    // cofi     0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1  One months    500000
    // pusd     0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0  One months    500000
    // fortube  0x1FCdcE58959f536621d76f5b7FfB955baa5A672F  ----    0
    // nest     0x04abEdA201850aC0124161F037Efd70c74ddC74C  Two years     36000000
    // peth     0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD  One months    500000
    // 2021-10-14 12:02

    // ** Deploy: part3-mainnet@20211020.js **
    // nest: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
    // nhbtc: 0x1F832091fAf289Ed4f50FE7418cFbD2611225d46
    // cofi: 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1
    // pusd: 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0
    // fortube: 0x1FCdcE58959f536621d76f5b7FfB955baa5A672F
    // peth: 0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // nestPriceFacade: 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A
    // fortGovernance: 0xfD6dF48df7E0989355B23f200d0D454b9101d17D
    // fortOptions: 0x6C844d364c2836f2111891111F25C7a24da976A9
    // fortFutures: 0x622f1CB39AdE2131061C68E61334D41321033ab4
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

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF');
    console.log('dcu: ' + dcu.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const fortGovernance = await FortGovernance.attach('0xfD6dF48df7E0989355B23f200d0D454b9101d17D');
    console.log('fortGovernance: ' + fortGovernance.address);

    //const fortOptions = await upgrades.deployProxy(FortOptions, [fortGovernance.address], { initializer: 'initialize' });
    const fortOptions = await FortOptions.attach('0x6C844d364c2836f2111891111F25C7a24da976A9');
    console.log('fortOptions: ' + fortOptions.address);

    //const fortFutures = await upgrades.deployProxy(FortFutures, [fortGovernance.address], { initializer: 'initialize' });
    const fortFutures = await FortFutures.attach('0x622f1CB39AdE2131061C68E61334D41321033ab4');
    console.log('fortFutures: ' + fortFutures.address);

    //const fortVaultForStaking = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    const fortVaultForStaking = await FortVaultForStaking.attach('0xE3940A3E94bca34B9175d156a5E9C5728dFE922F');
    console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

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