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

    console.log('** Deploy: scroll_test@20230602.js **');

    // ** Deploy: scroll_test@20230602.js **
    // nest: 0x146Af6aE0c93e9Aca1a39A644Ee7728bA9ddFA7c
    // commonGovernance: 0x526B8eE84c05b4cf742789026A447E2F052B21C8
    // nestFutures4V5: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
    // directPoster: 0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681

    //const nest = await NestToken.deploy();
    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x146Af6aE0c93e9Aca1a39A644Ee7728bA9ddFA7c');
    console.log('nest: ' + nest.address);

    //const commonGovernance = await CommonGovernance.deploy();
    const commonGovernance = await CommonGovernance.attach('0x526B8eE84c05b4cf742789026A447E2F052B21C8');
    console.log('commonGovernance: ' + commonGovernance.address);

    //const nestFutures4V5 = await deployProxy(NestFutures4V5, []);
    const nestFutures4V5 = await NestFutures4V5.attach('0xc39dC1385a44fBB895991580EA55FC10e7451cB3');
    console.log('nestFutures4V5: ' + nestFutures4V5.address);

    // await nestFutures4V5.setGovernance(commonGovernance.address);

    // // -------- TEST --------

    // await commonGovernance.registerAddress('nest.app.directPoster', '0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681');
    // await commonGovernance.registerAddress('nest.app.nest', nest.address);

    // console.log('7. nestFutures4V5.update()');
    // //await nestFutures4V5.update(commonGovernance.address);
    // await commonGovernance.execute(nestFutures4V5.address, getCalldata('update', ['address'], [commonGovernance.address]));

    // await nest.mintTo(nestFutures4V5.address, 100000000000000000000000000n);
    // await nest.approve(nestFutures4V5.address, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 1;

    const contracts = {
        eth: eth,
        nest: nest,

        commonGovernance: commonGovernance,
        nestFutures4V5: nestFutures4V5,

        BLOCK_TIME: BLOCK_TIME,
        USDT_DECIMALS: 18,

        miuT: function(orientation, blocks) {
            return Math.exp((orientation ? MIU_LONG : MIU_SHORT) * blocks * BLOCK_TIME);
        }
    };

    return contracts;
};