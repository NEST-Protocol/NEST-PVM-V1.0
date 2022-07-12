const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('32.NestBuyBackPool-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability,
            nestPriceFacade, nestBuyBackPool, BLOCK_TIME, USDT_DECIMALS, cofixRouter
        } = await deploy();

        await nest.transfer(nestBuyBackPool.address, 10000000000000000000000000n);
        await nest.transfer(owner.address, 10000000000000000000000000n);
        await dcu.transfer(owner.address, 100000000000000000000000n);
        
        const tokens = [eth, nest, dcu];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestBuyBackPool: await listBalances(nestBuyBackPool, tokens)
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();
        
        if (true) {
            console.log('1. buy back');
            await dcu.approve(cofixRouter.address, toBigInt(100000000));
            await cofixRouter.swapExactTokensForTokens(
                // address[] calldata path,
                [dcu.address, nest.address],
                // uint amountIn,
                toBigInt(10),
                // uint amountOutMin,
                0,
                // address to,
                owner.address,
                // address rewardTo,
                owner.address,
                // uint deadline
                9999999999
            );
            await listAccounts();
        }
    });
});
