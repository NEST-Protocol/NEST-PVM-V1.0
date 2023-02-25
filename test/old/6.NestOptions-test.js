const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('6.NestOptions-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, nest, nestOptions, nestFutures, nestPriceFacade, USDT_DECIMALS } = await deploy();

        await nest.transfer(owner.address, 10000000000000000000000000n);
        
        const tokens = [eth, usdt, nest];
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

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const BLOCK = 100000;

        const cfg = async function(tokenAddress) {
            let c = await nestOptions.getConfig(tokenAddress);
            return {
                sigmaSQ: c.sigmaSQ.toString(),
                miu: c.miu.toString(),
                minPeriod: c.minPeriod.toString()
            }
        }

        if (true) {
            console.log('3. list1');
            console.log('tokenCount=' + await nestOptions.getOptionCount());
            let options = await nestOptions.list(0, 5, 0);
            console.log(options);

            options = await nestOptions.list(0, 5, 1);
            console.log(options);
        }

        if (true) {
            console.log('4. list2');

            console.log('tokenCount=' + await nestOptions.getOptionCount());
            await nestOptions.open(eth.address, 2450000000, true, 100000, toBigInt(1000), {
                value: toBigInt(0.01)
            });

            // await nestOptions.open(hbtc.address, 52450000000, false, 100000, toBigInt(100000), {
            //     value: toBigInt(0.02)
            // });
            console.log('tokenCount=' + await nestOptions.getOptionCount());
            let options = await nestOptions.list(0, 5, 0);
            console.log(options);

            options = await nestOptions.list(0, 5, 1);
            console.log(options);

            //let fot1 = await nestOptions.getOptionInfo(eth.address, 2450000000, true, 100000);
            //let fot2 = await nestOptions.getOptionInfo(hbtc.address, 52450000000, false, 100000);

            //console.log('fot1: ' + fot1.index);
            //console.log('fot2: ' + fot2.index);

            //console.log('fot1-name: ' + fot1);
            //console.log('fot2-name: ' + fot2);
        }
    });
});
