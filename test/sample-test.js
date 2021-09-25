const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt } = require('./utils.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, fort, fortEuropeanOption, fortLever, nestPriceFacade } = await deploy();

        await fort.setMinter(owner.address, 1);
        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address) )+ 'fort');
        console.log('owner: ' + owner.address);

        const BLOCK = 100000;
        await fortEuropeanOption.open(eth.address, '2450000000', true, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        console.log('block: ' + await ethers.provider.getBlockNumber()); 
        //const FortOptionToken = await ethers.getContractFactory('FortOptionToken');
        const bot = await fortEuropeanOption.getOptionInfo(eth.address, '2450000000', true, BLOCK);
        console.log('bot: ' + bot.index);
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fortEuropeanOption.balanceOf(bot.index, owner.address)) + 'bot');

        await fortEuropeanOption.open(eth.address, '2750000000', false, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        const bot2 = await fortEuropeanOption.getOptionInfo(eth.address, '2750000000', false, BLOCK);
        console.log('bot2: ' + bot2.index);
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fortEuropeanOption.balanceOf(bot2.index, owner.address)) + '[bot2]');

        // for(var i = 0; i < 100; ++i) {
        //     //await ethers.provider.sendTransaction({ from: owner.address, to: owner.address, value: 0});
        //     await fort.transfer(owner.address, 0);
        // }
        await fortEuropeanOption.exercise(bot.index, await fortEuropeanOption.balanceOf(bot.index, owner.address), {
            value: toBigInt(0.01)
        });

        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fortEuropeanOption.balanceOf(bot.index, owner.address)) + 'bot');

        console.log('------------------------------');

        //await fortLever.create(eth.address, 2, true);
        await fortLever.buy(eth.address, 2, true, toBigInt(100), {
            value: toBigInt(0.01)
        });

        const queryPrice = async function(tokenAddress) {
            let tokenAmount = 1e18;
            let usdtAmount = (await nestPriceFacade.latestPriceView(usdt.address)).price;
            let decimals = 18;
            if (tokenAddress != eth.address) {
                decimals = await (await TestERC20.attach(tokenAddress)).decimals();
                tokenAmount = (await nestPriceFacade.latestPriceView(tokenAddress)).price;
            }
            
            return Math.floor(usdtAmount * 10 ** decimals / tokenAmount);
        };

        //const FortLeverToken = await ethers.getContractFactory('FortLeverToken');
        const lot = await fortLever.getLeverInfo(eth.address, 2, true);

        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        let oraclePrice = await queryPrice(eth.address);
        console.log('owner: ' + toDecimal(await fortLever.balanceOf(lot.index, oraclePrice, owner.address)) + 'lot');

        for(var i = 0; i < 100; ++i) {
            //await ethers.provider.sendTransaction({ from: owner.address, to: owner.address, value: 0});
            await fort.transfer(owner.address, 0);
        }
        await fortLever.sell(lot.index, toBigInt(1), {
            value: toBigInt(0.01)
        });
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fortLever.balanceOf(lot.index, oraclePrice, owner.address)) + 'lot');

        // await fortEuropeanOption.open(usdt.address, '2450000000', true, 500, toBigInt(1), {
        //     value: toBigInt(0.01)
        // });

        console.log('bot-name: ' + bot.index);
        console.log('lot-name: ' + lot.index);
    });
});
