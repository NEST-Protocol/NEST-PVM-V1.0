const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('32.NestBuybackPool-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();

        await nest.transfer(nestBuybackPool.address, 10000000000000000000000000n);
        await nest.transfer(owner.address, 10000000000000000000000000n);
        await dcu.transfer(owner.address, 100000000000000000000000n);
        
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
        
        if (true) {
            console.log('1. buy back');
            await dcu.approve(nestBuybackPool.address, toBigInt(100000000));
            await nestBuybackPool.swap(toBigInt(10));
            await listAccounts();
        }
    });
});
