const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('17.NestFrequentlyUsed-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, 
            nestOptions, nestFutures, nestPriceFacade, nestGovernance,
            USDT_DECIMALS
        } = await deploy();

        await nest.transfer(owner.address, 10000000000000000000000000n);
        
        const tokens = [eth, nest];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                addr1: await listBalances(addr1, tokens),
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();

        const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const cfg = async function(tokenAddress) {
            let c = await nestOptions.getConfig(tokenAddress);
            return {
                sigmaSQ: c.sigmaSQ.toString(),
                miu: c.miu.toString(),
                minPeriod: c.minPeriod.toString()
            }
        }
        
        const align = function(price) {
            let decimals = 0;
            while (price >= 10000000) {
                price = Math.floor(price / 10);
                ++decimals;
            }
            return price * 10 ** decimals;
        }

        if (true) {
            console.log('1. update');
            await nestOptions.update(nestGovernance.address);
            await nestOptions.update(nestGovernance.address);
            await nestOptions.update(nestGovernance.address);
            await nestOptions.update(nestGovernance.address);
            await nestOptions.update(nestGovernance.address);
            await nestOptions.update(nestGovernance.address);
        }

        if (true) {
            console.log('2. setUsdtTokenAddress');
            //await nestOptions.setUsdtTokenAddress(nestGovernance.address);
        }
    });
});
