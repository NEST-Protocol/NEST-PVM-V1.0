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
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestVault = await ethers.getContractFactory('NestVault');
    const NestOptions = await ethers.getContractFactory('NestOptions');
    const NestFutures = await ethers.getContractFactory('NestFutures');
    const NestPRC44 = await ethers.getContractFactory('NestPRC44');

    console.log('** Deploy: bsc_test@20220704.js **');
    
    // ** Deploy: bsc_test@20220704.js **
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    // nestPriceFacade: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277
    // nestGovernance: 0x0641a3F42500d8838D71230426bCC12e0cF31144
    // nestVault: 0xceF3e2A8fa02790b8A63370354cB386520a04fb8
    // nestOptions: 0xf8559f269E8de4619C7FAd37Cc118DEe5f551f21
    // nestFutures: 0x3FB118a6Bd159815cD088332B047A01CE9624046
    // nestPRC44: 0x9567F7b70a2da3802Cf02ee66C8DAFb9cCEe5571

    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc');
    console.log('usdt: ' + usdt.address);

    //const nestPriceFacade = await NestPriceFacade.deploy(usdt.address);
    const nestPriceFacade = await NestPriceFacade.attach('0xF2f9E62f52389EF223f5Fa8b9926e95386935277');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x0641a3F42500d8838D71230426bCC12e0cF31144');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestVault = await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0xceF3e2A8fa02790b8A63370354cB386520a04fb8');
    console.log('nestVault: ' + nestVault.address);

    //const nestOptions = await upgrades.deployProxy(NestOptions, [nestGovernance.address], { initializer: 'initialize' });
    const nestOptions = await NestOptions.attach('0xf8559f269E8de4619C7FAd37Cc118DEe5f551f21');
    console.log('nestOptions: ' + nestOptions.address);

    //const nestFutures = await upgrades.deployProxy(NestFutures, [nestGovernance.address], { initializer: 'initialize' });
    const nestFutures = await NestFutures.attach('0x3FB118a6Bd159815cD088332B047A01CE9624046');
    console.log('nestFutures: ' + nestFutures.address);

    //const nestPRC44 = await upgrades.deployProxy(NestPRC44, [nestGovernance.address], { initializer: 'initialize' });
    const nestPRC44 = await NestPRC44.attach('0x9567F7b70a2da3802Cf02ee66C8DAFb9cCEe5571');
    console.log('nestPRC44: ' + nestPRC44.address);

    // console.log('2. nestGovernance.setBuiltinAddress()');
    // await nestGovernance.setBuiltinAddress(
    //     nest.address,
    //     nestVault.address,
    //     nestOptions.address,
    //     nestFutures.address,
    //     '0x0000000000000000000000000000000000000000',
    //     nestPriceFacade.address
    // );

    // console.log('4. nestVault.update()');
    // await nestVault.update(nestGovernance.address);
    // console.log('5. nestOptions.update()');
    // await nestOptions.update(nestGovernance.address);
    // console.log('6. nestFutures.update()');
    // await nestFutures.update(nestGovernance.address);

    // console.log('8. nestPRC44.update()');
    // await nestPRC44.update(nestGovernance.address);

    // // 2.4. Register ETH ans HBTC
    // console.log('7. nestOptions.register(eth.address)');
    // await nestOptions.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });

    // console.log('8. nestOptions.register(hbtc.address)');
    // await nestOptions.register(hbtc.address, {
    //     channelId: 0,
    //     pairIndex: 2,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });
    
    // // 3.4. Register ETH and HBTC
    // console.log('9. nestFutures.register(eth.address)');
    // await nestFutures.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });
    // console.log('10. nestFutures.register(hbtc.address)');
    // await nestFutures.register(hbtc.address, {
    //     channelId: 0,
    //     pairIndex: 2,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });

    // console.log('8.2 create lever');
    
    // // 3.5. Register levels for ETH
    // console.log('13. create eth long lever');
    // await nestFutures.create(eth.address, [1, 2, 3, 4, 5], true);
    // console.log('14. create eth short lever');
    // await nestFutures.create(eth.address, [1, 2, 3, 4, 5], false);
    
    // // 3.5. Register levels for HBTC
    // console.log('13. create hbtc long lever');
    // await nestFutures.create(hbtc.address, [1, 2, 3, 4, 5], true);
    // console.log('14. create hbtc short lever');
    // await nestFutures.create(hbtc.address, [1, 2, 3, 4, 5], false);

    // await nestVault.setAddress(nest.address);

    // //await dcu.approve(nestOptions.address, 100000000000000000000000000n);
    // //await dcu.approve(nestFutures.address, 100000000000000000000000000n);
    // await nestVault.approve(nestOptions.address, 100000000000000000000000000n);
    // await nestVault.approve(nestPRC44.address, 100000000000000000000000000n);
    
    // await nest.approve(nestOptions.address, 100000000000000000000000000n);
    // await nest.approve(nestFutures.address, 100000000000000000000000000n);
    // await nest.transfer(nestVault.address, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        usdt: usdt,
        hbtc: hbtc,

        nestGovernance: nestGovernance,
        nestVault: nestVault,
        nestOptions: nestOptions,
        nestFutures: nestFutures,
        nestPRC44: nestPRC44,
        nestPriceFacade: nestPriceFacade,

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