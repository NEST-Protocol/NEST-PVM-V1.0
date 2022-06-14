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

    console.log('** Deploy: ropsten@20210918.js **');
    
    //     ** Deploy: ropsten@20210918.js **
    // usdt: 0xc6611844fD9FAE67ABFAdB5a67E33A4fbbB00893
    // hbtc: 0x86caf861010Ec334416C7d8c992Ba22b361152E4
    // nestPriceFacade: 0x85723E83A7E7d88b0F3Ceb4C5bE7C853e3Ed8a82
    // fortGovernance: 0xf669c02139e54C5D3b020DB8ba24c1bC66ebad87
    // dcu: 0xFe864063e10e5f7D99803765f28d2676A582A816
    // fortDAO: 0x417B0A969BebB25496e52303D0B22192261D3e82
    // fortOptions: 0x90b5212B1CE2cCF2aDC9Af4fF7EAcd61d0A216fF
    // fortFutures: 0x341bA26a1c4E1c609d170574Da0abB23f7986e34
    // fortVaultForStaking: 0x74E243b3C1cCF1c6b19788314d8a852C5A86e618

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0xc6611844fD9FAE67ABFAdB5a67E33A4fbbB00893');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0x86caf861010Ec334416C7d8c992Ba22b361152E4');
    console.log('hbtc: ' + hbtc.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x85723E83A7E7d88b0F3Ceb4C5bE7C853e3Ed8a82');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const fortGovernance = await FortGovernance.attach('0xf669c02139e54C5D3b020DB8ba24c1bC66ebad87');
    console.log('fortGovernance: ' + fortGovernance.address);

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xFe864063e10e5f7D99803765f28d2676A582A816');
    console.log('dcu: ' + dcu.address);

    //const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    const fortDAO = await FortDAO.attach('0x417B0A969BebB25496e52303D0B22192261D3e82');
    console.log('fortDAO: ' + fortDAO.address);

    //const fortOptions = await upgrades.deployProxy(FortOptions, [fortGovernance.address], { initializer: 'initialize' });
    const fortOptions = await FortOptions.attach('0x90b5212B1CE2cCF2aDC9Af4fF7EAcd61d0A216fF');
    console.log('fortOptions: ' + fortOptions.address);

    //const fortFutures = await upgrades.deployProxy(FortFutures, [fortGovernance.address], { initializer: 'initialize' });
    const fortFutures = await FortFutures.attach('0x341bA26a1c4E1c609d170574Da0abB23f7986e34');
    console.log('fortFutures: ' + fortFutures.address);

    //const fortVaultForStaking = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    const fortVaultForStaking = await FortVaultForStaking.attach('0x74E243b3C1cCF1c6b19788314d8a852C5A86e618');
    console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        usdt: usdt,
        hbtc: hbtc,

        fortGovernance: fortGovernance,
        dcu: dcu,
        fortDAO: fortDAO,
        fortOptions: fortOptions,
        fortFutures: fortFutures,
        fortVaultForStaking: fortVaultForStaking,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
};