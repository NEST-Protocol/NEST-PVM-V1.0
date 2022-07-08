const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('19.NestGovernance-test', function() {
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
            console.log('1. initialize');
            //await nestGovernance.initialize(eth.address);
            //await nestGovernance.initialize(nestGovernance.address);
        }

        if (true) {
            console.log('2. getGovernance');
            //await nestGovernance.initialize(eth.address);
            console.log('gov: ' + await nestGovernance.getGovernance(nestGovernance.address));
            console.log('addr1: ' + await nestGovernance.getGovernance(addr1.address));
            console.log('owner: ' + await nestGovernance.getGovernance(owner.address));
            console.log();

            await nestGovernance.setGovernance(addr1.address, 1);
            
            console.log('gov: ' + await nestGovernance.getGovernance(nestGovernance.address));
            console.log('addr1: ' + await nestGovernance.getGovernance(addr1.address));
            console.log('owner: ' + await nestGovernance.getGovernance(owner.address));
            console.log();

            console.log('gov: ' + await nestGovernance.checkGovernance(nestGovernance.address, 0));
            console.log('addr1: ' + await nestGovernance.checkGovernance(addr1.address, 0));
            console.log('owner: ' + await nestGovernance.checkGovernance(owner.address, 0));
            console.log();

            await nestGovernance.setGovernance(nestGovernance.address, 7);
            
            console.log('gov: ' + await nestGovernance.getGovernance(nestGovernance.address));
            console.log('addr1: ' + await nestGovernance.getGovernance(addr1.address));
            console.log('owner: ' + await nestGovernance.getGovernance(owner.address));
        }
    });
});
