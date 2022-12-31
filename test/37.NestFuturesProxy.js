const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('37.NestFuturesProxy', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction, nestFuturesWithPrice, nestVault, nestFuturesProxy,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();

        const tokens = [eth, nest];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestVault: await listBalances(nestVault, tokens),
                nestFuturesProxy: await listBalances(nestFuturesProxy, tokens)
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();
        await nest.transfer(owner.address, 100000000000000000000000000n);
        await nestFuturesWithPrice.init();
        await nest.approve(nestFuturesProxy.address, 100000000000000000000000000n);

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
            console.log('1. limit buy');
            //function newLimitOrder(uint16 tokenIndex, uint8 lever, bool orientation, uint amount, uint limitPrice) external {
            await nestFuturesProxy.newLimitOrder(0, 5, true, 1000 * NEST_BASE, toBigInt(1.538461), 0);
            await listAccounts();
        }
        if (true) {
            console.log('2. execute limit order');
            await nestFuturesProxy.executeLimitOrder([0]);
            await listAccounts();
        }

        if (true) {
            console.log('3. stop order');
            await nestFuturesWithPrice.setStopPrice(0, toBigInt(1.53));
            await listAccounts();
        }

        if (true) {
            console.log('4. execute stop order');
            await nestFuturesProxy.executeStopOrder([0]);
            await listAccounts();
        }

        if (true) {
            console.log('5. limit with stop');
            await nestFuturesProxy.newLimitOrder(0, 5, true, 1000 * NEST_BASE, toBigInt(1.538461), toBigInt(1.538461));
            await listAccounts();
        }

        if (true) {
            console.log('6. execute limit order');
            await nestFuturesProxy.executeLimitOrder([1]);
            //await nestFuturesProxy.executeLimitOrder([1]);
            await listAccounts();
        }

        if (true) {
            console.log('7. execute stop order');
            await nestFuturesProxy.executeStopOrder([1]);
            await listAccounts();
        }

        if (true) {
            console.log('8. list order');
            const list = await nestFuturesWithPrice.list2(0, 3, 0);
            console.log(UI(list));
        }

        if (true) {
            console.log('9. list limit order');
            const list = await nestFuturesProxy.list(0, 3, 0);
            console.log(UI(list));
        }
    });
});
