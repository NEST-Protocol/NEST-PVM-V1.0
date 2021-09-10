const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, usdt, fort, 
            fortGovernance,
            fortEuropeanOption, fortLever, fortVaultForStaking 
        } = await deploy();

        // const FortVaultForStaking = await ethers.getContractFactory('FortVaultForStaking');
        // const fvfs = await FortVaultForStaking.deploy();
        // console.log('fvfs:' + fvfs.address);
        // //const BoxV2 = await ethers.getContractFactory("BoxV2");
        // //const upgraded = await upgrades.upgradeProxy(fortVaultForStaking.address, FortVaultForStaking);
        // //console.log(upgraded);

        // // await fortVaultForStaking.setConfig(1000000000000000000n, 9266520n, 9266600n);
        // // await fortVaultForStaking.batchSetPoolWeight(
        // //     [usdt.address, fort.address], 
        // //     [100n, 1000n], 
        // //     [3, 7]
        // // );

        // //await usdt.transfer(owner.address, 10000000000n);
        // await usdt.approve(fortVaultForStaking.address, 10000000000n);
        // await fortVaultForStaking.stake(usdt.address, 100n, 700000000n);
        
    });
});
