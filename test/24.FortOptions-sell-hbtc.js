const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('24.FortOptions-sell-hbtc', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, fortOptions, fortFutures, nestPriceFacade, USDT_DECIMALS } = await deploy();

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, toBigInt(3510, USDT_DECIMALS), 1);

        const BLOCK = 100000;
        await fortOptions.open(hbtc.address, '2450000000', true, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        // let fot = await fortOptions.getOptionInfo(
        //     hbtc.address,
        //     '2450000000',
        //     true,
        //     BLOCK
        // );
        let fot = { index: 0 };

        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address)) + 'dcu');
        console.log('owner: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)) + '(fot)');
        console.log();

        await fortOptions.sell(fot.index, await fortOptions.balanceOf(fot.index, owner.address), { value: toBigInt(0.01) });
        console.log('After sell');
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address)) + 'dcu');
        console.log('owner: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)) + '(fot)');
    });
});
