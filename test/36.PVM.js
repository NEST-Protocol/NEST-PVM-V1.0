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
        let previous;
        let accounts;
        const listAccounts = async function() {
            previous = accounts;
            accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestPVM: await listBalances(nestPVM, tokens),
                addr2: await listBalances(addr2, tokens)
            };
            console.log(accounts);
            return accounts;
        };

        await nestPVM.registerTokenConfig({
            // The pairIndex for call nest price
            pairIndex: 0,

            // SigmaSQ for token
            sigmaSQ: toBigInt(0.0005),
            // MIU_LONG for token
            miu: toBigInt(0.00001),
        });
        await nestPVM.registerTokenConfig({
            // The pairIndex for call nest price
            pairIndex: 0,

            // SigmaSQ for token
            sigmaSQ: toBigInt(0.0005),
            // MIU_LONG for token
            miu: toBigInt(0.00001),
        });
        await nestPVM.registerTokenConfig({
            // The pairIndex for call nest price
            pairIndex: 0,

            // SigmaSQ for token
            sigmaSQ: toBigInt(0.0005),
            // MIU for token
            miu: toBigInt(0.00001),
        });

        //await listAccounts();
        await nest.transfer(owner.address, 100000000000000000000000000n);
        await nest.approve(nestPVM.address, 100000000000000000000000000n);

        await nestPVM.registerStaticCall('bn', nestPVM.address);
        await nestPVM.registerStaticCall('ts', nestPVM.address);
        await nestPVM.registerStaticCall('ob', nestPVM.address);

        await nestPVM.registerStaticCall('op', nestPVM.address);
        await nestPVM.registerStaticCall('ln', nestPVM.address);
        await nestPVM.registerStaticCall('exp', nestPVM.address);
        await nestPVM.registerStaticCall('flo', nestPVM.address);
        await nestPVM.registerStaticCall('cel', nestPVM.address);

        await nestPVM.registerStaticCall('log', nestPVM.address);
        await nestPVM.registerStaticCall('pow', nestPVM.address);
        await nestPVM.registerStaticCall('oav', nestPVM.address);

        let receipt = await nestFuturesWithPrice.directPost(200, [
            toBigInt(1.508461),
            toBigInt(66666666666),
            toBigInt(2000 / 20000)
        ]);

        receipt = await nestFuturesWithPrice.directPost(200, [
            toBigInt(1.508461 * 2),
            toBigInt(66666666666 * 2),
            toBigInt(2000 / 20000 * 2)
        ]);
        //let c = await nestPVM.estimate('4*2**3+1+PI');
        //let c = await nestPVM.estimate('4*2**0.5**(2+1)+PI*3*4*5+(44+4)*6*7*9');
        //let c = await nestPVM.estimate('P0 * P1+ P1 + P0');
        //let c = await nestPVM.estimate('P1 ** 0.5 + PI * (E+ 9527)');
        //let c = await nestPVM.estimate('(0+3)**(0+1)');
        //let c = await nestPVM.estimate('3 + 4 + add(4,5,max( 10, 20 )) + op(1)');
        //let c = await nestPVM.estimate('pow(7, 2) + PI + E');
        let c = await nestPVM.estimate('flo(0-3.14)');

        console.log('result=' + toDecimal(c).toString());

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

        if (true) {
            console.log('4.buy2')
            let receipt = await nestPVM.buy('op(0) * exp(1 + 60 / bn() ) + log(op(1), PI)');
            await showReceipt(receipt);
            await listAccounts();
        }

        if (true) {
            console.log('5. list2');
            let list = await nestPVM.list(0, 2, 0);
            for (var i = 0; i < list.length; ++i) {
                console.log(UI(list[i]));
            }
        }
        if (true) {
            console.log('6. sell2');
            let receipt = await nestPVM.sell(1);
            await showReceipt(receipt);
            await listAccounts();
        }

        if (true) {
            console.log('7. full');
            let receipt = await nestPVM.buy('m1(0) + m2(2) + m3(0) + m4(0) + m5(0)');
            await showReceipt(receipt);
            await listAccounts();
        }

        if (true) {
            console.log('8. sell full');
            let receipt = await nestPVM.sell(2);
            await showReceipt(receipt);
            await listAccounts();
        }
    });
});
