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
    const HedgeVaultForStaking = await ethers.getContractFactory('HedgeVaultForStaking');

    console.log('** Deploy: ropsten@20210918.js **');
    
    //     ** Deploy: ropsten@20210918.js **
    // usdt: 0xc6611844fD9FAE67ABFAdB5a67E33A4fbbB00893
    // hbtc: 0x86caf861010Ec334416C7d8c992Ba22b361152E4
    // nestPriceFacade: 0x85723E83A7E7d88b0F3Ceb4C5bE7C853e3Ed8a82
    // hedgeGovernance: 0xf669c02139e54C5D3b020DB8ba24c1bC66ebad87
    // dcu: 0xFe864063e10e5f7D99803765f28d2676A582A816
    // hedgeDAO: 0x417B0A969BebB25496e52303D0B22192261D3e82
    // hedgeOptions: 0x90b5212B1CE2cCF2aDC9Af4fF7EAcd61d0A216fF
    // hedgeFutures: 0x341bA26a1c4E1c609d170574Da0abB23f7986e34
    // hedgeVaultForStaking: 0x74E243b3C1cCF1c6b19788314d8a852C5A86e618

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0xc6611844fD9FAE67ABFAdB5a67E33A4fbbB00893');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0x86caf861010Ec334416C7d8c992Ba22b361152E4');
    console.log('hbtc: ' + hbtc.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x85723E83A7E7d88b0F3Ceb4C5bE7C853e3Ed8a82');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const hedgeGovernance = await upgrades.deployProxy(HedgeGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const hedgeGovernance = await HedgeGovernance.attach('0xf669c02139e54C5D3b020DB8ba24c1bC66ebad87');
    console.log('hedgeGovernance: ' + hedgeGovernance.address);

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xFe864063e10e5f7D99803765f28d2676A582A816');
    console.log('dcu: ' + dcu.address);

    //const hedgeDAO = await upgrades.deployProxy(HedgeDAO, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeDAO = await HedgeDAO.attach('0x417B0A969BebB25496e52303D0B22192261D3e82');
    console.log('hedgeDAO: ' + hedgeDAO.address);

    //const hedgeOptions = await upgrades.deployProxy(HedgeOptions, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeOptions = await HedgeOptions.attach('0x90b5212B1CE2cCF2aDC9Af4fF7EAcd61d0A216fF');
    console.log('hedgeOptions: ' + hedgeOptions.address);

    //const hedgeFutures = await upgrades.deployProxy(HedgeFutures, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeFutures = await HedgeFutures.attach('0x341bA26a1c4E1c609d170574Da0abB23f7986e34');
    console.log('hedgeFutures: ' + hedgeFutures.address);

    //const hedgeVaultForStaking = await upgrades.deployProxy(HedgeVaultForStaking, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeVaultForStaking = await HedgeVaultForStaking.attach('0x74E243b3C1cCF1c6b19788314d8a852C5A86e618');
    console.log('hedgeVaultForStaking: ' +hedgeVaultForStakingng.address);

    // // await hedgeGovernance.initialize('0x0000000000000000000000000000000000000000');
    // console.log('1. dcu.initialize(hedgeGovernance.address)');
    // await dcu.initialize(hedgeGovernance.address);
    // // await hedgeDAO.initialize(hedgeGovernance.address);
    // // await hedgeOptions.initialize(hedgeGovernance.address);
    // // await hedgeFutures.initialize(hedgeGovernance.address);
    // // await hedgeVaultForStaking.initialize(hedgeGovernance.address);

    // console.log('2. hedgeGovernance.setBuiltinAddress()');
    // await hedgeGovernance.setBuiltinAddress(
    //     dcu.address,
    //     hedgeDAO.address,
    //     hedgeOptions.address,
    //     hedgeFutures.address,
    //     hedgeVaultForStaking.address,
    //     nestPriceFacade.address
    // );

    // console.log('3. dcu.update()');
    // await dcu.update(hedgeGovernance.address);
    // console.log('4. hedgeDAO.update()');
    // await hedgeDAO.update(hedgeGovernance.address);
    // console.log('5. hedgeOptions.update()');
    // await hedgeOptions.update(hedgeGovernance.address);
    // console.log('6. hedgeFutures.update()');
    // await hedgeFutures.update(hedgeGovernance.address);
    // console.log('7. hedgeVaultForStaking.update()');
    // await hedgeVaultForStaking.update(hedgeGovernance.address);

    // console.log('8. hedgeOptions.setConfig()');
    // await hedgeOptions.setConfig(eth.address, { 
    //     sigmaSQ: '4168125400', 
    //     miu: '175482725206', 
    //     minPeriod: 10000 
    // });
    // console.log('8.1. hedgeOptions.setConfig()');
    // await hedgeOptions.setConfig(hbtc.address, { 
    //     sigmaSQ: '4168125400', 
    //     miu: '175482725206', 
    //     minPeriod: 10000 
    // });

    // console.log('9. dcu.setMinter(hedgeOptions.address, 1)');
    // await dcu.setMinter(hedgeOptions.address, 1);
    // console.log('10. dcu.setMinter(hedgeFutures.address, 1)');
    // await dcu.setMinter(hedgeFutures.address, 1);
    // console.log('11. dcu.setMinter(hedgeVaultForStaking.address, 1)');
    // await dcu.setMinter(hedgeVaultForStaking.address, 1);

    // await hedgeOptions.setUsdtTokenAddress(usdt.address);
    // await hedgeFutures.setUsdtTokenAddress(usdt.address);

    // console.log('8.2 create lever');
    // await hedgeFutures.create(eth.address, 1, true);
    // await hedgeFutures.create(eth.address, 2, true);
    // await hedgeFutures.create(eth.address, 5, true);
    // await hedgeFutures.create(eth.address, 1, false);
    // await hedgeFutures.create(eth.address, 2, false);
    // await hedgeFutures.create(eth.address, 5, false);
    // await hedgeFutures.create(hbtc.address, 1, true);
    // await hedgeFutures.create(hbtc.address, 2, true);
    // await hedgeFutures.create(hbtc.address, 5, true);
    // await hedgeFutures.create(hbtc.address, 1, false);
    // await hedgeFutures.create(hbtc.address, 2, false);
    // await hedgeFutures.create(hbtc.address, 5, false);

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        usdt: usdt,
        hbtc: hbtc,

        hedgeGovernance: hedgeGovernance,
        dcu: dcu,
        hedgeDAO: hedgeDAO,
        hedgeOptions: hedgeOptions,
        hedgeFutures: hedgeFutures,
        hedgeVaultForStaking:hedgeVaultForStakingng,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
};