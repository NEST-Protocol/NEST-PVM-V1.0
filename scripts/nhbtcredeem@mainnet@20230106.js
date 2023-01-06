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
    const NestRedeem = await ethers.getContractFactory('NestRedeem');

    console.log('** Deploy: nhbtcredeem@mainnet@20230106.js **');
    
    // ** Deploy: nhbtcredeem@mainnet@20230106.js **
    // nhbtc: 0x1F832091fAf289Ed4f50FE7418cFbD2611225d46
    // nest: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
    // nestGovernance: 0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5
    // ntokenMining: 0xC2058Dd4D55Ae1F3e1b0744Bdb69386c9fD902CA
    // nestRedeem: 0xAF22d05095d09cb6CB4f18cb7aeFd94Cb39EB113
    // proxyAdmin: 0xCA52f25f37d213CeD3dDE81a539e64464dEa8f3C

    //const nhbtc = await TestERC20.deploy('nHBTC', 'nHBTC', 18);
    const nhbtc = await TestERC20.attach('0x1F832091fAf289Ed4f50FE7418cFbD2611225d46');
    console.log('nhbtc: ' + nhbtc.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
    console.log('nest: ' + nest.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestRedeem = await NestRedeem.deploy(nhbtc.address, nest.address, 500000000000000000n, { nonce: 74 });
    const nestRedeem = await NestRedeem.attach('0xAF22d05095d09cb6CB4f18cb7aeFd94Cb39EB113');
    console.log('nestRedeem: ' + nestRedeem.address);

    //await nestRedeem.initialize(nestGovernance.address, { nonce: 75 });

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 14;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        nhbtc: nhbtc,
        nest: nest,

        nestGovernance: nestGovernance,

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