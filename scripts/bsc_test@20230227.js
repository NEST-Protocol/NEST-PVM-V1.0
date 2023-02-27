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

    console.log('** Deploy: bsc_test@20230227.js **');
    
    // ** Deploy: bsc_test@20230227.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestTrustFuturesV3: 0xE8b787EdE23997Ff5C64067e2220FBbd13b085A1
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

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

    // await nestGovernance.registerAddress('nest.app.vault', nestVault.address);
    // await nestGovernance.registerAddress('nest.app.futures', nestTrustFutures.address);
    // await nestGovernance.registerAddress('nest.app.directPoster', (await ethers.getSigners())[0].address)
    // await nestGovernance.registerAddress('nest.app.maintains', (await ethers.getSigners())[0].address);

    // console.log('1. nestTrustFuturesV3.update()');
    // await nestTrustFuturesV3.update(nestGovernance.address);

    // await nestTrustFutures.openChannel(0);
    // await nestTrustFutures.openChannel(1);
    // await nestTrustFutures.openChannel(2);

    // await nestVault.approve(nestTrustFuturesV3.address, 100000000000000000000000000n);
    // await nest.approve(nestTrustFuturesV3.address, 100000000000000000000000000n);

    /*
    // ** Deploy: bsc_test@20230227.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestTrustFuturesV3: 0xE8b787EdE23997Ff5C64067e2220FBbd13b085A1
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

    已经在bsc测试网上部署了最新版本的期货合约，动态μ算法，看涨和看跌的Pt分别计算，详情见最新版本算法文档，除getChannelInfo()接口
    返回的数据结构有针对性的做了调整外（添加了PtL和PtS），其他接口签名不变。
    
    开发和测试请连接到最新版本的合约。
    
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