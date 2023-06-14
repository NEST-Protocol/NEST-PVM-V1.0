// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const CommonGovernance = await ethers.getContractFactory('CommonGovernance');
    const CommonProxy = await ethers.getContractFactory('CommonProxy');
    const NestToken = await ethers.getContractFactory('NestToken');
    const NestFutures4V5 = await ethers.getContractFactory('NestFutures4V5');
    const NestCraft = await ethers.getContractFactory('NestCraftSmart');
    const PancakeFactory = await ethers.getContractFactory('PancakeFactory');
    const PancakeRouter = await ethers.getContractFactory('PancakeRouter');

    const deployProxy = async function(artifact, args) {
        const target = await artifact.deploy(args);
        const proxy = await CommonProxy.deploy(target.address);
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

    console.log('** Deploy: deploy.proxy.js **');
    
    const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const nest = await NestToken.deploy();
    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);

    const commonGovernance = await CommonGovernance.deploy();
    //const commonGovernance = await CommonGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('commonGovernance: ' + commonGovernance.address);

    const nestFutures4V5 = await deployProxy(NestFutures4V5, []);
    //const nestFutures4V5 = await NestFutures4V5.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures4V5: ' + nestFutures4V5.address);

    const nestCraft = await deployProxy(NestCraft, []);
    //const nestCraft = await NestCraft.attach('0x0000000000000000000000000000000000000000');
    console.log('nestCraft: ' + nestCraft.address);

    await nestFutures4V5.setGovernance(commonGovernance.address);

    // -------- TEST --------
    const pancakeFactory = await PancakeFactory.deploy('0x0000000000000000000000000000000000000000');
    console.log('pancakeFactory: ' + pancakeFactory.address);

    const pancakeRouter = await PancakeRouter.deploy(pancakeFactory.address, '0x0000000000000000000000000000000000000000');
    console.log('pancakeRouter: ' + pancakeRouter.address);

    await pancakeFactory.createPair(usdt.address, nest.address);

    // -------- TEST --------

    await commonGovernance.registerAddress('nest.app.directPoster', (await ethers.getSigners())[0].address)
    await commonGovernance.registerAddress('nest.app.nest', nest.address);
    await commonGovernance.registerAddress('pancake.app.router', pancakeRouter.address);
    await commonGovernance.registerAddress('pancake.pair.nestusdt', await pancakeFactory.getPair(usdt.address, nest.address));
    await commonGovernance.registerAddress('common.token.usdt', usdt.address);

    console.log('7. nestFutures4V5.update()');
    //await nestFutures4V5.update(commonGovernance.address);
    await commonGovernance.execute(nestFutures4V5.address, getCalldata('update', ['address'], [commonGovernance.address]));
    await commonGovernance.execute(nestCraft.address, getCalldata('update', ['address'], [commonGovernance.address]));

    await nestCraft.register('PI', 3141592653590000000n | (1n << 248n));
    await nestCraft.register('E',  2718281828459000000n | (1n << 248n));
    await nestCraft.registerAddress('P0', nestCraft.address);
    await nestCraft.registerAddress('P1', nestCraft.address);
    await nestCraft.registerAddress('P2', nestCraft.address);

    console.log('8. mint');
    await nest.mintTo(nestFutures4V5.address, 100000000000000000000000000n);
    await nest.approve(nestFutures4V5.address, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 1;

    const contracts = {
        eth: eth,
        usdt: usdt,
        nest: nest,

        commonGovernance: commonGovernance,
        nestFutures4V5: nestFutures4V5,
        pancakeFactory: pancakeFactory,
        pancakeRouter: pancakeRouter,
        nestCraft: nestCraft,

        BLOCK_TIME: BLOCK_TIME,
        USDT_DECIMALS: 18,

        miuT: function(orientation, blocks) {
            return Math.exp((orientation ? MIU_LONG : MIU_SHORT) * blocks * BLOCK_TIME);
        }
    };

    return contracts;
};