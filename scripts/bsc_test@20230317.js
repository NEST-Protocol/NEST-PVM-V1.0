// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestVault = await ethers.getContractFactory('NestVault');
    const NestTrustFuturesV3 = await ethers.getContractFactory('NestTrustFuturesV3');
    const PancakeFactory = await ethers.getContractFactory('PancakeFactory');
    const PancakeRouter = await ethers.getContractFactory('PancakeRouter');

    console.log('** Deploy: bsc_test@20230317.js **');
    
    // ** Deploy: bsc_test@20230317.js **
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestTrustFuturesV3: 0xE8b787EdE23997Ff5C64067e2220FBbd13b085A1
    // pancakeFactory: 0x1D743a4a2313cf59083aFA48Aed90F815Fc073DC
    // pancakeRouter: 0x7E9747Dd4a7390FCA7D86A400D14F031981Bc1E1
    // nestUsdtPair: 0xF55D681c2D64310e2196E55562c402effCfe2E5E
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc');
    console.log('usdt: ' + usdt.address);

    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x5691dc0770D55B9469a3242DA282754687687935');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestVault = await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0x0649A02C15229Cb970CDcE456f9dd52248023520');
    console.log('nestVault: ' + nestVault.address);

    //const nestTrustFuturesV3 = await upgrades.deployProxy(NestTrustFuturesV3, [nestGovernance.address], { initializer: 'initialize' });
    const nestTrustFuturesV3 = await NestTrustFuturesV3.attach('0xE8b787EdE23997Ff5C64067e2220FBbd13b085A1');
    console.log('nestTrustFuturesV3: ' + nestTrustFuturesV3.address);

    // -------- TEST --------
    //const pancakeFactory = await PancakeFactory.deploy('0x0000000000000000000000000000000000000000');
    const pancakeFactory = await PancakeFactory.attach('0x1D743a4a2313cf59083aFA48Aed90F815Fc073DC');
    console.log('pancakeFactory: ' + pancakeFactory.address);
    
    //const pancakeRouter = await PancakeRouter.deploy(pancakeFactory.address, '0x0000000000000000000000000000000000000000');
    const pancakeRouter = await PancakeRouter.attach('0x7E9747Dd4a7390FCA7D86A400D14F031981Bc1E1');
    console.log('pancakeRouter: ' + pancakeRouter.address);
    
    //await pancakeFactory.createPair(usdt.address, nest.address);
    const nestUsdtPairAddress = await pancakeFactory.getPair(usdt.address, nest.address);
    console.log('nestUsdtPair: ' + nestUsdtPairAddress);

    // await nestGovernance.registerAddress('pancake.app.router', pancakeRouter.address);
    // await nestGovernance.registerAddress('pancake.pair.nestusdt', nestUsdtPairAddress);
    // await nestGovernance.registerAddress('common.token.usdt', usdt.address);
    // await nestGovernance.registerAddress('pancake.app.router', pancakeRouter.address);

    // console.log('nest: ' + await nestGovernance.getNestTokenAddress());
    // console.log('nest.v4.openPrice: ' + await nestGovernance.checkAddress("nest.v4.openPrice"));
    // console.log('nest.app.vault: ' + await nestGovernance.checkAddress("nest.app.vault"));
    // console.log('nest.app.directPoster: ' + await nestGovernance.checkAddress("nest.app.directPoster"));
    // console.log('nest.app.maintains: ' + await nestGovernance.checkAddress("nest.app.maintains"));
    // console.log('pancake.pair.nestusdt: ' + await nestGovernance.checkAddress("pancake.pair.nestusdt"));
    // console.log('common.token.usdt: ' + await nestGovernance.checkAddress("common.token.usdt"));

    const newNestTrustFuturesV3 = await NestTrustFuturesV3.deploy();
    console.log('newNestTrustFuturesV3: ' + newNestTrustFuturesV3.address);

    //await usdt.approve(pancakeRouter.address, 1000000000000000000000000n);
    //await nest.approve(pancakeRouter.address, 1000000000000000000000000n);
    // await pancakeRouter.addLiquidity(
    //     usdt.address,
    //     nest.address,
    //     10000000000000000000000n,
    //     500000000000000000000000n,
    //     0,
    //     0,
    //     '0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4',
    //     100000000000n
    // );
    //await usdt.approve(nestTrustFuturesV3.address, 1000000000000000000000000n);
    // await pancakeRouter.swapExactTokensForTokens(
    //     100000000000000000000n,
    //     1000000000000000000000n,
    //     [usdt.address, nest.address],
    //     '0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4',
    //     100000000000n
    // );

    /*
    // ** Deploy: bsc_test@20230227.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestTrustFuturesV3: 0xE8b787EdE23997Ff5C64067e2220FBbd13b085A1
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

    已经在bsc测试网上部署了最新版本的期货合约，动态μ算法，看涨和看跌的Pt分别计算，详情见最新版本算法文档，除getChannelInfo()接口
    返回的数据结构有针对性的做了调整外（添加了PtL和PtS），其他接口签名不变。
    
    开发和测试请连接到最新版本的合约。*/
    
    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        nest: nest,

        nestGovernance: nestGovernance,
        nestVault: nestVault,
        nestTrustFuturesV3: nestTrustFuturesV3,

        BLOCK_TIME: BLOCK_TIME,
        USDT_DECIMALS: 18,

        MIU_LONG: MIU_LONG,
        MIU_SHORT: MIU_SHORT,
        miuT: function(orientation, blocks) {
            return Math.exp((orientation ? MIU_LONG : MIU_SHORT) * blocks * BLOCK_TIME);
        }
    };

    return contracts;
};