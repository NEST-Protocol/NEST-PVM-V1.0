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
    const NestTokenNew = await ethers.getContractFactory('NestTokenNew');
    const NestFutures4V5 = await ethers.getContractFactory('NestFutures4V5');
    const NestFutures5V1 = await ethers.getContractFactory('NestFutures5V1');
    const NestCraft = await ethers.getContractFactory('NestCraftSmart');
    const NestCraftSimple = await ethers.getContractFactory('NestCraftSimple');
    const NestSwitch = await ethers.getContractFactory('NestSwitch');
    const PancakeFactory = await ethers.getContractFactory('PancakeFactory');
    const PancakeRouter = await ethers.getContractFactory('PancakeRouter');

    const deployProxy = async function(artifact, args, targetAddress) {
        if (!targetAddress) {
            let target;
            if (args.length == 0) { target = await artifact.deploy(); } else 
            if (args.length == 1) { target = await artifact.deploy(args[0]); } else 
            if (args.length == 2) { target = await artifact.deploy(args[0], args[1]); } else 
            if (args.length == 3) { target = await artifact.deploy(args[0], args[1], args[2]); } else 
            if (args.length == 4) { target = await artifact.deploy(args[0], args[1], args[2], args[3]); } else 
            if (args.length == 5) { target = await artifact.deploy(args[0], args[1], args[2], args[3], args[4]); } else 
            if (args.length == 6) { target = await artifact.deploy(args[0], args[1], args[2], args[3], args[4], args[5]); } else 
            if (args.length == 7) { target = await artifact.deploy(args[0], args[1], args[2], args[3], args[4], args[5], args[6]); } else 
            if (args.length == 8) { target = await artifact.deploy(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]); } else 
            if (args.length == 9) { target = await artifact.deploy(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8]); } else 
            { throw new Error('too many arguments'); }

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

    console.log('** Deploy: deploy.proxy.js **');
    
    const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const nest_old = await NestToken.deploy();
    //const nest_old = await TestERC20.deploy('NEST', 'NEST', 18);
    //const nest_old = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest_old: ' + nest_old.address);

    const nest = await NestTokenNew.deploy();
    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);

    const commonGovernance = await CommonGovernance.deploy();
    //const commonGovernance = await CommonGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('commonGovernance: ' + commonGovernance.address);

    const nestFutures4V5 = await deployProxy(NestFutures4V5, []);
    //const nestFutures4V5 = await NestFutures4V5.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures4V5: ' + nestFutures4V5.address);

    const nestFutures5V1 = await deployProxy(NestFutures5V1, []);
    //const nestFutures5V1 = await NestFutures5V1.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures5V1: ' + nestFutures5V1.address);

    const nestCraft = await deployProxy(NestCraft, []);
    //const nestCraft = await NestCraft.attach('0x0000000000000000000000000000000000000000');
    console.log('nestCraft: ' + nestCraft.address);

    const nestCraftSimple = await deployProxy(NestCraftSimple, []);
    //const nestCraftSimple = await NestCraftSimple.attach('0x0000000000000000000000000000000000000000');
    console.log('nestCraftSimple: ' + nestCraftSimple.address);

    const nestSwitch = await deployProxy(NestSwitch, [nest_old.address, nest.address]);
    //const nestSwitch = await NestSwitch.attach('0x0000000000000000000000000000000000000000');
    console.log('nestSwitch: ' + nestSwitch.address);

    await nestFutures4V5.setGovernance(commonGovernance.address);
    await nestFutures5V1.setGovernance(commonGovernance.address);
    await nestCraft.setGovernance(commonGovernance.address);
    await nestCraftSimple.setGovernance(commonGovernance.address);
    await nestSwitch.setGovernance(commonGovernance.address);

    // -------- TEST --------
    const pancakeFactory = await PancakeFactory.deploy('0x0000000000000000000000000000000000000000');
    console.log('pancakeFactory: ' + pancakeFactory.address);

    const pancakeRouter = await PancakeRouter.deploy(pancakeFactory.address, '0x0000000000000000000000000000000000000000');
    console.log('pancakeRouter: ' + pancakeRouter.address);

    await pancakeFactory.createPair(usdt.address, nest.address);

    // -------- TEST --------

    await commonGovernance.registerAddress('nest.app.directPoster', (await ethers.getSigners())[0].address)
    await commonGovernance.registerAddress('nest.app.nest.old', nest_old.address);
    await commonGovernance.registerAddress('nest.app.nest', nest.address);
    await commonGovernance.registerAddress('pancake.app.router', pancakeRouter.address);
    await commonGovernance.registerAddress('pancake.pair.nestusdt', await pancakeFactory.getPair(usdt.address, nest.address));
    await commonGovernance.registerAddress('common.token.usdt', usdt.address);

    console.log('7. nestFutures4V5.update()');
    //await nestFutures4V5.update(commonGovernance.address);
    await commonGovernance.execute(nestFutures4V5.address, getCalldata('update', ['address'], [commonGovernance.address]));
    await commonGovernance.execute(nestFutures5V1.address, getCalldata('update', ['address'], [commonGovernance.address]));
    await commonGovernance.execute(nestCraft.address, getCalldata('update', ['address'], [commonGovernance.address]));
    await commonGovernance.execute(nestCraftSimple.address, getCalldata('update', ['address'], [commonGovernance.address]));
    //await commonGovernance.execute(nestSwitch.address, getCalldata('update', ['address'], [commonGovernance.address]));
    
    // await nestCraft.register('PI', 3141592653590000000n | (1n << 248n));
    // await nestCraft.register('E',  2718281828459000000n | (1n << 248n));
    // await nestCraft.registerAddress('P0', nestCraft.address);
    // await nestCraft.registerAddress('P1', nestCraft.address);
    // await nestCraft.registerAddress('P2', nestCraft.address);

    console.log('8. mint');
    await nest.transfer(nestFutures4V5.address, 100000000000000000000000000n);
    await nest.transfer(nestFutures5V1.address, 100000000000000000000000000n);
    await nest.approve(nestFutures4V5.address, 100000000000000000000000000n);
    await nest.approve(nestFutures5V1.address, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 1;

    const contracts = {
        eth: eth,
        usdt: usdt,
        nest: nest,
        nest_old: nest_old,

        commonGovernance: commonGovernance,
        nestFutures4V5: nestFutures4V5,
        nestFutures5V1: nestFutures5V1,
        pancakeFactory: pancakeFactory,
        pancakeRouter: pancakeRouter,
        nestCraft: nestCraft,
        nestCraftSimple: nestCraftSimple,
        nestSwitch: nestSwitch,
        
        BLOCK_TIME: BLOCK_TIME,
        USDT_DECIMALS: 18,

        miuT: function(orientation, blocks) {
            return Math.exp((orientation ? MIU_LONG : MIU_SHORT) * blocks * BLOCK_TIME);
        }
    };

    return contracts;
};