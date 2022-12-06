const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, UI, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('37.NestMultiSign', function() {
    it('First', async function() {
        var [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9] = await ethers.getSigners();
        const NestMultiSign = await ethers.getContractFactory('NestMultiSign');
        const nestMultiSign = await NestMultiSign.deploy([
            [owner.address, addr1.address, addr2.address],
            [addr3.address, addr4.address, addr5.address],
            [addr6.address, addr7.address, addr8.address],
        ]);

        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction, nestFuturesWithPrice, nestGovernance, nestPVM,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();

        const tokens = [eth, nest];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestMultiSign: await listBalances(nestMultiSign, tokens),
                addr8: await listBalances(addr8, tokens),
            };
            console.log(accounts);
            return accounts;
        }

        await nest.transfer(owner.address, 100000000000000000000000000n);
        await nest.approve(nestPVM.address, 100000000000000000000000000n);

        let receipt = await nestFuturesWithPrice.directPost(200, [
            toBigInt(1.508461),
            toBigInt(66666666666),
            toBigInt(2000 / 20000)
        ]);

        await nest.transfer(nestMultiSign.address, toBigInt(100000));
        await listAccounts();
        if (true) {
            console.log('1. get members');
            for (var i = 0; i < 3; ++i) {
                for (var j = 0; j < 3; ++j) {
                    console.log({
                        i: i,
                        j: j,
                        member: await nestMultiSign.getMember(i, j)
                    })
                }
            }
        }
        if (true) {
            console.log('2. sign');
            await nestMultiSign.newTransaction(0, 0, nest.address, addr8.address, toBigInt(9527));
            await nestMultiSign.connect(addr3).signTransaction(1, 0, 0);
            await nestMultiSign.connect(addr6).signTransaction(2, 0, 0);
            //await nestMultiSign.connect(addr5).rejectTransaction(1, 2, 0);
            await nestMultiSign.connect(addr2).executeTransaction(0, 2, 0);
            await listAccounts();
        }

        if (true) {
            console.log('3. list');
            let list = await nestMultiSign.list(0, 1, 0);
            console.log(UI(list));
        }
    });
});
