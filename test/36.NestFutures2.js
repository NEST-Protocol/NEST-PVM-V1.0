const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('36.NestFutures2', function() {
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
                nestRedeem: await listBalances(nestRedeem, tokens)
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();
        await nest.transfer(owner.address, 100000000000000000000000000n);
        await nestFuturesWithPrice.init();

        if (true) {
            console.log('1. directPost');
            await nestFuturesWithPrice.directPost(200, [
                toBigInt(1.538461),
                toBigInt(66666666666),
                toBigInt(2000 / 20000)
            ]);
            await nestFuturesWithPrice.directPost(200, [
                toBigInt(1.538461),
                toBigInt(66666666666),
                toBigInt(2000 / 20000)
            ]);
        }

        const NEST_BASE = 10000;
        if (true) {
            console.log('1. buy');
            await nestFuturesWithPrice.buy2(0, 5, true, 1000 * NEST_BASE, 0);
            await listAccounts();
          
        }

        if (true) {
            console.log('2. sell');
            let receipt = await nestFuturesWithPrice.directPost(200, [
                toBigInt(1.508461),
                toBigInt(66666666666),
                toBigInt(2000 / 20000)
            ]);
            await showReceipt(receipt);
            await nestFuturesWithPrice.add2(0, 1000 * NEST_BASE);
            //await nestFuturesWithPrice.sell2(0);
            await listAccounts();
        }

        if (true) {
            console.log('3. listPrice');

            let prices = await nestFuturesWithPrice.listPrice(0, 0, 4, 1);
            for (var i = 0; i < prices.length; i += 3) {
                console.log({ 
                    period: prices[i].toString(),
                    height: prices[i + 1].toString(),
                    price: toDecimal(prices[i + 2].toString())
                });
            }
        }

        if (true) {
            console.log('4. buy');
            await nestFuturesWithPrice.buy2(0, 5, true, 1000 * NEST_BASE, 0);
            await listAccounts();
        }

        if (false) {
            console.log('5. sell');
            let receipt = await nestFuturesWithPrice.directPost(200, [
                toBigInt(1.508461),
                toBigInt(66666666666),
                toBigInt(2000 / 20000)
            ]);
            await showReceipt(receipt);
            await nestFuturesWithPrice.sell2(1);
            await listAccounts();
        }

        if (true) {
            console.log('6. listPrice');

            let prices = await nestFuturesWithPrice.listPrice(0, 0, 5, 1);
            for (var i = 0; i < prices.length; i += 3) {
                console.log({ 
                    period: prices[i].toString(),
                    height: prices[i + 1].toString(),
                    price: toDecimal(prices[i + 2].toString())
                });
            }
        }

        if (true) {
            console.log('7. findPrice');
            let p = await nestFuturesWithPrice.findPrice(0, 78);
            console.log(UI(p));
        }

        if (true) {
            console.log('8. liquidate2');
            let receipt = await nestFuturesWithPrice.directPost(200, [
                toBigInt(1.858461),
                toBigInt(66666666666),
                toBigInt(2000 / 20000)
            ]);

            console.log(UI(await nestFuturesWithPrice.list2(0, 3, 0)));
            await nestFuturesWithPrice.liquidate2([1]);
            console.log(UI(await nestFuturesWithPrice.list2(0, 3, 0)));
            await listAccounts();
        }

        if (true) {
            console.log('9. redeem');
            await nest.transfer(nestRedeem.address, toBigInt(10000));
            await dcu.transfer(owner.address, toBigInt(10000));
            await dcu.approve(nestRedeem.address, toBigInt(100000));
            await listAccounts();
            await nestRedeem.redeem(toBigInt(7));
            await listAccounts();
        }
    });
});
