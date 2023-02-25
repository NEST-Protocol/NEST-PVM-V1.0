const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('24.NestOptions-sell-hbtc', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, nest, nestOptions, nestFutures, nestPriceFacade, USDT_DECIMALS } = await deploy();

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

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, toBigInt(3510, USDT_DECIMALS), 1);

        const BLOCK = 100000;
        await nestOptions.open(hbtc.address, '2450000000', true, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        // let fot = await nestOptions.getOptionInfo(
        //     hbtc.address,
        //     '2450000000',
        //     true,
        //     BLOCK
        // );
        let fot = { index: 0 };

        console.log('owner: ' + toDecimal(await nest.balanceOf(owner.address)) + 'nest');
        console.log('owner: ' + toDecimal(await nestOptions.balanceOf(fot.index, owner.address)) + '(fot)');
        console.log();

        await nestOptions.sell(fot.index, await nestOptions.balanceOf(fot.index, owner.address), { value: toBigInt(0.01) });
        console.log('After sell');
        console.log('owner: ' + toDecimal(await nest.balanceOf(owner.address)) + 'nest');
        console.log('owner: ' + toDecimal(await nestOptions.balanceOf(fot.index, owner.address)) + '(fot)');
    });
});
