const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('34.NestFuturesWithPrice', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestBlindBox,
            nestNFTAuction, nestFuturesWithPrice,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();

        const tokens = [eth, nest, dcu];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestBuybackPool: await listBalances(nestBuybackPool, tokens)
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();
        await nest.transfer(owner.address, 100000000000000000000000000n);

        if (true) {
            console.log('1. directPost');
            await nestFuturesWithPrice.setDirectPoster(owner.address);
            await nestFuturesWithPrice.directPost([
                toBigInt(1.538461),
                toBigInt(66666666666),
                toBigInt(2000 / 20000)
            ]);
            await nestFuturesWithPrice.directPost([
                toBigInt(1.538461),
                toBigInt(66666666666),
                toBigInt(2000 / 20000)
            ]);
        }

        if (true) {
            console.log('1. buy');
            await listAccounts();
            await nestFuturesWithPrice.buy(eth.address, 5, true, toBigInt(1000));
            await listAccounts();
          
        }

        if (true) {
            console.log('2. sell');
            let receipt = await nestFuturesWithPrice.directPost([
                toBigInt(1.508461),
                toBigInt(66666666666),
                toBigInt(2000 / 20000)
            ]);
            await showReceipt(receipt);
            await nestFuturesWithPrice.sell(5, toBigInt(1000));
            await listAccounts();
        }
    });
});
