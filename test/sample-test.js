const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt } = require('./utils.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, fort, fortEuropeanOption, fortLever } = await deploy();

        await fort.setMinter(owner.address, 1);
        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address) )+ 'fort');
        console.log('owner: ' + owner.address);

        const BLOCK = 100000;
        await fortEuropeanOption.open(eth.address, '2450000000', true, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        console.log('block: ' + await ethers.provider.getBlockNumber()); 
        const FortOptionToken = await ethers.getContractFactory('FortOptionToken');
        const bot = await FortOptionToken.attach(
            await fortEuropeanOption.getEuropeanToken(eth.address, '2450000000', true, BLOCK)
        );
        console.log('bot: ' + bot.address);
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await bot.balanceOf(owner.address)) + 'bot');

        await fortEuropeanOption.open(eth.address, '2750000000', false, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        const bot2 = await FortOptionToken.attach(
            await fortEuropeanOption.getEuropeanToken(eth.address, '2750000000', false, BLOCK)
        );
        console.log('bot: ' + bot.address);
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await bot2.balanceOf(owner.address)) + '[' + await bot2.name() + ']');

        // for(var i = 0; i < 100; ++i) {
        //     //await ethers.provider.sendTransaction({ from: owner.address, to: owner.address, value: 0});
        //     await fort.transfer(owner.address, 0);
        // }
        await fortEuropeanOption.exercise(bot.address, await bot.balanceOf(owner.address), {
            value: toBigInt(0.01)
        });

        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await bot.balanceOf(owner.address)) + 'bot');

        console.log('------------------------------');

        //await fortLever.create(eth.address, 2, true);
        await fortLever.buy(eth.address, 2, true, toBigInt(100), {
            value: toBigInt(0.01)
        });

        const FortLeverToken = await ethers.getContractFactory('FortLeverToken');
        const lot = await FortLeverToken.attach(await fortLever.getLeverToken(eth.address, 2, true));

        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await lot.balanceOf(owner.address)) + 'lot');

        for(var i = 0; i < 100; ++i) {
            //await ethers.provider.sendTransaction({ from: owner.address, to: owner.address, value: 0});
            await fort.transfer(owner.address, 0);
        }
        await fortLever.sell(lot.address, toBigInt(1), {
            value: toBigInt(0.01)
        });
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await lot.balanceOf(owner.address)) + 'lot');

        // await fortEuropeanOption.open(usdt.address, '2450000000', true, 500, toBigInt(1), {
        //     value: toBigInt(0.01)
        // });

        console.log('bot-name: ' + await bot.name());
        console.log('lot-name: ' + await lot.name());
    });
});
