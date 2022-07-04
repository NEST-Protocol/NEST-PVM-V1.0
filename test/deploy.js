const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

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
            fortPRC,
            fortPRCSwap,

            fortGovernance,
            fortOptions, fortFutures,
            nestPriceFacade, fortSwap
        } = await deploy();

        console.log('ok');
    });
});
