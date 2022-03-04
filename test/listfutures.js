const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const FortOptions = await ethers.getContractFactory('FortOptions');
        const FortFutures = await ethers.getContractFactory('FortFutures');

        const { 
            eth, usdt, dcu, hbtc,
            cofi,
            pusd,
            peth,

            hedgeGovernance,
            hedgeOptions, hedgeFutures,
            fortOptions, fortFutures,
            nestPriceFacade, hedgeSwap
        } = await deploy();

        console.log('ok');

        {
            let count = await hedgeFutures.getFutureCount();
            console.log('count: ' + count);
            let futures = await hedgeFutures.find(0, 20, 1000, '0x5fa1dd7f6DCE7066d8be8B8787575d66a20Dc44C');

            for (var i = 0; i < futures.length; ++i) {
                let future = futures[i];
                let f = {
                    index: future.index.toString(),
                    tokenAddress: future.tokenAddress.toString(),
                    lever: future.lever.toString(),
                    orientation: future.orientation.toString(),
                    
                    balance: future.balance.toString(),
                    // Base price
                    basePrice: future.basePrice.toString(),
                    // Base block
                    baseBlock: future.baseBlock.toString()
                }
                console.log(f);
            }
        }
    });
});
