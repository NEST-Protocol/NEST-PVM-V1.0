const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, UI, snd, tableSnd, d1, Vc, Vp, FEQ } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('36.PVM', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction, nestFuturesWithPrice, nestGovernance, nestCraft,
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
                nestCraft: await listBalances(nestCraft, tokens),
                addr2: await listBalances(addr2, tokens)
            };
            console.log(accounts);
            return accounts;
        };

        await nestCraft.registerTokenConfig({
            // The pairIndex for call nest price
            pairIndex: 0,

            // SigmaSQ for token
            sigmaSQ: 45659142400n, //toBigInt(0.0005),
            // MIU_LONG for token
            miu: 3472222200n //toBigInt(0.00001),
        });
        await nestCraft.registerTokenConfig({
            // The pairIndex for call nest price
            pairIndex: 1,

            // SigmaSQ for token
            sigmaSQ: 45659142400n, //toBigInt(0.0005),
            // MIU_LONG for token
            miu: 347222220n //toBigInt(0.00001),
        });
        await nestCraft.registerTokenConfig({
            // The pairIndex for call nest price
            pairIndex: 2,

            // SigmaSQ for token
            sigmaSQ: 45659142400n, //toBigInt(0.0005),
            // MIU for token
            miu: 3472222200n //toBigInt(0.00001),
        });

        //await listAccounts();
        await nest.transfer(owner.address, 100000000000000000000000000n);
        await nest.approve(nestCraft.address, 100000000000000000000000000n);

        await nestCraft.registerStaticCall('bn', nestCraft.address);
        await nestCraft.registerStaticCall('ts', nestCraft.address);
        await nestCraft.registerStaticCall('ob', nestCraft.address);

        await nestCraft.registerStaticCall('op', nestCraft.address);
        await nestCraft.registerStaticCall('ln', nestCraft.address);
        await nestCraft.registerStaticCall('exp', nestCraft.address);
        await nestCraft.registerStaticCall('flo', nestCraft.address);
        await nestCraft.registerStaticCall('cel', nestCraft.address);

        await nestCraft.registerStaticCall('log', nestCraft.address);
        await nestCraft.registerStaticCall('pow', nestCraft.address);
        await nestCraft.registerStaticCall('oav', nestCraft.address);

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
        //let c = await nestCraft.estimate('4*2**3+1+PI');
        //let c = await nestCraft.estimate('4*2**0.5**(2+1)+PI*3*4*5+(44+4)*6*7*9');
        //let c = await nestCraft.estimate('P0 * P1+ P1 + P0');
        //let c = await nestCraft.estimate('P1 ** 0.5 + PI * (E+ 9527)');
        //let c = await nestCraft.estimate('(0+3)**(0+1)');
        //let c = await nestCraft.estimate('3 + 4 + add(4,5,max( 10, 20 )) + op(1)');
        //let c = await nestCraft.estimate('pow(7, 2) + PI + E');
        let c = await nestCraft.estimate('flo(0-3.14)');

        console.log('result=' + toDecimal(c).toString());

        if (true) {
            console.log('1. buy');
            let receipt = await nestCraft.buy('P0');
            await showReceipt(receipt);
            await listAccounts();
        }

        if (true) {
            console.log('2. list');
            let list = await nestCraft.list(0, 1, 0);
            for (var i = 0; i < list.length; ++i) {
                console.log(UI(list[i]));
            }
        }
        if (true) {
            console.log('3. sell');
            let receipt = await nestCraft.sell(0);
            await showReceipt(receipt);
            await listAccounts();
        }

        if (true) {
            console.log('4.buy2')
            let receipt = await nestCraft.buy('op(0) * exp(1 + 60 / 300 ) + log(op(1), PI)');
            await showReceipt(receipt);
            await listAccounts();
        }

        if (true) {
            console.log('5. list2');
            let list = await nestCraft.list(0, 2, 0);
            for (var i = 0; i < list.length; ++i) {
                console.log(UI(list[i]));
            }
        }
        if (true) {
            console.log('6. sell2');
            let receipt = await nestCraft.sell(1);
            await showReceipt(receipt);
            await listAccounts();
        }

        const BLOCK_SECONDS = 3000;
        const OP_BUY = 0;
        const OP_SELL = 1;
        const MIU = 0.0000000034722222;
        const SIGMASQ = 0.0000000456591424;

        const m1 = function(op, miu, sigmaSQ, t, St) {
            if (op == OP_BUY) {
                return St;
            } else if (op == OP_SELL) {
                return St * Math.exp(-miu * t);
            }
            throw new Error('Not support');
        };

        const m2 = function(op, miu, sigmaSQ, t, St) {
            if (op == OP_BUY) {
                return St * St;
            } else if (op == OP_SELL) {
                return St * St * Math.exp(-2 * miu * t - sigmaSQ * t);
            }
            throw new Error('Not support');
        };

        const m3 = function(op, miu, sigmaSQ, t, St) {
            if (op == OP_BUY) {
                return 1 / St;
            } else if (op == OP_SELL) {
                return 1 / St * Math.exp(miu * t - sigmaSQ * t);
            }
            throw new Error('Not support');
        };

        const m4 = function(op, miu, sigmaSQ, t, St) {
            if (op == OP_BUY) {
                return Math.sqrt(St);
            } else if (op == OP_SELL) {
                return Math.sqrt(St) * Math.exp(-1 / 2 * miu * t + 1 / 8 * sigmaSQ * t);
            }
            throw new Error('Not support');
        };

        const m5 = function(op, miu, sigmaSQ, t, St) {
            if (op == OP_BUY) {
                return Math.log(St);
            } else if (op == OP_SELL) {
                return Math.log(St) - miu * t + 1 / 2 * sigmaSQ * t;
            }
        };

        if (true) {
            console.log('7. full');
            let receipt = await nestCraft.buy('1.23 * m1(0) + 2.34 * m2(0) + 3.45 * m3(0) + 4.56 * m4(0) + 5.67 * m5(0)');
            await showReceipt(receipt);
            await listAccounts();

            const totalNest = 
                1.23 * m1(OP_BUY, MIU, SIGMASQ, 0, 1.508461 * 2) + 
                2.34 * m2(OP_BUY, MIU, SIGMASQ, 0, 1.508461 * 2) + 
                3.45 * m3(OP_BUY, MIU, SIGMASQ, 0, 1.508461 * 2) +
                4.56 * m4(OP_BUY, MIU, SIGMASQ, 0, 1.508461 * 2) +
                5.67 * m5(OP_BUY, MIU, SIGMASQ, 0, 1.508461 * 2);

            FEQ({
                a: parseFloat(previous.owner.NEST) - parseFloat(accounts.owner.NEST),
                b: totalNest,
                d: 0.0000001
            });
            FEQ({
                a: parseFloat(accounts.nestCraft.NEST) - parseFloat(previous.nestCraft.NEST),
                b: totalNest,
                d: 0.0000001
            })
        }

        if (true) {
            console.log('8. sell full');
            let receipt = await nestCraft.sell(2);
            await showReceipt(receipt);
            await listAccounts();

            const totalNest = 
                1.23 * m1(OP_SELL, MIU, SIGMASQ, 3, 1.508461 * 2) + 
                2.34 * m2(OP_SELL, MIU, SIGMASQ, 3, 1.508461 * 2) + 
                3.45 * m3(OP_SELL, MIU, SIGMASQ, 3, 1.508461 * 2) +
                4.56 * m4(OP_SELL, MIU, SIGMASQ, 3, 1.508461 * 2) +
                5.67 * m5(OP_SELL, MIU, SIGMASQ, 3, 1.508461 * 2);

            FEQ({
                a: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
                b: totalNest,
                d: 0.0000001
            });
            FEQ({
                a: parseFloat(previous.nestCraft.NEST) - parseFloat(accounts.nestCraft.NEST),
                b: totalNest,
                d: 0.0000001
            });
        }
    });
});
