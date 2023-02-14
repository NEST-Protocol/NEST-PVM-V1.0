const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI, FEQ } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('40.NestFutures3', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction, nestFutures3, nestVault,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();

        const tokens = [eth, nest, dcu];
        let previous;
        let accounts;
        const listAccounts = async function() {
            previous = accounts;
            accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestVault: await listBalances(nestVault, tokens),
                addr2: await listBalances(addr2, tokens)
            };
            console.log(accounts);
            return accounts;
        }
        const MIU_LONG = 3.4722222222016014E-09;
        const Rt = function(L, St, S0, seconds) {
            return L * (St / S0 / (1 + MIU_LONG * seconds) - 1);
        };

        const NEST_BASE = 10000;
        const ownerNestBalance = 100000000000000000000000000n;

        await nest.transfer(owner.address, ownerNestBalance);
        await nestFutures3.init();
        await listAccounts();

        await nestFutures3.directPost3(200, [toBigInt(2000/1250), toBigInt(2000/250), toBigInt(2000/16000)]);
        if (true) {
            console.log('1. buy3');
            console.log(UI(await nestFutures3.getChannelParameter(0)));
            await nestFutures3.buy3(0, 7, true, 1000 * NEST_BASE);
            console.log(UI(await nestFutures3.getChannelParameter(0)));
            await listAccounts();
            await nestFutures3.buy3(0, 7, true, 1000 * NEST_BASE);
            console.log(UI(await nestFutures3.getChannelParameter(0)));
            await listAccounts();
            await nestFutures3.buy3(0, 7, false, 10000 * NEST_BASE);
            console.log(UI(await nestFutures3.getChannelParameter(0)));
            await listAccounts();
            for (var i = 0; i < 3; i++) {
                await nest.transfer(owner.address, 0);
            }
            await nestFutures3.buy3(0, 7, true, 1000 * NEST_BASE);
            console.log(UI(await nestFutures3.getChannelParameter(0)));
            await listAccounts();
        }

        if (true) {
            console.log('2. sell3');
            await nestFutures3.sell3(0, 0);
            console.log(UI(await nestFutures3.getChannelParameter(0)));
            await listAccounts();
            await nestFutures3.sell3(0, 1);
            console.log(UI(await nestFutures3.getChannelParameter(0)));
            await listAccounts();
            await nestFutures3.sell3(0, 2);
            console.log(UI(await nestFutures3.getChannelParameter(0)));
            await listAccounts();
            await nestFutures3.sell3(0, 3);
            console.log(UI(await nestFutures3.getChannelParameter(0)));
            await listAccounts();
            return;
        }

        if (false) {
            console.log('2. sell2');
            await nestFutures2.directPost(200, [toBigInt(2000/2000), toBigInt(2000/200), toBigInt(2000/10000)]);
            await nestFutures2.sell2(0);
            
            await listAccounts();
            const totalNest = 1000 * (1 + Rt(7, 2000, 1250, 3 * 4)) - 1000 * 7 * 2000 / 1250 * 0.002;

            FEQ({
                a: parseFloat(accounts.owner.NEST),
                b: parseFloat(previous.owner.NEST) + totalNest,
                d: 0.000000000001
            });
            FEQ({
                a: parseFloat(accounts.nestVault.NEST),
                b: parseFloat(previous.nestVault.NEST) - totalNest,
                d: 0.000000000001
            });
        } else if (false) {
            console.log('3. add2');
            await nestFutures2.directPost(200, [toBigInt(2000/2000), toBigInt(2000/200), toBigInt(2000/10000)]);
            await nestFutures2.add2(0, 2000 * NEST_BASE);
            
            await listAccounts();
            const totalNest = 2000 + 2000 * 7 * 0.002;

            console.log(UI(await nestFutures2.list2(0, 1, 1)));

            FEQ({
                a: parseFloat(accounts.owner.NEST),
                b: parseFloat(previous.owner.NEST) - totalNest,
                d: 0.000000000001
            });
            FEQ({
                a: parseFloat(accounts.nestVault.NEST),
                b: parseFloat(previous.nestVault.NEST) + totalNest,
                d: 0.000000000001
            });

            const newPrice = (1000 + 2000) * 1250 * 2000 / (1250 * 2000 + 2000 * 1000 / (1 + MIU_LONG * 3 * 4));
            FEQ({
                a: toDecimal((await nestFutures2.list2(0, 1, 1))[0].basePrice),
                b: newPrice,
                d: 0.00000000001
            });
        } else if (true) {
            console.log('4. liquidate2');
            await nestFutures2.directPost(200, [toBigInt(1.862934), toBigInt(2000/200), toBigInt(0.145545)]);
            await nestFutures2.connect(addr2).liquidate2([2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1]);
            await nestFutures2.connect(addr2).liquidate2([2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1]);
            
            await listAccounts();
            console.log(UI(await nestFutures2.list2(0, 3, 0)));

            const nest1 = 1000 * (1 + Rt(7, 2000 / 1.862934, 1250, 3 * 4));
            const nest2 = 8000 * (1 + Rt(7, 2000 / 0.145545, 16000, 3 * 3));
            const nest3 = 5000 * (1 + Rt(7, 2000 / 1.862934, 1250, 3 * 2));

            console.log({ nest1: nest1, nest2: nest2, nest3: nest3 });
            
            FEQ({
                a: parseFloat(previous.addr2.NEST) + nest1 + nest2 + nest3,
                b: parseFloat(accounts.addr2.NEST),
                d: 0.000000001
            });
            FEQ({
                a: parseFloat(previous.nestVault.NEST) - (nest1 + nest2 + nest3),
                b: parseFloat(accounts.nestVault.NEST),
                d: 0.000000001
            });
        }
    });
});
