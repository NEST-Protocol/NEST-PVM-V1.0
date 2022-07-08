const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('27.NestPRC44-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, nest, cofixRouter, nestPRCSwap, nestPRC44, BLOCK_TIME, USDT_DECIMALS } = await deploy();
        const TestERC20 = await ethers.getContractFactory('TestERC20');
        await nest.transfer(owner.address, 10000000000000000000000000n);
        
        const tokens = [eth, usdt, nest, nestPRC44];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestPRCSwap: await listBalances(nestPRCSwap, tokens),
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();

        await nestPRC44.setMinter(owner.address, 1);
        await nestPRC44.mint(nestPRCSwap.address, toBigInt(5000000));
        await listAccounts();

        if (true) {
            console.log('1. buy prc');
            await nest.approve(cofixRouter.address, toBigInt(1000000));
            await cofixRouter.swapExactTokensForTokens(
                [nest.address, nestPRC44.address],
                toBigInt(10000),
                0,
                owner.address,
                owner.address,
                9999999999n
            );
            await listAccounts();
        }

        if (true) {
            console.log('2. roll44');
            
            for (var i = 0; i < 1; ++i) {
                await nestPRC44.roll44(1, 20000);
                for (var j = 0; j < 2; ++j) {
                    await usdt.transfer(owner.address, 0);
                }
                await nestPRC44.claim44(0);
                console.log('roll ' + i + ': ');
                await listAccounts();
            }
        }
    });
});
