const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, dcu, 
            fortOptions, fortFutures, nestPriceFacade, fortGovernance,
            fortVaultForStaking, fortDAO, USDT_DECIMALS
        } = await deploy();

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), USDT_DECIMALS),
                dcu: toDecimal(await dcu.balanceOf(account), 18),
            };
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                dcu: await getAccountInfo(dcu),
                fortDAO: await getAccountInfo(fortDAO),
            };
        }

        const cfg = async function(tokenAddress) {
            let c = await fortOptions.getConfig(tokenAddress);
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
            //await fortGovernance.initialize(eth.address);
            //await fortGovernance.initialize(fortGovernance.address);
        }

        if (true) {
            console.log('2. getGovernance');
            //await fortGovernance.initialize(eth.address);
            console.log('gov: ' + await fortGovernance.getGovernance(fortGovernance.address));
            console.log('addr1: ' + await fortGovernance.getGovernance(addr1.address));
            console.log('owner: ' + await fortGovernance.getGovernance(owner.address));
            console.log();

            await fortGovernance.setGovernance(addr1.address, 1);
            
            console.log('gov: ' + await fortGovernance.getGovernance(fortGovernance.address));
            console.log('addr1: ' + await fortGovernance.getGovernance(addr1.address));
            console.log('owner: ' + await fortGovernance.getGovernance(owner.address));
            console.log();

            console.log('gov: ' + await fortGovernance.checkGovernance(fortGovernance.address, 0));
            console.log('addr1: ' + await fortGovernance.checkGovernance(addr1.address, 0));
            console.log('owner: ' + await fortGovernance.checkGovernance(owner.address, 0));
            console.log();

            await fortGovernance.setGovernance(fortGovernance.address, 7);
            
            console.log('gov: ' + await fortGovernance.getGovernance(fortGovernance.address));
            console.log('addr1: ' + await fortGovernance.getGovernance(addr1.address));
            console.log('owner: ' + await fortGovernance.getGovernance(owner.address));
        }
    });
});
