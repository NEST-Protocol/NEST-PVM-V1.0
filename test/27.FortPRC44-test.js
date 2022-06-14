const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('27.FortPRC44-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, cofixRouter, fortPRCSwap, fortPRC44, BLOCK_TIME, USDT_DECIMALS } = await deploy();
        const TestERC20 = await ethers.getContractFactory('TestERC20');
        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), USDT_DECIMALS),
                dcu: toDecimal(await dcu.balanceOf(account), 18),
                fortPRC44: toDecimal(await fortPRC44.balanceOf(account), 18),
            };
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                fortPRCSwap: await getAccountInfo(fortPRCSwap),
            };
        }

        await fortPRC44.setMinter(owner.address, 1);
        await fortPRC44.mint(fortPRCSwap.address, toBigInt(5000000));
        console.log(await getStatus());

        if (true) {
            console.log('1. buy prc');
            await dcu.approve(cofixRouter.address, toBigInt(1000000));
            await cofixRouter.swapExactTokensForTokens(
                [dcu.address, fortPRC44.address],
                toBigInt(10000),
                0,
                owner.address,
                owner.address,
                9999999999n
            );
            console.log(await getStatus());
        }

        if (true) {
            console.log('2. roll44');
            
            for (var i = 0; i < 1; ++i) {
                await fortPRC44.roll44(1, 20000);
                for (var j = 0; j < 2; ++j) {
                    await usdt.transfer(owner.address, 0);
                }
                await fortPRC44.claim44(0);
                console.log('roll ' + i + ': ');
                console.log(await getStatus());
            }
        }
    });
});
