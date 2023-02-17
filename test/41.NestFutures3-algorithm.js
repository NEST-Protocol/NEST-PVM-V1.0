const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI, FEQ } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('41.NestFutures3-algorithm.js', function() {
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
        const MIU_DECIMALS = 1e12;
        const ownerNestBalance = 100000000000000000000000000n;

        await nest.transfer(owner.address, ownerNestBalance);
        //await nestFutures3.init();
        await listAccounts();

        let ctx = {
            channels: [
                { Lp: 0, Sp: 0, Pt: 0, bn: 0 },
                { Lp: 0, Sp: 0, Pt: 0, bn: 0 }
            ],
            orders: [],
            prices: [0, 0, 0]
        };

        const bn = async function() {
            return await ethers.provider.getBlockNumber();
        };
        const directPost = async function(period, prices) {
            await nestFutures3.directPost(period, [toBigInt(prices[0]), toBigInt(prices[1]), toBigInt(prices[2])]);
            ctx.prices[0] = prices[0],
            ctx.prices[1] = prices[1],
            ctx.prices[2] = prices[2];
        };
        const queryPrice = function(channelIndex) {
            return 2000 / ctx.prices[channelIndex];
        };
        const compareOrder = async function(index) {
            const jo = UI(ctx.orders[index]);
            const co = UI((await nestFutures3.list(index, 1, 1))[0]);
            const po = {
                index: co.index,
                owner: co.owner,
                balance: parseFloat(co.balance) / NEST_BASE,
                channelIndex: co.channelIndex,
                baseBlock: co.baseBlock,
                lever: co.lever,
                orientation: co.orientation,
                basePrice: toDecimal(co.basePrice),
                Pt: parseFloat(co.Pt) / MIU_DECIMALS
            };
            console.log({
                jo: jo,
                po: po
            });
            
            FEQ({
                a: jo.Pt,
                b: po.Pt,
                d: 0.00001
            });
            FEQ({
                a: jo.balance,
                b: po.balance,
                d: 0.000001
            });
        };
        const currentPt = async function(channel) {
            if (channel.Lp + channel.Sp > 0) {
                let miu = (channel.Lp - channel.Sp) * 0.02 / (channel.Lp + channel.Sp) / 86400;
                return channel.Pt + miu * (await bn() - channel.bn) * BLOCK_TIME;
            }
            return channel.Pt;
        };
        // Update channel parameter
        const updateChannel = async function(channelIndex, virtualAmount, orientation, nocheck) {
            let channel = ctx.channels[channelIndex];
            channel.Pt = await currentPt(channel);
            if (orientation) {
                channel.Lp += virtualAmount;
            } else {
                channel.Sp += virtualAmount;
            }
            channel.bn = await bn();

            if (!nocheck) {
                const cp = UI(await nestFutures3.getChannel(channelIndex));
                const pp = {
                    Lp: parseFloat(cp.Lp) / NEST_BASE,
                    Sp: parseFloat(cp.Sp) / NEST_BASE,
                    Pt: parseFloat(cp.Pt) / MIU_DECIMALS,
                    bn: cp.bn
                }
                console.log(channel);
                console.log(pp);
                FEQ({
                    a: channel.Lp,
                    b: pp.Lp
                });
                FEQ({
                    a: channel.Sp,
                    b: pp.Sp
                });
                FEQ({
                    a: channel.Pt,
                    b: pp.Pt,
                    d: 0.00001
                });
            }

            return channel;
        }
        // Buy order
        const buy = async function(sender, channelIndex, lever, orientation, amount) {
            await listAccounts();
            await nestFutures3.buy(channelIndex, lever, orientation, amount * NEST_BASE);
            await listAccounts();

            let channel = await updateChannel(channelIndex, amount * lever, orientation);

            const index = ctx.orders.length;
            ctx.orders.push({
                index: index, 
                owner: sender.address,
                balance: amount,
                channelIndex: channelIndex,
                baseBlock: await bn(),
                lever: lever,
                orientation: orientation,
                basePrice: queryPrice(channelIndex),
                Pt: channel.Pt
            });

            await compareOrder(index);

            const totalNest = amount + amount * lever * 0.002;
            FEQ({
                a: totalNest,
                b: parseFloat(previous.owner.NEST) - parseFloat(accounts.owner.NEST),
                d: 0
            });
            FEQ({
                a: totalNest,
                b: parseFloat(accounts.nestVault.NEST) - parseFloat(previous.nestVault.NEST),
                d: 0
            });

            return index;
        };
        const expMiuT = function(miuT) {
            return 1.0000 + miuT;
        };
        const valueOf = function(miuT, balance, lever, orientation, basePrice, oraclePrice) {
            if (orientation) {
                if (miuT < 0) miuT = 0;
            } else {
                if (miuT > 0) miuT = 0;
            }
            let Rt = lever * (oraclePrice / expMiuT(miuT) - basePrice) / basePrice;
            if (orientation) {
                return balance * (1 + Rt);
            } else {
                return balance * (1 - Rt);
            }
        };
        const sell = async function(sender, index) {
            await listAccounts();
            await nestFutures3.sell(index);
            await listAccounts();

            let order = ctx.orders[index];
            let channel = await updateChannel(order.channelIndex, -order.balance * order.lever, order.orientation);
            
            let miuT = channel.Pt - order.Pt;
            let oraclePrice = queryPrice(order.channelIndex);
            let value = valueOf(miuT, order.balance, order.lever, order.orientation, order.basePrice, oraclePrice);
            let fee = order.balance * order.lever * oraclePrice / order.basePrice * 0.002;
            order.balance = 0;

            let totalNest = value - fee;
            if (totalNest < 0) totalNest = 0;

            FEQ({
                a: totalNest,
                b: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
                d: 0.0000000001
            });
            FEQ({
                a: totalNest,
                b: parseFloat(previous.nestVault.NEST) - parseFloat(accounts.nestVault.NEST),
                d: 0.0000000001
            });
        };
        const add = async function(sender, index, amount) {
            await listAccounts();
            await nestFutures3.add(index, amount * NEST_BASE);
            await listAccounts();

            let order = ctx.orders[index];
            let channel = ctx.channels[order.channelIndex];

            let miuT = await currentPt(channel) - order.Pt;
            let oraclePrice = queryPrice(order.channelIndex);
            let value = valueOf(miuT, order.balance, order.lever, order.orientation, order.basePrice, oraclePrice);
            order.balance = value + amount;

            await compareOrder(index);
        };
        const liquidate = async function(sender, indices) {
            await listAccounts();
            await nestFutures3.liquidate(indices);
            await listAccounts();

            let reward = 0;
            for (let i = 0; i < indices.length; ++i) {
                let index = indices[i];
                
                let order = ctx.orders[index];
                let channel = ctx.channels[order.channelIndex];
                let oraclePrice = queryPrice(order.channelIndex);

                if (order.lever > 1 && order.balance > 0) {
                    let miuT = await currentPt(channel) - order.Pt;
                    let value = valueOf(miuT, order.balance, order.lever, order.orientation, order.basePrice, oraclePrice);
                    if (value < order.balance * order.lever * oraclePrice / order.basePrice * 0.002 + 15 ||
                        value < order.balance * order.lever * 0.5 / 100
                    ) {
                        await updateChannel(order.channelIndex, -order.balance * order.lever, order.orientation, true);

                        reward += value;
                        order.balance = 0;
                        order.baseBlock = 0;
                    }
                }

                await compareOrder(index);
            }

            FEQ({
               a: reward,
               b: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
               d: 0.00000001
            });
            FEQ({
                a: reward,
                b: parseFloat(previous.nestVault.NEST) - parseFloat(accounts.nestVault.NEST),
                d: 0.00000001
            });
        }

        await directPost(200, [2000/1250, 2000/250, 2000/16000]);
        if (true) {
            console.log('1. buy');
            await buy(owner, 0, 1, true, 1000);
            await buy(owner, 0, 2, true, 1000);
            await buy(owner, 0, 3, false, 10000);
            for (var i = 0; i < 3; i++) {
                await nest.transfer(owner.address, 0);
            }
            await buy(owner, 0, 4, true, 1000);
        }

        if (true) {
            console.log('2. sell');
            await sell(owner, 0);
            await sell(owner, 1);
            //await sell(owner, 2);
            await sell(owner, 3);
        }

        if (false) {
            console.log('3. add');
            await add(owner, 2, 9527);
        }

        if (true) {
            console.log('4. liquidate');
            console.log((await nestFutures3.valueOf1(2, toBigInt(queryPrice(0)) * 132n / 100n)).toString());
            await directPost(200, [1.203007, 2000/250, 2000/16000]);
            await liquidate(owner, [0, 1, 2, 3]);
            await updateChannel(0, 0, false);
        }
    });
});
