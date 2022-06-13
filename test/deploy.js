const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('FortOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const FortOptions = await ethers.getContractFactory('FortOptions');
        const FortFutures = await ethers.getContractFactory('FortFutures');

        const { 
            eth, usdt, dcu, hbtc,
            cofi,
            pusd,
            peth,

            fortGovernance,
            fortOptions, fortFutures,
            fortLPGuarantee,
            nestPriceFacade, hedgeSwap
        } = await deploy();

        console.log('ok');
    });
});
