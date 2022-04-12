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
    const HedgeOptions = await ethers.getContractFactory('FortOptions');
    const HedgeFutures = await ethers.getContractFactory('FortFutures');
    const FortLPGuarantee = await ethers.getContractFactory('FortLPGuarantee');
    const FortPRC = await ethers.getContractFactory('FortPRCExt');
    const HedgeVaultForStaking = await ethers.getContractFactory('HedgeVaultForStaking');
    const HedgeSwap = await ethers.getContractFactory('HedgeSwap');
    const FortSwap = await ethers.getContractFactory('FortSwap');
    const FortPRCSwap = await ethers.getContractFactory('FortPRCSwap');

    console.log('** Deploy: bsc_test@20220412.js **');
    
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // pusd: 0x3DA5c9aafc6e6D6839E62e2fB65825869019F291
    // peth: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestLedger: 0x78D5E2fC85969e51580fd2C0Fd6D056a444167cE
    // nestOpenMining: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277

    // ** Deploy: bsc_test@20220412.js **
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // dcu: 0x5Df87aE415206707fd52aDa20a5Eac2Ec70e8dbb
    // nestPriceFacade: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // hedgeGovernance: 0x38831FF0d6133D2d45C2eb876602C0249BA601eE
    // hedgeDAO: 0x81c952c4EEE91DF16A7908E1869a31E438FbCE44
    // hedgeOptions: 0x19465d54ba7c492174127244cc26dE49F0cC1F1f
    // hedgeFutures: 0xFD42E41B96BC69e8B0763B2Ed75CD50347b9778D
    // fortLPGuarantee: 0x1e148a04D29e11dd988Ada81B49108Ad09364444
    // fortPRC: 0x6c0cC0e354c12B7c0aceCC45424e9Ee1334bda24
    // hedgeSwap: 0xD83C860d3A27cC5EddaB68EaBFCF9cc8ad38F15D
    // fortSwap: 0xc61409835E6A23e31f2fb06F76ae13A1b4c5fD26
    // fortPRCSwap: 0xb035E907cF84472af91b69eBa1fB7E4eeCF6D3F6

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

    //const hedgeGovernance = await upgrades.deployProxy(HedgeGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const hedgeGovernance = await HedgeGovernance.attach('0x38831FF0d6133D2d45C2eb876602C0249BA601eE');
    console.log('hedgeGovernance: ' + hedgeGovernance.address);

    //const hedgeDAO = await upgrades.deployProxy(HedgeDAO, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeDAO = await HedgeDAO.attach('0x81c952c4EEE91DF16A7908E1869a31E438FbCE44');
    console.log('hedgeDAO: ' + hedgeDAO.address);

    //const hedgeOptions = await upgrades.deployProxy(HedgeOptions, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeOptions = await HedgeOptions.attach('0x19465d54ba7c492174127244cc26dE49F0cC1F1f');
    console.log('hedgeOptions: ' + hedgeOptions.address);

    //const hedgeFutures = await upgrades.deployProxy(HedgeFutures, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeFutures = await HedgeFutures.attach('0xFD42E41B96BC69e8B0763B2Ed75CD50347b9778D');
    console.log('hedgeFutures: ' + hedgeFutures.address);

    //const fortLPGuarantee = await upgrades.deployProxy(FortLPGuarantee, [hedgeGovernance.address], { initializer: 'initialize' });
    const fortLPGuarantee = await FortLPGuarantee.attach('0x1e148a04D29e11dd988Ada81B49108Ad09364444');
    console.log('fortLPGuarantee: ' + fortLPGuarantee.address);

    //const fortPRC = await upgrades.deployProxy(FortPRC, [hedgeGovernance.address], { initializer: 'initialize' });
    const fortPRC = await FortPRC.attach('0x6c0cC0e354c12B7c0aceCC45424e9Ee1334bda24');
    console.log('fortPRC: ' + fortPRC.address);

    //const hedgeSwap = await upgrades.deployProxy(HedgeSwap, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeSwap = await HedgeSwap.attach('0xD83C860d3A27cC5EddaB68EaBFCF9cc8ad38F15D');
    console.log('hedgeSwap: ' + hedgeSwap.address);

    //const fortSwap = await upgrades.deployProxy(FortSwap, [hedgeGovernance.address], { initializer: 'initialize' });
    const fortSwap = await FortSwap.attach('0xc61409835E6A23e31f2fb06F76ae13A1b4c5fD26');
    console.log('fortSwap: ' + fortSwap.address);

    //const fortPRCSwap = await upgrades.deployProxy(FortPRCSwap, [hedgeGovernance.address], { initializer: 'initialize' });
    const fortPRCSwap = await FortPRCSwap.attach('0xb035E907cF84472af91b69eBa1fB7E4eeCF6D3F6');
    console.log('fortPRCSwap: ' + fortPRCSwap.address);
    
    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        usdt: usdt,
        nest: nest,
        hbtc: hbtc,

        hedgeGovernance: hedgeGovernance,
        dcu: dcu,
        hedgeDAO: hedgeDAO,
        hedgeOptions: hedgeOptions,
        hedgeFutures: hedgeFutures,
        fortLPGuarantee: fortLPGuarantee,
        nestPriceFacade: nestPriceFacade,
        hedgeSwap: hedgeSwap,
        fortSwap: fortSwap,

        BLOCK_TIME: 3
    };

    return contracts;
};