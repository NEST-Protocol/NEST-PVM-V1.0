const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const toBigInt = function(val, decimals) {
            decimals = decimals || 18;
            val = parseFloat(val.toString());
            val = val * 1000000;
            decimals -= 6;
            let bi = BigInt(val.toString());
            let BASE = BigInt(10);
            while (decimals > 0) {
                bi *= BASE;
                --decimals;
            }

            return bi;
        }

        const showReceipt = async function(receipt) {
            console.log({ gasUsed: (await receipt.wait()).gasUsed.toString() });
        }

        const toDecimal = function(bi, decimals) {
            decimals = decimals || 18;
            decimals = BigInt(decimals.toString());
            bi = BigInt(bi.toString());
            let BASE = BigInt(10);
            let r = '';
            while (decimals > 0) {
                let c = (bi % BASE).toString();
                r = c + r;
                bi /= BASE;

                --decimals;
            }
            r = bi.toString() + '.' + r;
            return r;
        }

        const { fort, fortEuropeanOption, fortLever } = await deploy();

        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address) )+ 'fort');

        console.log('owner: ' + owner.address);

        // await fortEuropeanOption.open(fort.address, '2450000000', true, 100, toBigInt(1));
        // console.log('block: ' + await ethers.provider.getBlockNumber()); 
        // const FortOptionToken = await ethers.getContractFactory('FortOptionToken');
        // const bot = await FortOptionToken.attach(
        //     await fortEuropeanOption.getBinaryToken(fort.address, '2450000000', true, 100)
        // );
        // console.log('bot: ' + bot.address);
        // console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        // console.log('owner: ' + toDecimal(await bot.balanceOf(owner.address)) + 'bot');
        // for(var i = 0; i < 100; ++i) {
        //     //await ethers.provider.sendTransaction({ from: owner.address, to: owner.address, value: 0});
        //     await fort.transfer(owner.address, 0);
        // }
        // await fortEuropeanOption.exercise(bot.address, await bot.balanceOf(owner.address));

        // console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        // console.log('owner: ' + toDecimal(await bot.balanceOf(owner.address)) + 'bot');
        // await greeter.deployed();
        // expect(await greeter.greet()).to.equal("Hello, world!");

        // await greeter.setGreeting("Hola, mundo!");
        // expect(await greeter.greet()).to.equal("Hola, mundo!");

        console.log('------------------------------');

        fortLever.buy(fort.address, 2, true, toBigInt(1));

        const FortLeverToken = await ethers.getContractFactory('FortLeverToken');
        const lot = await FortLeverToken.attach(await fortLever.getLeverToken(fort.address, 2, true));

        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await lot.balanceOf(owner.address)) + 'lot');

        for(var i = 0; i < 100; ++i) {
            //await ethers.provider.sendTransaction({ from: owner.address, to: owner.address, value: 0});
            await fort.transfer(owner.address, 0);
        }
        await fortLever.sell(lot.address, toBigInt(1));
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await lot.balanceOf(owner.address)) + 'lot');
    });
});
