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
    const FortVaultForStaking = await ethers.getContractFactory('FortVaultForStaking');

    console.log('** Deploy: ropsten@20210929.js **');
    // usdt: 0xc6611844fD9FAE67ABFAdB5a67E33A4fbbB00893
    // dcu: 0xFe864063e10e5f7D99803765f28d2676A582A816
    // nestPriceFacade: 0x85723E83A7E7d88b0F3Ceb4C5bE7C853e3Ed8a82
    // fortGovernance: 0xe3f6Ca50831086618689f564327796F29BF8bFD2
    // fortDAO: 0x69d4A007686FbAd6bE4e2E3e0A29AbF105077BC0
    // fortOptions: 0xa6948042D7B68b4c28907cE8B450DC0e5BBe30a5
    // fortFutures: 0x48437856C4f6C3F60eA014110066BB440A4530D7
    // hedgeVaultForStakinggggg: 0x176D7C08e5BC8f7334a1b1A5DC2C3516F80e1195

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0xc6611844fD9FAE67ABFAdB5a67E33A4fbbB00893');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    //const hbtc = await TestERC20.attach('0x86caf861010Ec334416C7d8c992Ba22b361152E4');
    //console.log('hbtc: ' + hbtc.address);

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xFe864063e10e5f7D99803765f28d2676A582A816');
    console.log('dcu: ' + dcu.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x85723E83A7E7d88b0F3Ceb4C5bE7C853e3Ed8a82');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const fortGovernance = await FortGovernance.attach('0xe3f6Ca50831086618689f564327796F29BF8bFD2');
    console.log('fortGovernance: ' + fortGovernance.address);

    //const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    const fortDAO = await FortDAO.attach('0x69d4A007686FbAd6bE4e2E3e0A29AbF105077BC0');
    console.log('fortDAO: ' + fortDAO.address);

    //const fortOptions = await upgrades.deployProxy(FortOptions, [fortGovernance.address], { initializer: 'initialize' });
    const fortOptions = await FortOptions.attach('0xa6948042D7B68b4c28907cE8B450DC0e5BBe30a5');
    console.log('fortOptions: ' + fortOptions.address);

    //const fortFutures = await upgrades.deployProxy(FortFutures, [fortGovernance.address], { initializer: 'initialize' });
    const fortFutures = await FortFutures.attach('0x48437856C4f6C3F60eA014110066BB440A4530D7');
    console.log('fortFutures: ' + fortFutures.address);

    //const hedgeVaultForStakinggggg = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    const hedgeVaultForStakinggggg = await FortVaultForStaking.attach('0x176D7C08e5BC8f7334a1b1A5DC2C3516F80e1195');
    console.log('hedgeVaultForStakinggggg: hedgeVaultForStakingngngngng.address);

    // // await fortGovernance.initialize('0x0000000000000000000000000000000000000000');
    // console.log('1. dcu.initialize(fortGovernance.address)');
    // //await dcu.initialize(fortGovernance.address);
    // // await fortDAO.initialize(fortGovernance.address);
    // // await fortOptions.initialize(fortGovernance.address);
    // // await fortFutures.initialize(fortGovernance.address);
    // // await hedgeVaultForStakinggggg.initialize(fortGovernance.address);

    // console.log('2. fortGovernance.setBuiltinAddress()');
    // await fortGovernance.setBuiltinAddress(
    //     dcu.address,
    //     fortDAO.address,
    //     fortOptions.address,
    //     fortFutures.address,
    //     hedgeVaultForStakinggggg.address,
    //     nestPriceFacade.address
    // );

    // console.log('3. dcu.update()');
    // await dcu.update(fortGovernance.address);
    // console.log('4. fortDAO.update()');
    // await fortDAO.update(fortGovernance.address);
    // console.log('5. fortOptions.update()');
    // await fortOptions.update(fortGovernance.address);
    // console.log('6. fortFutures.update()');
    // await fortFutures.update(fortGovernance.address);
    // console.log('7. hedgeVaultForStakinggggg.update()');
    // await hedgeVaultForStakinggggg.update(fortGovernance.address);

    // console.log('8. fortOptions.setConfig()');
    // await fortOptions.setConfig(eth.address, { 
    //     sigmaSQ: '45659142400', 
    //     miu: '467938556917', 
    //     minPeriod: 6000 
    // });
    // // console.log('8.1. fortOptions.setConfig()');
    // // await fortOptions.setConfig(hbtc.address, { 
    // //     sigmaSQ: '45659142400', 
    // //     miu: '467938556917', 
    // //     minPeriod: 6000 
    // // });

    // console.log('9. dcu.setMinter(fortOptions.address, 1)');
    // await dcu.setMinter(fortOptions.address, 1);
    // console.log('10. dcu.setMinter(fortFutures.address, 1)');
    // await dcu.setMinter(fortFutures.address, 1);
    // console.log('11. dcu.setMinter(hedgeVaultForStakinggggg.address, 1)');
    // await dcu.setMinter(hedgeVaultForStakinggggg.address, 1);

    // await fortOptions.setUsdtTokenAddress(usdt.address);
    // await fortFutures.setUsdtTokenAddress(usdt.address);

    // console.log('8.2 create lever');
    // await fortFutures.create(eth.address, 1, true);
    // await fortFutures.create(eth.address, 2, true);
    // await fortFutures.create(eth.address, 3, true);
    // await fortFutures.create(eth.address, 4, true);
    // await fortFutures.create(eth.address, 5, true);
    // await fortFutures.create(eth.address, 1, false);
    // await fortFutures.create(eth.address, 2, false);
    // await fortFutures.create(eth.address, 3, false);
    // await fortFutures.create(eth.address, 4, false);
    // await fortFutures.create(eth.address, 5, false);
    // // await fortFutures.create(hbtc.address, 1, true);
    // // await fortFutures.create(hbtc.address, 2, true);
    // // await fortFutures.create(hbtc.address, 5, true);
    // // await fortFutures.create(hbtc.address, 1, false);
    // // await fortFutures.create(hbtc.address, 2, false);
    // // await fortFutures.create(hbtc.address, 5, false);

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        usdt: usdt,
        //hbtc: hbtc,

        fortGovernance: fortGovernance,
        dcu: dcu,
        fortDAO: fortDAO,
        fortOptions: fortOptions,
        fortFutures: fortFutures,
        hedgeVaultForStakinggghedgeVaultForStakingngngngng,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
};