const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('deploy', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const FortPRC44 = await ethers.getContractFactory('FortPRC44');
        const FortPRCSwap = await ethers.getContractFactory('FortPRCSwap');

        const { 
            eth, usdt, dcu, 
            cofi,
            pusd,
            peth,

            fortGovernance,
            fortOptions, fortFutures,
            nestPriceFacade, fortSwap
        } = await deploy();

        console.log('ok');

        const newFortPRC44 = await FortPRC44.deploy();
        console.log('newFortPRC44: ' + newFortPRC44.address);

        const newFortPRCSwap = await FortPRCSwap.deploy();
        console.log('newFortPRCSwap: ' + newFortPRCSwap.address);
    });
});
