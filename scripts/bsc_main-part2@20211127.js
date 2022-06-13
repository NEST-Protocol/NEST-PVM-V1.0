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
    const FortGovernance = await ethers.getContractFactory('FortGovernance');
    const DCU = await ethers.getContractFactory('DCU');
    const FortDAO = await ethers.getContractFactory('FortDAO');
    const FortOptions = await ethers.getContractFactory('FortOptions');
    const FortFutures = await ethers.getContractFactory('FortFutures');
    const HedgeSwap = await ethers.getContractFactory('HedgeSwap');

    console.log('** Deploy: bsc_main-part2@20211127.js **');
        
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // fortGovernance: 0x3e7D350BbAb71cAA2304e979aa6Af007EF5ECcB8
    // nestOpenMining: 0x09CE0e021195BA2c1CDE62A8B187abf810951540

    //     ** Deploy: bsc_main-part2@20211127.js **
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // fortGovernance: 0x3e7D350BbAb71cAA2304e979aa6Af007EF5ECcB8
    // nestPriceFacade: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
    // fortOptions: 0x284935F8C571d054Df98eDA8503ea13cde5fd8Cc
    // fortFutures: 0x8c5052f7747D8Ebc2F069286416b6aE8Ad3Cc149
    // hedgeSwap: 0x2Cd1Bf9345E969b5DFc6D88000475aD6d487363A
    // proxyAdmin: 0xB16260599777EFFB17fd2a8fD30c449e5b71C088

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF');
    console.log('dcu: ' + dcu.address);

    //const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const fortGovernance = await FortGovernance.attach('0x3e7D350BbAb71cAA2304e979aa6Af007EF5ECcB8');
    console.log('fortGovernance: ' + fortGovernance.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    // const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    // //const fortDAO = await FortDAO.attach('0x0000000000000000000000000000000000000000');
    // console.log('fortDAO: ' + fortDAO.address);

    //const fortOptions = await upgrades.deployProxy(FortOptions, [fortGovernance.address], { initializer: 'initialize' });
    const fortOptions = await FortOptions.attach('0x284935F8C571d054Df98eDA8503ea13cde5fd8Cc');
    console.log('fortOptions: ' + fortOptions.address);

    //const fortFutures = await upgrades.deployProxy(FortFutures, [fortGovernance.address], { initializer: 'initialize' });
    const fortFutures = await FortFutures.attach('0x8c5052f7747D8Ebc2F069286416b6aE8Ad3Cc149');
    console.log('fortFutures: ' + fortFutures.address);

    //const hedgeSwap = await upgrades.deployProxy(HedgeSwap, [fortGovernance.address], { initializer: 'initialize' });
    const hedgeSwap = await HedgeSwap.attach('0x2Cd1Bf9345E969b5DFc6D88000475aD6d487363A');
    console.log('hedgeSwap: ' + hedgeSwap.address);

    // console.log('2. fortGovernance.setBuiltinAddress()');
    // await fortGovernance.setBuiltinAddress(
    //     dcu.address,
    //     '0x0000000000000000000000000000000000000000', //fortDAO.address,
    //     fortOptions.address, //fortOptions.address,
    //     fortFutures.address, //fortFutures.address,
    //     '0x0000000000000000000000000000000000000000',
    //     nestPriceFacade.address
    // );

    // console.log('3. dcu.update()');
    // await dcu.update(fortGovernance.address, { nonce: 12 });
    // console.log('4. fortDAO.update()');
    // await fortDAO.update(fortGovernance.address);
    // console.log('5. fortOptions.update()');
    // await fortOptions.update(fortGovernance.address);
    // console.log('6. fortFutures.update()');
    // await fortFutures.update(fortGovernance.address);
    // console.log('7. fortVaultForStaking.update()');
    // await fortVaultForStaking.update(fortGovernance.address, { nonce: 12 });

    // console.log('8. fortOptions.setConfig()');
    // await fortOptions.setConfig(eth.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });
    // console.log('8.1. fortOptions.setConfig()');
    // await fortOptions.setConfig(hbtc.address, { 
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

    //await fortFutures.create(eth.address, 1, true);
    //await fortFutures.create(eth.address, 2, true);
    //await fortFutures.create(eth.address, 3, true);
    //await fortFutures.create(eth.address, 4, true);
    //await fortFutures.create(eth.address, 5, true);
    //await fortFutures.create(eth.address, 1, false);
    //await fortFutures.create(eth.address, 2, false);
    //await fortFutures.create(eth.address, 3, false);
    //await fortFutures.create(eth.address, 4, false);
    //await fortFutures.create(eth.address, 5, false);

    // 2021-11-27 15:30 execute
    //console.log('9. dcu.setMinter(fortOptions.address, 1)');
    //await dcu.setMinter(fortOptions.address, 1);

    // console.log('10. dcu.setMinter(fortFutures.address, 1)');
    // await dcu.setMinter(fortFutures.address, 1);

    console.log('---------- OK ----------');
    
    const contracts = {
        dcu: dcu,
        fortGovernance: fortGovernance,

        fortOptions: fortOptions,
        fortFutures: fortFutures,
        hedgeSwap: hedgeSwap,

        nestPriceFacade: nestPriceFacade
    };

    return contracts;
};