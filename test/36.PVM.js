const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, UI, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('36.PVM', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const NestPVM = await ethers.getContractFactory('NestPVM');
        
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
                nestPVM: await listBalances(nestPVM, tokens)
            };
            console.log(accounts);
            return accounts;
        }

        //await listAccounts();
        //await nest.transfer(owner.address, 100000000000000000000000000n);
        //await nest.approve(nestPVM.address, 100000000000000000000000000n);

        let receipt = await nestFuturesWithPrice.directPost(200, [
            toBigInt(1.508461),
            toBigInt(66666666666),
            toBigInt(2000 / 20000)
        ]);
        //let c = await nestPVM.calc('4*2**3+1+PI');
        //let c = await nestPVM.calc('4*2**0.5**(2+1)+PI*3*4*5+(44+4)*6*7*9');
        //let c = await nestPVM.estimate('P0 * P1+ P1 + P0');
        let c = await nestPVM.estimate('P1 ** 0.5 + PI * (E+ 9527)');
        //let c = await nestPVM.calc('(0+3)**(0+1)');

        console.log('result=' + toDecimal(c).toString());
        return;
        if (true) {
            console.log('1. buy');
            let receipt = await nestPVM.buy('P0');
            await showReceipt(receipt);
            await listAccounts();
        }

        if (true) {
            console.log('2. list');
            let list = await nestPVM.list(0, 1, 0);
            for (var i = 0; i < list.length; ++i) {
                console.log(UI(list[i]));
            }
        }
        if (true) {
            console.log('3. sell');
            let receipt = await nestPVM.sell(0);
            await showReceipt(receipt);
            await listAccounts();
        }

    });
});
