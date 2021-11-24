const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('HedgeSwap', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, hedgeOptions, hedgeFutures, nestPriceFacade, hedgeSwap } = await deploy();
        const TestERC20 = await ethers.getContractFactory('TestERC20');
        const nest = await TestERC20.deploy('NEST', 'NEST', 18);

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '100000000000000000000000000');
        
        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                nest: toDecimal(await nest.balanceOf(account), 18),
                dcu: toDecimal(await dcu.balanceOf(account), 18),
            };
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                hedgeSwap: await getAccountInfo(hedgeSwap),
            };
        }

        await dcu.setMinter(hedgeSwap.address, 1);
        await nest.transfer(owner.address, toBigInt(100000000));
        
        await hedgeSwap.setNestTokenAddress(nest.address);
        await nest.approve(hedgeSwap.address, toBigInt(300000000));
        //await dcu.approve(hedgeSwap.address, toBigInt(300000000));
        if (true) {
            console.log('1. deposit');
            await hedgeSwap.deposit(toBigInt(14999999));
            await hedgeSwap.deposit(toBigInt(1));
            console.log(await getStatus());
        }

        if (true) {
            console.log('2. 用400万dcu兑换nest');
            await dcu.transfer(hedgeSwap.address, toBigInt(1000000));
            console.log(await getStatus());
            let receipt = await hedgeSwap.swapForDCU(toBigInt(10));
            await showReceipt(receipt);
            console.log(await getStatus());
        }
    });
});
