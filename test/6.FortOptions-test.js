const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('6.FortOptions-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, fortOptions, fortFutures, nestPriceFacade, USDT_DECIMALS } = await deploy();

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const BLOCK = 100000;
        
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
                addr1: await getAccountInfo(addr1),
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

        if (true) {
            console.log('3. list1');
            console.log('tokenCount=' + await fortOptions.getOptionCount());
            let options = await fortOptions.list(0, 5, 0);
            console.log(options);

            options = await fortOptions.list(0, 5, 1);
            console.log(options);
        }

        if (true) {
            console.log('4. list2');

            console.log('tokenCount=' + await fortOptions.getOptionCount());
            await fortOptions.open(eth.address, 2450000000, true, 100000, toBigInt(1000), {
                value: toBigInt(0.01)
            });

            // await fortOptions.open(hbtc.address, 52450000000, false, 100000, toBigInt(100000), {
            //     value: toBigInt(0.02)
            // });
            console.log('tokenCount=' + await fortOptions.getOptionCount());
            let options = await fortOptions.list(0, 5, 0);
            console.log(options);

            options = await fortOptions.list(0, 5, 1);
            console.log(options);

            //let fot1 = await fortOptions.getOptionInfo(eth.address, 2450000000, true, 100000);
            //let fot2 = await fortOptions.getOptionInfo(hbtc.address, 52450000000, false, 100000);

            //console.log('fot1: ' + fot1.index);
            //console.log('fot2: ' + fot2.index);

            //console.log('fot1-name: ' + fot1);
            //console.log('fot2-name: ' + fot2);
        }
    });
});
