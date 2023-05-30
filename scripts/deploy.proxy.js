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
    const NestFutures4V5 = await ethers.getContractFactory('NestFutures4V5');
    const PancakeFactory = await ethers.getContractFactory('PancakeFactory');
    const PancakeRouter = await ethers.getContractFactory('PancakeRouter');

    console.log('** Deploy: deploy.proxy.js **');
    
    const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);

    const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const nestGovernance = await NestGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('nestGovernance: ' + nestGovernance.address);

    const nestFutures4V5 = await upgrades.deployProxy(NestFutures4V5, [nestGovernance.address], { initializer: 'initialize' });
    //const nestFutures4V5 = await NestFutures4V5.attach('0x0000000000000000000000000000000000000000');
    console.log('nestFutures4V5: ' + nestFutures4V5.address);

    // -------- TEST --------
    const pancakeFactory = await PancakeFactory.deploy('0x0000000000000000000000000000000000000000');
    console.log('pancakeFactory: ' + pancakeFactory.address);

    const pancakeRouter = await PancakeRouter.deploy(pancakeFactory.address, '0x0000000000000000000000000000000000000000');
    console.log('pancakeRouter: ' + pancakeRouter.address);

    await pancakeFactory.createPair(usdt.address, nest.address);

    // -------- TEST --------

    console.log('2. nestGovernance.setBuiltinAddress()');
    await nestGovernance.setBuiltinAddress(
        nest.address,
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000'
    );
    await nestGovernance.registerAddress('nest.app.directPoster', (await ethers.getSigners())[0].address)
    await nestGovernance.registerAddress('nest.app.maintains', (await ethers.getSigners())[0].address);
    await nestGovernance.registerAddress('pancake.app.router', pancakeRouter.address);
    await nestGovernance.registerAddress('pancake.pair.nestusdt', await pancakeFactory.getPair(usdt.address, nest.address));
    await nestGovernance.registerAddress('common.token.usdt', usdt.address);

    console.log('7. nestFutures4V5.update()');
    await nestFutures4V5.update(nestGovernance.address);
    
    await nest.transfer(nestFutures4V5.address, 100000000000000000000000000n);
    await nest.approve(nestFutures4V5.address, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        usdt: usdt,
        nest: nest,

        nestGovernance: nestGovernance,
        nestFutures4V5: nestFutures4V5,
        pancakeFactory: pancakeFactory,
        pancakeRouter: pancakeRouter,

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