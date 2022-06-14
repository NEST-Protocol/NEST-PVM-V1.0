// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const FortPRC44 = await ethers.getContractFactory('FortPRC44');
    const FortPRCSwap = await ethers.getContractFactory('FortPRCSwap');

    console.log('** Deploy: bsc_test@20220613.js **');
    
    //     ** Deploy: bsc_test@20220613.js **
    // proxyAdmin: 0xB5604C3C3AE902513731037B9c7368842582642e
    
    // ** Deploy: bsc_test@20220613.js **
    // newFortPRC44: 0x6FAbA92Bbb48B5200AC4D9D6fECb7F2896c8A23b
    // newFortPRCSwap: 0xCdbaA683F924C18CE81C4D44696aa5C1Bb1BF122

    const newFortPRC44 = await FortPRC44.deploy();
    console.log('newFortPRC44: ' + newFortPRC44.address);

    const newFortPRCSwap = await FortPRCSwap.deploy();
    console.log('newFortPRCSwap: ' + await newFortPRCSwap.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        BLOCK_TIME: 3,
        newFortPRC44: newFortPRC44,
        newFortPRCSwap: newFortPRCSwap
    };

    return contracts;
};