const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('29.NestPRC-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, nestOptions, nestFutures, nestLPGuarantee, nestPRC44,
            nestPriceFacade, nestGovernance, BLOCK_TIME, USDT_DECIMALS 
        } = await deploy();

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        
        const tokens = [eth, nest, nestPRC44];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();

        const cfg = async function(tokenAddress) {
            let c = await nestOptions.getConfig(tokenAddress);
            return {
                sigmaSQ: c.sigmaSQ.toString(),
                miu: c.miu.toString(),
                minPeriod: c.minPeriod.toString()
            }
        }
        
        const align = function(price) {
            // let decimals = 0;
            // while (price >= 10000000) {
            //     price = Math.floor(price / 10);
            //     ++decimals;
            // }
            // return price * 10 ** decimals;
            return price;
        }

        await nest.transfer(owner.address, 10000000000000000000000000n);
        
        await nestPRC44.setMinter(owner.address, 1);
        await nestPRC44.mint(owner.address, toBigInt(10000));

        await listAccounts();

        if (true) {
            console.log('1. roll');
            await nestPRC44.roll44(10000, 30000);
            await listAccounts();
        }
        if (false) {
            console.log('2. claim');
            for (var i = 0; i < 256; ++i) {
                console.log('gained: ' + (await nestPRC44.list44(0, 1, 0))[0].gained.toString());
                await nest.transfer(owner.address, 0);
            }
            await nestPRC44.claim(0);
            await listAccounts();
        }
        if (true) {
            console.log('3. batchClaim');
            for (var i = 0; i < 256; ++i) {
                console.log('gained: ' + (await nestPRC44.list44(0, 1, 0))[0].gained.toString());
                await nest.transfer(owner.address, 0);
            }
            await nestPRC44.batchClaim44([0]);
            await listAccounts();
        }
    });
});
