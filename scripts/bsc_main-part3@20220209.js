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
    const HedgeOptions = await ethers.getContractFactory('HedgeOptions');
    const HedgeFutures = await ethers.getContractFactory('HedgeFutures');
    const HedgeSwap = await ethers.getContractFactory('HedgeSwap');
    const FortSwap = await ethers.getContractFactory('FortSwap');

    console.log('** 开始部署合约 bsc_main-part3@20220209.js **');
        
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // hedgeGovernance: 0x3e7D350BbAb71cAA2304e979aa6Af007EF5ECcB8
    // nestOpenMining: 0x09CE0e021195BA2c1CDE62A8B187abf810951540

    //     ** 开始部署合约 bsc_main-part2@20211127.js **
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // hedgeGovernance: 0x3e7D350BbAb71cAA2304e979aa6Af007EF5ECcB8
    // nestPriceFacade: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
    // hedgeOptions: 0x284935F8C571d054Df98eDA8503ea13cde5fd8Cc
    // hedgeFutures: 0x8c5052f7747D8Ebc2F069286416b6aE8Ad3Cc149
    // hedgeSwap: 0x2Cd1Bf9345E969b5DFc6D88000475aD6d487363A
    // proxyAdmin: 0xB16260599777EFFB17fd2a8fD30c449e5b71C088

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF');
    console.log('dcu: ' + dcu.address);

    //const hedgeGovernance = await upgrades.deployProxy(HedgeGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const hedgeGovernance = await HedgeGovernance.attach('0x3e7D350BbAb71cAA2304e979aa6Af007EF5ECcB8');
    console.log('hedgeGovernance: ' + hedgeGovernance.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    // const hedgeDAO = await upgrades.deployProxy(HedgeDAO, [hedgeGovernance.address], { initializer: 'initialize' });
    // //const hedgeDAO = await HedgeDAO.attach('0x0000000000000000000000000000000000000000');
    // console.log('hedgeDAO: ' + hedgeDAO.address);

    //const hedgeOptions = await upgrades.deployProxy(HedgeOptions, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeOptions = await HedgeOptions.attach('0x284935F8C571d054Df98eDA8503ea13cde5fd8Cc');
    console.log('hedgeOptions: ' + hedgeOptions.address);

    //const hedgeFutures = await upgrades.deployProxy(HedgeFutures, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeFutures = await HedgeFutures.attach('0x8c5052f7747D8Ebc2F069286416b6aE8Ad3Cc149');
    console.log('hedgeFutures: ' + hedgeFutures.address);

    //const hedgeSwap = await upgrades.deployProxy(HedgeSwap, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeSwap = await HedgeSwap.attach('0x2Cd1Bf9345E969b5DFc6D88000475aD6d487363A');
    console.log('hedgeSwap: ' + hedgeSwap.address);

    const fortSwap = await upgrades.deployProxy(FortSwap, [hedgeGovernance.address], { initializer: 'initialize' });
    //const fortSwap = await FortSwap.attach('0x0000000000000000000000000000000000000000');
    console.log('fortSwap: ' + fortSwap.address);

    // console.log('2. hedgeGovernance.setBuiltinAddress()');
    // await hedgeGovernance.setBuiltinAddress(
    //     dcu.address,
    //     '0x0000000000000000000000000000000000000000', //hedgeDAO.address,
    //     hedgeOptions.address, //hedgeOptions.address,
    //     hedgeFutures.address, //hedgeFutures.address,
    //     '0x0000000000000000000000000000000000000000',
    //     nestPriceFacade.address
    // );

    // console.log('3. dcu.update()');
    // await dcu.update(hedgeGovernance.address, { nonce: 12 });
    // console.log('4. hedgeDAO.update()');
    // await hedgeDAO.update(hedgeGovernance.address);
    // console.log('5. hedgeOptions.update()');
    // await hedgeOptions.update(hedgeGovernance.address);
    // console.log('6. hedgeFutures.update()');
    // await hedgeFutures.update(hedgeGovernance.address);
    // console.log('7. hedgeVaultForStaking.update()');
    // await hedgeVaultForStaking.update(hedgeGovernance.address, { nonce: 12 });

    // console.log('8. hedgeOptions.setConfig()');
    // await hedgeOptions.setConfig(eth.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });
    // console.log('8.1. hedgeOptions.setConfig()');
    // await hedgeOptions.setConfig(hbtc.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });

    //console.log('8.2 create lever');
    // lever	orientation		index
    // 2		1				0
    // 3		1				1
    // 5		1				2
    // 1		1				3
    // 4        1               4
    // 1        0               5
    // 2        0               6
    // 3        0               7
    // 4        0               8
    // 5        0               9

    //await hedgeFutures.create(eth.address, 1, true);
    //await hedgeFutures.create(eth.address, 2, true);
    //await hedgeFutures.create(eth.address, 3, true);
    //await hedgeFutures.create(eth.address, 4, true);
    //await hedgeFutures.create(eth.address, 5, true);
    //await hedgeFutures.create(eth.address, 1, false);
    //await hedgeFutures.create(eth.address, 2, false);
    //await hedgeFutures.create(eth.address, 3, false);
    //await hedgeFutures.create(eth.address, 4, false);
    //await hedgeFutures.create(eth.address, 5, false);

    // 2021-11-27 15:30执行
    //console.log('9. dcu.setMinter(hedgeOptions.address, 1)');
    //await dcu.setMinter(hedgeOptions.address, 1);

    // console.log('10. dcu.setMinter(hedgeFutures.address, 1)');
    // await dcu.setMinter(hedgeFutures.address, 1);

    console.log('---------- OK ----------');
    
    const contracts = {
        dcu: dcu,
        hedgeGovernance: hedgeGovernance,

        hedgeOptions: hedgeOptions,
        hedgeFutures: hedgeFutures,
        hedgeSwap: hedgeSwap,

        nestPriceFacade: nestPriceFacade
    };

    return contracts;
};