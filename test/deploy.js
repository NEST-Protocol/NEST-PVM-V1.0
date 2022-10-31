const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('deploy', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const NestProbability = await ethers.getContractFactory('NestProbability');

        const { 
            eth, usdt, nest, 
            cofi,
            pusd,
            peth,
            nestPRCSwap,

            nestCyberInk, nestNFTAuction,
            nestFuturesWithPrice,

            nestGovernance,
            nestOptions, nestFutures,
            nestPriceFacade
        } = await deploy();

        console.log('ok');

        console.log('count: ' + await nestFuturesWithPrice.getFutureCount());
    });
});
