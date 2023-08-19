// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestSwitch = await ethers.getContractFactory('NestSwitch');

    console.log('** Deploy: mainnet@20230810.js **');

    const nest = await TestERC20.attach('0xcd6926193308d3B371FdD6A6219067E550000000');
    console.log('nest: ' + nest.address);

    //const nestSwitch = await NestSwitch.deploy();
    const nestSwitch = await NestSwitch.attach('0xA5014706eD91a30F9bcc0DD777Ed82D7eECA8a29');
    console.log('nestSwitch: ' + nestSwitch.address);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        nest: nest,
        nestSwitch: nestSwitch,

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