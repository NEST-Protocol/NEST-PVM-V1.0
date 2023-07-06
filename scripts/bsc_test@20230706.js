// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestTokenNew = await ethers.getContractFactory('NestTokenNew');
    const CommonProxy = await ethers.getContractFactory('CommonProxy');
    const CommonGovernance = await ethers.getContractFactory('CommonGovernance');
    const NestCraftSimple = await ethers.getContractFactory('NestCraftSimple');
    const NestSwitch = await ethers.getContractFactory('NestSwitch');

    console.log('** Deploy: bsc_test@20230706.js **');
    
    // ** Deploy: bsc_test@20230706.js **
    // nest_old: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nest: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // commonGovernance: 0xb75947547dD02318692A0127e9c3f80F2c35ed0d
    // nestCraft: 0x06F86C308123e029ab80aCA18862Acfab52C47D8
    // nestSwitch: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

    const deployProxy = async function(artifact, args, targetAddress) {
        if (!targetAddress) {
            const target = await artifact.deploy(args);
            targetAddress = target.address;
        }
        const proxy = await CommonProxy.deploy(targetAddress);
        return artifact.attach(proxy.address);
    };

    const getCalldata = function(methodName, argumentTypes, args) {
        // let fullMethodName = 'function ' + methodName + '(' + argumentTypes.join(',') + ') external';
        // //console.log(fullMethodName);
        // const calldata0 = new ethers.utils.Interface([fullMethodName]).encodeFunctionData(methodName, args);
        // //console.log('calldata0: ' + calldata0);
        
        let method = methodName + '(' + argumentTypes.join(',') + ')';
        //console.log(method);
        const signatureData = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(method)).substring(0, 10);
        const argumentData = ethers.utils.defaultAbiCoder.encode(argumentTypes, args).substring(2);
        const calldata1 = signatureData + argumentData;
        //console.log('calldata1: ' + calldata1);

        return calldata1;
    };

    const nest_old = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest_old: ' + nest_old.address);

    //const nest = await NestTokenNew.deploy();
    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await NestTokenNew.attach('0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0');
    console.log('nest: ' + nest.address);

    //const commonGovernance = await CommonGovernance.deploy();
    const commonGovernance = await CommonGovernance.attach('0xb75947547dD02318692A0127e9c3f80F2c35ed0d');
    console.log('commonGovernance: ' + commonGovernance.address);

    //const nestCraft = await deployProxy(NestCraftSimple, []);
    const nestCraft = await NestCraftSimple.attach('0x06F86C308123e029ab80aCA18862Acfab52C47D8');
    console.log('nestCraft: ' + nestCraft.address);

    //const nestSwitch = await deployProxy(NestSwitch, []);
    const nestSwitch = await NestSwitch.attach('0xB64825a6bA80d65886b5123f5170ddffc935D9DE');
    console.log('nestSwitch: ' + nestSwitch.address);

    // await commonGovernance.registerAddress('nest.app.nest.old', nest_old.address);
    // await commonGovernance.registerAddress('nest.app.nest', nest.address);

    //await commonGovernance.execute(nestCraft.address, getCalldata('update', ['address'], [commonGovernance.address]));
    //await nestSwitch.update(commonGovernance.address);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        nest_old: nest_old,
        nest: nest,

        commonGovernance: commonGovernance,
        nestCraft: nestCraft,
        nestSwitch: nestSwitch,

        BLOCK_TIME: BLOCK_TIME,
        USDT_DECIMALS: 18,

        MIU_LONG: MIU_LONG,
        MIU_SHORT: MIU_SHORT,
        miuT: function(orientation, blocks) {
            return Math.exp((orientation ? MIU_LONG : MIU_SHORT) * blocks * BLOCK_TIME);
        }
    };

/*
** Deploy: bsc_test@20230706.js **
nest_old: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
nest: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
commonGovernance: 0xb75947547dD02318692A0127e9c3f80F2c35ed0d
nestSwitch: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE

NEST换币合约已经部署，可以通过nestSwitch合约将之前的NEST换成新的NEST，流程如下：
1. 用户通过nestSwitch.switchOld()接口将旧币存入转换合约，合约记录下用户存入的旧NEST数量
2. 后台定期扫描存入交易，获取存入用户列表
3. 将存入用户列表和黑名单匹配，剔除黑名单地址，生成放行列表
4. 使用管理权限根据放行列表生成merkle树，将树根更新到转换合约，对列表用户放行
5. 在放行列表中的用户，可以通过nestSwitch.withdrawNew()接口按照之前存入的旧NEST数量1:1取回新NEST

注意：
1. 转换操作只允许外部地址，不允许合约地址
2. 放行列表可以分多批进行
*/

    return contracts;
};