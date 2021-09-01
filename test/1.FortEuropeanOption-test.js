const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const eth = { address: '0x0000000000000000000000000000000000000000' };
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

        const { usdt, hbtc, fort, fortEuropeanOption, fortLever, nestPriceFacade } = await deploy();

        await fort.setMinter(owner.address, 1);
        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address) )+ 'fort');
        console.log('owner: ' + owner.address);

        const FortOptionToken = await ethers.getContractFactory('FortOptionToken');
        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const BLOCK = 100000;
        await fortEuropeanOption.open(eth.address, '2450000000', true, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        let fot = await FortOptionToken.attach(await fortEuropeanOption.getEuropeanToken(
            eth.address,
            '2450000000',
            true,
            BLOCK
        ));
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fot.balanceOf(owner.address)) + '(' + await fot.name() + ')');
        await fortEuropeanOption.exercise(fot.address, await fot.balanceOf(owner.address), {
            value: toBigInt(0.01)
        });
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fot.balanceOf(owner.address)) + '(' + await fot.name() + ')');
        console.log();

        await fortEuropeanOption.open(hbtc.address, '47215470000', false, BLOCK, toBigInt(100000), {
            value: toBigInt(0.02)
        });
        fot = await FortOptionToken.attach(await fortEuropeanOption.getEuropeanToken(
            hbtc.address,
            '47215470000',
            false,
            BLOCK
        ));
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fot.balanceOf(owner.address)) + '(' + await fot.name() + ')');
        await fortEuropeanOption.exercise(fot.address, await fot.balanceOf(owner.address), {
            value: toBigInt(0.02)
        });
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fot.balanceOf(owner.address)) + '(' + await fot.name() + ')');
        console.log();
    });
});
