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

        console.log('fortPRC: ' + fortPRC.address);
        console.log('fortPRCSwap: ' + fortPRCSwap.address);

        {
            let list = await fortPRC.list44(0, 5, 0);
            console.log(UI(list));
        }
        {
            console.log('fortPRC.totalSupply: ' + toDecimal(await fortPRC.totalSupply()));
            console.log('dcu.totalSupply: ' + toDecimal(await dcu.totalSupply()));
            console.log('fortPRCSwap.dcu: ' + toDecimal(await dcu.balanceOf(fortPRCSwap.address)));
            console.log('fortPRCSwap.fortPRC: ' + toDecimal(await fortPRC.balanceOf(fortPRCSwap.address)));
        }
    });
});
