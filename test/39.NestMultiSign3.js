const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, UI, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('39.NestMultiSign3', function() {
    it('First', async function() {
        var [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9] = await ethers.getSigners();
        const NestMultiSign = await ethers.getContractFactory('NestMultiSign');
        const nestMultiSign = await NestMultiSign.deploy([
            [owner.address, addr1.address, addr2.address, addr3.address],
            [addr4.address, addr5.address, addr6.address, addr7.address],
        ]);

        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction, nestFuturesWithPrice, nestGovernance, nestCraft,
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
        await nest.approve(nestCraft.address, 100000000000000000000000000n);

        let receipt = await nestFuturesWithPrice.directPost(200, [
            toBigInt(1.508461),
            toBigInt(66666666666),
            toBigInt(2000 / 20000)
        ]);

        await nest.transfer(nestMultiSign.address, toBigInt(100000));
        await listAccounts();

        if (true) {
            console.log('owner: ' + owner.address);
            console.log('addr1: ' + addr1.address);
            console.log('addr2: ' + addr2.address);
            console.log('addr3: ' + addr3.address);
            console.log('addr4: ' + addr4.address);
            console.log('addr5: ' + addr5.address);
            console.log('addr6: ' + addr6.address);
            console.log('addr7: ' + addr7.address);
            console.log('addr8: ' + addr8.address);
            console.log('addr9: ' + addr9.address);
        }
        if (true) {
            console.log('1. get members');
            for (var i = 0; i < 2; ++i) {
                for (var j = 0; j < 4; ++j) {
                    console.log({
                        i: i,
                        j: j,
                        member: await nestMultiSign.getMember(i, j)
                    })
                }
            }
        }

        if (true) {
            console.log('2. findMember');
            console.log(await nestMultiSign.findMember(owner.address));
            console.log(await nestMultiSign.findMember(addr1.address));
            console.log(await nestMultiSign.findMember(addr2.address));
            console.log(await nestMultiSign.findMember(addr3.address));
            console.log(await nestMultiSign.findMember(addr4.address));
            console.log(await nestMultiSign.findMember(addr5.address));
            console.log(await nestMultiSign.findMember(addr6.address));
            console.log(await nestMultiSign.findMember(addr7.address));
        }
        if (true) {
            console.log('2. sign');
            await nestMultiSign.connect(addr7).newTransaction(1, 3, nest.address, addr8.address, toBigInt(9527));
            //await nestMultiSign.connect(addr3).signTransaction(1, 1, 0);
            //await nestMultiSign.connect(addr4).signTransaction(2, 0, 0);
            //await nestMultiSign.connect(owner).signTransaction(0, 0, 0);
            await nestMultiSign.connect(addr2).executeTransaction(0, 2, 0);
            await listAccounts();
        }

        if (true) {
            console.log('3. list');
            let list = await nestMultiSign.list(0, 1, 0);
            console.log(UI(list));
            expect(list[0].signs[0]).to.eq(addr2.address);
            expect(list[0].signs[1]).to.eq(addr7.address);
        }

        if (true) {
            console.log('3. newTransaction');
            await nestMultiSign.connect(addr3).newTransaction(0, 3, nest.address, addr8.address, toBigInt(1));
            let list = await nestMultiSign.list(0, 1, 0);
            console.log(UI(list));
            expect(list[0].signs[0]).to.eq(addr3.address);
            expect(list[0].signs[1]).to.eq(eth.address);
            await listAccounts();
        }

        if (true) {
            console.log('4. signTransaction');
            await nestMultiSign.connect(addr1).signTransaction(0, 1, 1);
            let list = await nestMultiSign.list(0, 1, 0);
            console.log(UI(list));
            expect(list[0].signs[0]).to.eq(addr1.address);
            expect(list[0].signs[1]).to.eq(eth.address);
            await listAccounts();
        }

        if (true) {
            console.log('5. executeTransaction');
            await nestMultiSign.connect(addr5).signTransaction(1, 1, 1);
            let list = await nestMultiSign.list(0, 1, 0);
            console.log(UI(list));
            expect(list[0].signs[0]).to.eq(addr1.address);
            expect(list[0].signs[1]).to.eq(addr5.address);
            await listAccounts();
        }

        if (true) {
            console.log('6. new Sign');
            await nestMultiSign.connect(addr6).executeTransaction(1, 2, 1);
            let list = await nestMultiSign.list(0, 1, 0);
            console.log(UI(list));
            expect(list[0].signs[0]).to.eq(addr1.address);
            expect(list[0].signs[1]).to.eq(addr5.address);
            await listAccounts();
        }
    });
});
