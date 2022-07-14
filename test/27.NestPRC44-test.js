const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('27.NestProbability-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, nest, nestPRCSwap, nestProbability, BLOCK_TIME, USDT_DECIMALS } = await deploy();
        const TestERC20 = await ethers.getContractFactory('TestERC20');
        await nest.transfer(owner.address, 10000000000000000000000000n);
        
        const tokens = [eth, usdt, nest];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();

        if (true) {
            console.log('2. roll44');
            
            for (var i = 0; i < 1; ++i) {
                await nestProbability.roll44(1, 20000);
                for (var j = 0; j < 2; ++j) {
                    await usdt.transfer(owner.address, 0);
                }
                await nestProbability.claim44(0);
                console.log('roll ' + i + ': ');
                await listAccounts();
            }
        }
    });
});
