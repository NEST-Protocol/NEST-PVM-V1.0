const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('39.NestFutures2-algorithm', function() {
    it('First', async function() {
        const NestRedeem = await ethers.getContractFactory('NestRedeem');
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction, nestFuturesWithPrice, nestVault,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();
        const nestRedeem = await NestRedeem.deploy(dcu.address, nest.address, toBigInt(0.5));

        const tokens = [eth, nest, dcu];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestVault: await listBalances(nestVault, tokens),
                addr2: await listBalances(addr2, tokens)
            };
            console.log(accounts);
            return accounts;
        }

        const NEST_BASE = 10000;
        const nestFutures2 = nestFuturesWithPrice;
        const ownerNestBalance = 100000000000000000000000000n;

        await nest.transfer(owner.address, ownerNestBalance);
        await nestFutures2.init();
        let accounts = await listAccounts();

        await nestFutures2.directPost(200, [toBigInt(2000/1250), toBigInt(2000/250), toBigInt(2000/16000)]);
        if (true) {
            console.log('1. buy2');
            await nestFutures2.buy2(0, 7, true, 1000 * NEST_BASE, toBigInt(1200));
            let newAccounts = await listAccounts();

            const totalNest = toBigInt(1000 + 1000 * 7 * 0.002);
            expect(newAccounts.owner.NEST).to.eq(toDecimal(toBigInt(accounts.owner.NEST) - totalNest));
            expect(newAccounts.nestVault.NEST).to.eq(toDecimal(toBigInt(accounts.nestVault.NEST) + totalNest));
            accounts = newAccounts;

            console.log(await nestFutures2.list2(0, 1, 0));
            await nestFutures2.buy2(1, 7, true, 8000 * NEST_BASE, toBigInt(12000));
            await nestFutures2.buy2(0, 7, true, 5000 * NEST_BASE, toBigInt(1200));
        }

        const MIU_LONG = 3.4722222222016014E-09;
        const Rt = function(L, St, S0, seconds) {
            return L * (St / S0 / (1 + MIU_LONG * seconds) - 1);
        };
        const FEQ = function(o) {
            console.log(o);
            expect(Math.abs(parseFloat(o.a) - parseFloat(o.b))).to.lt(o.d);
        };

        if (false) {
            console.log('2. sell2');
            await nestFutures2.directPost(200, [toBigInt(2000/2000), toBigInt(2000/200), toBigInt(2000/10000)]);
            await nestFutures2.sell2(0);
            
            let newAccounts = await listAccounts();
            const totalNest = 1000 * (1 + Rt(7, 2000, 1250, 3 * 2)) - 1000 * 7 * 2000 / 1250 * 0.002;

            FEQ({
                a: parseFloat(newAccounts.owner.NEST),
                b: parseFloat(accounts.owner.NEST) + totalNest,
                d: 0.000000000001
            });
            FEQ({
                a: parseFloat(newAccounts.nestVault.NEST),
                b: parseFloat(accounts.nestVault.NEST) - totalNest,
                d: 0.000000000001
            });
        } else if (false) {
            console.log('3. add2');
            await nestFutures2.directPost(200, [toBigInt(2000/2000), toBigInt(2000/200), toBigInt(2000/10000)]);
            await nestFutures2.add2(0, 2000 * NEST_BASE);
            
            let newAccounts = await listAccounts();
            const totalNest = 2000 + 2000 * 7 * 0.002;

            console.log(UI(await nestFutures2.list2(0, 1, 0)));

            FEQ({
                a: parseFloat(newAccounts.owner.NEST),
                b: parseFloat(accounts.owner.NEST) - totalNest,
                d: 0.000000000001
            });
            FEQ({
                a: parseFloat(newAccounts.nestVault.NEST),
                b: parseFloat(accounts.nestVault.NEST) + totalNest,
                d: 0.000000000001
            });

            const newPrice = (1000 + 2000) * 1250 * 2000 / (1250 * 2000 + 2000 * 1000 / (1 + MIU_LONG * 3 * 2));
            FEQ({
                a: toDecimal((await nestFutures2.list2(0, 1, 0))[0].basePrice),
                b: newPrice,
                d: 0.00000000001
            });
        } else if (true) {
            console.log('4. liquidate2');
            await nestFutures2.directPost(200, [toBigInt(1.862934), toBigInt(2000/200), toBigInt(0.145545)]);
            await nestFutures2.connect(addr2).liquidate2([2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1]);
            
            let newAccounts = await listAccounts();
            console.log(UI(await nestFutures2.list2(0, 3, 0)));
        }
    });
});
