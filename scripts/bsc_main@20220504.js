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
    const FortPRC = await ethers.getContractFactory('FortPRC');
    const FortPRCSwap = await ethers.getContractFactory('FortPRCSwap');

    console.log('** Deploy: bsc_main@20220504.js **');
        
    //     ** Deploy: bsc_main-part2@20211127.js **
    // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF
    // hedgeGovernance: 0x3e7D350BbAb71cAA2304e979aa6Af007EF5ECcB8
    // nestPriceFacade: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
    // fortOptions: 0x284935F8C571d054Df98eDA8503ea13cde5fd8Cc
    // fortFutures: 0x8c5052f7747D8Ebc2F069286416b6aE8Ad3Cc149
    // hedgeSwap: 0x2Cd1Bf9345E969b5DFc6D88000475aD6d487363A
    // fortSwap: 0x9484f12044b9d5707AfeaC5BD02b5E0214381801
    // fortPRC: 0xf43A71e4Da398e5731c9580D11014dE5e8fD0530
    // fortPRCSwap: 0x6a36b2491F761007A74b18e357d58B895272DbfF
    // proxyAdmin: 0xB16260599777EFFB17fd2a8fD30c449e5b71C088

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF');
    console.log('dcu: ' + dcu.address);

    //const hedgeGovernance = await upgrades.deployProxy(HedgeGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const hedgeGovernance = await HedgeGovernance.attach('0x3e7D350BbAb71cAA2304e979aa6Af007EF5ECcB8');
    console.log('hedgeGovernance: ' + hedgeGovernance.address);

    //const fortPRC = await upgrades.deployProxy(FortPRC, [hedgeGovernance.address], { initializer: 'initialize' });
    const fortPRC = await FortPRC.attach('0xf43A71e4Da398e5731c9580D11014dE5e8fD0530');
    console.log('fortPRC: ' + fortPRC.address);

    // console.log('3. fortPRC.update()');
    // await fortPRC.update(hedgeGovernance.address);

    // console.log('9. dcu.setMinter(fortPRC.address, 1)');
    // await dcu.setMinter(fortPRC.address, 1);

    // TODO: Modify FortPRCSwap.PRC_TOKEN_ADDRESS and FortPRCSwap.COFIX_ROUTER_ADDRESS before execute
    
    //const fortPRCSwap = await upgrades.deployProxy(FortPRCSwap, [hedgeGovernance.address], { initializer: 'initialize' });
    const fortPRCSwap = await FortPRCSwap.attach('0x6a36b2491F761007A74b18e357d58B895272DbfF');
    console.log('fortPRCSwap: ' + fortPRCSwap.address);
    
    // console.log('4. fortPRCSwap.update()');
    // await fortPRCSwap.update(hedgeGovernance.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        dcu: dcu,
        hedgeGovernance: hedgeGovernance,

        fortPRC: fortPRC,

        fortPRCSwap: fortPRCSwap
    };

    return contracts;
};