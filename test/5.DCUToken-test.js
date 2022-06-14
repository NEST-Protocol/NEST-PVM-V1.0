const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('5.DCUToken-test', function() {
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

        if (true) {
            console.log('1. Show balance');
            console.log(await getStatus());
        }

        if (true) {
            console.log('2. Transfer 20000dcu to addr1');
            await dcu.transfer(addr1.address, toBigInt(20000));
            console.log(await getStatus());
        }

        if (true) {
            console.log('4. Remove owner from minters');
            console.log('checkMinter:' + await dcu.checkMinter(owner.address));
            await dcu.setMinter(owner.address, 0);
            console.log('checkMinter:' + await dcu.checkMinter(owner.address));
            await dcu.setMinter(owner.address, 1);
            console.log('checkMinter:' + await dcu.checkMinter(owner.address));
        }

        if (true) {
            console.log('3. Mint 300dcu to addr1')
            await dcu.mint(addr1.address, toBigInt(300));
            console.log(await getStatus());
        }

        if (true) {
            console.log('5. Burn 700dcu fron addr1');
            await dcu.burn(addr1.address, toBigInt(700));
            console.log(await getStatus());
        }
    });
});
