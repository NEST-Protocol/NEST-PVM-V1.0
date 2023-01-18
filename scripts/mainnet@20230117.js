// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const NestMultiSign = await ethers.getContractFactory('NestMultiSign');

    console.log('** Deploy: mainnet@20230117.js **');
    
    // ** Deploy: mainnet@20230117.js **
    // nestMultiSign: 0x88F0Ad9d14Bb500Fc7f97d556e668bF17DE91dc8

    // Address table
    // 
    // 1. James:
    // 0x5fa1dd7f6DCE7066d8be8B8787575d66a20Dc44C
    // 0x45b0d42174D2845cf99834dB81437C984E02DB77
    // 0x4C41369a139FFEe81E66641c87f59cF130a65A0a
    //
    // 2. Yang
    // 0x85126DB6cbc2Ee14FaAB20D234DC93ef5dEf5a08
    // 0x376fc43C3AFCd7AE7a2D70ab55d1440681F52099
    // 0x1F6153d13cf99a6CD1C6aC84eC5e923860daE78F
    // 
    // 3. British
    // 0x7891c9Bf9F3796Cc9Cf36b44d8dabB9C9a034636
    // 0xddA1Ad1EF11C42112CC3cE61bA4140e25F98d9a6
    // 0x0000000000000000000000000000000000000000

    // const nestMultiSign = await NestMultiSign.deploy([
    //     ['0x5fa1dd7f6DCE7066d8be8B8787575d66a20Dc44C', '0x45b0d42174D2845cf99834dB81437C984E02DB77', '0x4C41369a139FFEe81E66641c87f59cF130a65A0a'],
    //     ['0x85126DB6cbc2Ee14FaAB20D234DC93ef5dEf5a08', '0x376fc43C3AFCd7AE7a2D70ab55d1440681F52099', '0x1F6153d13cf99a6CD1C6aC84eC5e923860daE78F'],
    //     ['0x7891c9Bf9F3796Cc9Cf36b44d8dabB9C9a034636', '0xddA1Ad1EF11C42112CC3cE61bA4140e25F98d9a6', '0x0000000000000000000000000000000000000000'],
    // ], { nonce: 3 });
    const nestMultiSign = await NestMultiSign.attach('0x88F0Ad9d14Bb500Fc7f97d556e668bF17DE91dc8');
    console.log('nestMultiSign: ' + nestMultiSign.address);

    console.log((await nestMultiSign.getMember(0, 0)).member);
    console.log((await nestMultiSign.getMember(0, 1)).member);
    console.log((await nestMultiSign.getMember(0, 2)).member);

    console.log();

    console.log((await nestMultiSign.getMember(1, 0)).member);
    console.log((await nestMultiSign.getMember(1, 1)).member);
    console.log((await nestMultiSign.getMember(1, 2)).member);

    console.log();
    
    console.log((await nestMultiSign.getMember(2, 0)).member);
    console.log((await nestMultiSign.getMember(2, 1)).member);
    console.log((await nestMultiSign.getMember(2, 2)).member);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 14;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,

        nestMultiSign: nestMultiSign,

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