const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances } = require('./utils.js');

describe('sample-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, nest, nestOptions, nestFutures, nestPriceFacade, USDT_DECIMALS } = await deploy();

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

        const BLOCK = 100000;
        await nestOptions.open(eth.address, toBigInt(2450, USDT_DECIMALS), true, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        console.log('block: ' + await ethers.provider.getBlockNumber()); 
        //const bot = await nestOptions.getOptionInfo(eth.address, '2450000000', true, BLOCK);
        const bot = { index: 0 };
        console.log('bot: ' + bot.index);
        console.log('owner: ' + toDecimal(await nest.balanceOf(owner.address)) + 'nest');
        console.log('owner: ' + toDecimal(await nestOptions.balanceOf(bot.index, owner.address)) + 'bot');

        await nestOptions.open(eth.address, toBigInt(2750, USDT_DECIMALS), false, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        // const bot2 = await nestOptions.getOptionInfo(eth.address, '2750000000', false, BLOCK);
        const bot2 = { index: 1 };
        console.log('bot2: ' + bot2.index);
        console.log('owner: ' + toDecimal(await nest.balanceOf(owner.address)) + 'nest');
        console.log('owner: ' + toDecimal(await nestOptions.balanceOf(bot2.index, owner.address)) + '[bot2]');

        // for(var i = 0; i < 100; ++i) {
        //     //await ethers.provider.sendTransaction({ from: owner.address, to: owner.address, value: 0});
        //     await nest.transfer(owner.address, 0);
        // }
        await nestOptions.exercise(bot.index, await nestOptions.balanceOf(bot.index, owner.address), {
            value: toBigInt(0.01)
        });

        console.log('owner: ' + toDecimal(await nest.balanceOf(owner.address)) + 'nest');
        console.log('owner: ' + toDecimal(await nestOptions.balanceOf(bot.index, owner.address)) + 'bot');

        console.log('------------------------------');

        //await nestFutures.create(eth.address, 2, true);
        await nestFutures.buy(eth.address, 2, true, toBigInt(100), {
            value: toBigInt(0.01)
        });

        // const queryPrice = async function(tokenAddress) {
        //     let tokenAmount = 1e18;
        //     let usdtAmount = (await nestPriceFacade.latestPriceView(usdt.address)).price;
        //     let decimals = 18;
        //     if (tokenAddress != eth.address) {
        //         decimals = await (await TestERC20.attach(tokenAddress)).decimals();
        //         tokenAmount = (await nestPriceFacade.latestPriceView(tokenAddress)).price;
        //     }
            
        //     return Math.floor(usdtAmount * 10 ** decimals / tokenAmount);
        // };

        // const lot = await nestFutures.getFutureInfo(eth.address, 2, true);

        // console.log('owner: ' + toDecimal(await nest.balanceOf(owner.address)) + 'nest');
        // let oraclePrice = await queryPrice(eth.address);
        // console.log('owner: ' + toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + 'lot');
        // for(var i = 0; i < 100; ++i) {
        //     //await ethers.provider.sendTransaction({ from: owner.address, to: owner.address, value: 0});
        //     await nest.transfer(owner.address, 0);
        // }
        // await nestFutures.sell(lot.index, toBigInt(1), {
        //     value: toBigInt(0.01)
        // });
        // console.log('owner: ' + toDecimal(await nest.balanceOf(owner.address)) + 'nest');
        // console.log('owner: ' + toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + 'lot');

        // // await nestOptions.open(usdt.address, '2450000000', true, 500, toBigInt(1), {
        // //     value: toBigInt(0.01)
        // // });

        // console.log('bot-name: ' + bot.index);
        // console.log('lot-name: ' + lot.index);
    });
});
