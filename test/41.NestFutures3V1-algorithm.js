const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI, FEQ } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('41.NestFutures3V1-algorithm.js', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction, nestTrustFuturesV1, nestVault,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();

        const tokens = [eth, nest, dcu];
        let previous;
        let accounts;
        const listAccounts = async function(silent) {
            previous = accounts;
            accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestVault: await listBalances(nestVault, tokens),
                nestTrustFuturesV1: await listBalances(nestTrustFuturesV1, tokens)
            };
            if (!silent) console.log(accounts);
            return accounts;
        }

        const NEST_BASE = 10000;
        const MIU_DECIMALS = 1e12;
        const FEE_RATE = 0.001;
        const ownerNestBalance = 100000000000000000000000000n;

        await nest.transfer(owner.address, ownerNestBalance);
        await listAccounts();

        // Local context
        let ctx = {
            channels: [
                { Lp: 0, Sp: 0, Pt: 0, bn: 0 },
                { Lp: 0, Sp: 0, Pt: 0, bn: 0 }
            ],
            orders: [],
            trustOrders: [],
            prices: [0, 0, 0]
        };

        // Calculate exp(miuT)
        const expMiuT = function(miuT) {
            return 1.0000 + miuT;
        };

        // Return last block number
        const bn = async function() {
            return await ethers.provider.getBlockNumber();
        };

        // Post price
        const post = async function(period, prices) {
            // Post price to the contract
            await nestTrustFuturesV1.post(period, [toBigInt(prices[0]), toBigInt(prices[1]), toBigInt(prices[2])]);
            // Update price to context
            ctx.prices[0] = prices[0],
            ctx.prices[1] = prices[1],
            ctx.prices[2] = prices[2];
        };

        // Return lastPrice of target channel
        const lastPrice = function(channelIndex) {
            return ctx.prices[channelIndex];
        };

        // Compare Order from local context to contract
        const compareOrder = async function(index) {
            // Local Order
            const jo = UI(ctx.orders[index]);
            // Order from contract
            const co = UI((await nestTrustFuturesV1.list(index, 1, 1))[0]);
            // Parse Order to local format
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
            //console.log({ jo: jo, po: po });
            
            // Compare two Order: basePrice, balance, appends, lever, valueOf, Pt
            FEQ({ a: jo.basePrice, b: po.basePrice, d: 0.00000000001 }, true);
            FEQ({ a: jo.balance, b: po.balance, d: 0.00000000001 }, true);
            FEQ({ a: jo.appends, b: po.appends, d: 0.00000000001 }, true);
            FEQ({ a: jo.lever, b: po.lever }, true);
            FEQ({ a: jo.Pt, b: po.Pt, d: 0.00001 }, true);
        };

        // Load and calculate current Pt of channel
        const currentPt = async function(channel) {
            // If channel.Lp + channel.Sp not 0, update Pt
            if (channel.Lp + channel.Sp > 0) {
                let miu = (channel.Lp - channel.Sp) * 0.02 / (channel.Lp + channel.Sp) / 86400;
                return channel.Pt + miu * (await bn() - channel.bn) * BLOCK_TIME;
            }
            return channel.Pt;
        };

        // Update channel parameter
        const updateChannel = async function(channelIndex, virtualAmount, orientation, uncheck) {
            let channel = ctx.channels[channelIndex];
            channel.Pt = await currentPt(channel);
            if (orientation) {
                channel.Lp += virtualAmount;
            } else {
                channel.Sp += virtualAmount;
            }
            channel.bn = await bn();

            if (!uncheck) {
                const cp = UI(await nestTrustFuturesV1.getChannel(channelIndex));
                const pp = {
                    Lp: parseFloat(cp.Lp) / NEST_BASE,
                    Sp: parseFloat(cp.Sp) / NEST_BASE,
                    Pt: parseFloat(cp.Pt) / MIU_DECIMALS,
                    bn: cp.bn
                }
                //console.log({ channel, pp });
                FEQ({ a: channel.Lp, b: pp.Lp }, true);
                FEQ({ a: channel.Sp, b: pp.Sp }, true);
                FEQ({ a: channel.Pt, b: pp.Pt, d: 0.00001 }, true);
            }

            return channel;
        }

        // Calculate value with current variables
        const _valueOf = function(miuT, balance, lever, orientation, basePrice, oraclePrice) {
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

        // Calculate value of the order
        const balanceOf = async function(orderIndex, oraclePrice) {
            const order = ctx.orders[orderIndex];
            const miuT = await currentPt(order.channelIndex) - order.Pt;
            const value = _valueOf(miuT, order.balance, order.lever, order.orientation, order.basePrice, oraclePrice);
            return value + order.appends;
        };

        // Buy order
        const buy = async function(sender, channelIndex, lever, orientation, amount) {
            await listAccounts(true);
            await nestTrustFuturesV1.buy(channelIndex, lever, orientation, amount * NEST_BASE);
            await listAccounts(true);

            let channel = await updateChannel(channelIndex, amount * lever, orientation);

            const index = ctx.orders.length;
            ctx.orders.push({
                index: index, 
                owner: sender.address,
                balance: amount,
                appends: 0,
                channelIndex: channelIndex,
                lever: lever,
                orientation: orientation,
                basePrice: lastPrice(channelIndex),
                Pt: channel.Pt
            });

            await compareOrder(index);

            const totalNest = amount + amount * lever * FEE_RATE;
            FEQ({ a: totalNest, b: parseFloat(previous.owner.NEST) - parseFloat(accounts.owner.NEST) }, true);
            FEQ({ a: totalNest, b: parseFloat(accounts.nestVault.NEST) - parseFloat(previous.nestVault.NEST) }, true);

            return index;
        };

        // Append order
        const add = async function(sender, index, amount) {
            await listAccounts(true);
            await nestTrustFuturesV1.add(index, amount * NEST_BASE);
            await listAccounts(true);

            ctx.orders[index].appends += amount;

            await compareOrder(index);
        };

        // Sell order
        const sell = async function(sender, index) {
            await listAccounts(true);
            await nestTrustFuturesV1.sell(index);
            await listAccounts(true);

            let order = ctx.orders[index];
            // Update channel
            let channel = await updateChannel(order.channelIndex, -order.balance * order.lever, order.orientation);
            
            // μT = P1 - P0
            let miuT = channel.Pt - order.Pt;
            // Query last price
            let oraclePrice = lastPrice(order.channelIndex);
            // Calculate value of order
            let value = _valueOf(
                miuT, 
                order.balance, 
                order.lever, 
                order.orientation, 
                order.basePrice, 
                oraclePrice
            ) + order.appends;
            // Service fee
            let fee = order.balance * order.lever * oraclePrice / order.basePrice * FEE_RATE;
            // Update order
            order.balance = 0;
            order.appends = 0;

            let totalNest = value - fee;
            if (totalNest < 0) totalNest = 0;

            FEQ({
                a: totalNest,
                b: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
                d: 0.0000000001
            }, true);
            FEQ({
                a: totalNest,
                b: parseFloat(previous.nestVault.NEST) - parseFloat(accounts.nestVault.NEST),
                d: 0.0000000001
            }, true);
        };

        // Liquidate orders
        const liquidate = async function(sender, indices) {
            await listAccounts(true);
            await nestTrustFuturesV1.liquidate(indices);
            await listAccounts(true);

            let reward = 0;
            for (let i = 0; i < indices.length; ++i) {
                let index = indices[i];
                
                let order = ctx.orders[index];
                let channel = ctx.channels[order.channelIndex];
                let oraclePrice = lastPrice(order.channelIndex);

                if (order.lever > 1 && order.balance > 0) {
                    // μT = P1 - P0
                    let miuT = await currentPt(channel) - order.Pt;
                    // Calculate value of order
                    let value = _valueOf(
                        miuT, 
                        order.balance, 
                        order.lever, 
                        order.orientation, 
                        order.basePrice, 
                        oraclePrice
                    ) + order.appends;

                    // Compare with liquidate line
                    if (value < order.balance * order.lever * oraclePrice / order.basePrice * FEE_RATE + 15 ||
                        value < order.balance * order.lever * 0.5 / 100
                    ) {
                        // Liquidated, update channel
                        await updateChannel(order.channelIndex, -order.balance * order.lever, order.orientation, true);

                        reward += value;
                        order.balance = 0;
                        order.appends = 0;
                        order.baseBlock = 0;
                    }
                }

                await compareOrder(index);
            }

            FEQ({
               a: reward,
               b: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
               d: 0.00000001
            }, true);
            FEQ({
                a: reward,
                b: parseFloat(previous.nestVault.NEST) - parseFloat(accounts.nestVault.NEST),
                d: 0.00000001
            }, true);

            for (let i = 0; i < indices.length; ++i) {
                let index = indices[i];
                let order = ctx.orders[index];
                await updateChannel(order.channelIndex, 0, false);
            }
        };

        // Compare TrustOrder
        const compareTrustOrder = async function(index) {
            const to = UI((await nestTrustFuturesV1.listTrustOrder(index, 1, 1))[0]);
            const po = {
                index: to.index,
                owner: to.owner,
                orderIndex: to.orderIndex,
                channelIndex: to.channelIndex,
                lever: to.lever,
                orientation: to.orientation,
                limitPrice: parseFloat(toDecimal(to.limitPrice)),
                stopProfitPrice: parseFloat(toDecimal(to.stopProfitPrice)),
                stopLossPrice: parseFloat(toDecimal(to.stopLossPrice)),
                balance: parseFloat(to.balance) / NEST_BASE,
                fee: parseFloat(to.fee) / NEST_BASE,
                status: to.status
            };

            const jo = ctx.trustOrders[index];
            //console.log({ jo, po });

            FEQ({ a: jo.orderIndex, b: po.orderIndex }, true);
            FEQ({ a: jo.channelIndex, b: po.channelIndex }, true);
            FEQ({ a: jo.lever, b: po.lever }, true);
            FEQ({ a: jo.limitPrice, b: po.limitPrice, d: 0.0000000001 }, true);
            FEQ({ a: jo.stopProfitPrice, b: po.stopProfitPrice, d: 0.0000000001 }, true);
            FEQ({ a: jo.stopLossPrice, b: po.stopLossPrice, d: 0.0000000001 }, true);
            FEQ({ a: jo.balance, b: po.balance }, true);
            FEQ({ a: jo.fee, b: po.fee }, true);
            FEQ({ a: jo.status, b: po.status }, true);
        };

        // New TrustOrder
        const newTrustOrder = async function(
            sender, channelIndex, lever, orientation, amount, limitPrice, stopProfitPrice, stopLossPrice) {
            await listAccounts(true);
            await nestTrustFuturesV1.newTrustOrder(
                channelIndex,
                lever,
                orientation,
                amount * NEST_BASE,
                toBigInt(limitPrice),
                toBigInt(stopProfitPrice),
                toBigInt(stopLossPrice)
            );
            await listAccounts(true);

            const index = ctx.trustOrders.length;
            ctx.trustOrders.push({
                index: index,
                owner: sender.address,
                orderIndex: ctx.orders.length,
                channelIndex: channelIndex,
                lever: lever,
                orientation: orientation,
                limitPrice: limitPrice,
                stopProfitPrice: stopProfitPrice,
                stopLossPrice: stopLossPrice,
                balance: amount,
                fee: amount * lever * FEE_RATE,
                status: 1
            });
            ctx.orders.push({
                index: ctx.orders.length, 
                owner: sender.address,
                balance: 0,
                appends: 0,
                channelIndex: channelIndex,
                lever: lever,
                orientation: orientation,
                basePrice: limitPrice,
                Pt: 0
            });

            // Check order data
            await compareOrder(ctx.orders.length - 1);
            await compareTrustOrder(index);

            // Check balance
            const totalNest = amount + amount * lever * FEE_RATE + 15;
            FEQ({
                a: totalNest,
                b: parseFloat(previous.owner.NEST) - parseFloat(accounts.owner.NEST),
                d: 0.000000001
            }, true);
            FEQ({
                a: totalNest,
                b: parseFloat(accounts.nestTrustFuturesV1.NEST) - parseFloat(previous.nestTrustFuturesV1.NEST),
                d: 0.000000001
            }, true);
        };

        // Execute LimitOrder
        const executeLimitOrder = async function(sender, trustOrderIndices) {
            await listAccounts(true);
            await nestTrustFuturesV1.executeLimitOrder(trustOrderIndices);
            await listAccounts(true);

            let totalNest = 0;

            for (let i = 0; i < trustOrderIndices.length; ++i) {
                let trustOrder = ctx.trustOrders[trustOrderIndices[i]];

                let order = ctx.orders[trustOrder.orderIndex];
                order.balance = trustOrder.balance;
                order.basePrice = ctx.prices[order.channelIndex];
                order.Pt = (await updateChannel(order.channelIndex, order.balance * order.lever, order.orientation, true)).Pt;

                totalNest += (trustOrder.balance + trustOrder.fee);

                trustOrder.limitPrice = ctx.prices[order.channelIndex];
                trustOrder.balance = 0;
                trustOrder.fee = 0;
                trustOrder.status = 0;

                compareOrder(order.index);
                compareTrustOrder(trustOrderIndices[i]);
            }

            for (let i = 0; i < trustOrderIndices.length; ++i) {
                let trustOrder = ctx.trustOrders[trustOrderIndices[i]];
                compareOrder(trustOrder.orderIndex);
                compareTrustOrder(trustOrderIndices[i]);
            }

            FEQ({
                a: totalNest,
                b: parseFloat(previous.nestTrustFuturesV1.NEST) - parseFloat(accounts.nestTrustFuturesV1.NEST),
                d: 0.0000000001
            }, true);
            FEQ({
                a: totalNest,
                b: parseFloat(accounts.nestVault.NEST) - parseFloat(previous.nestVault.NEST),
                d: 0.0000000001
            }, true);
        };

        // New StopOrder
        const newStopOrder = async function(sender, orderIndex, stopProfitPrice, stopLossPrice) {
            await nestTrustFuturesV1.newStopOrder(orderIndex, toBigInt(stopProfitPrice), toBigInt(stopLossPrice));

            const order = ctx.orders[orderIndex];
            const index = ctx.trustOrders.length;
            ctx.trustOrders.push({
                index: index,
                owner: sender.address,
                orderIndex: orderIndex,
                channelIndex: order.channelIndex,
                lever: order.lever,
                orientation: order.orientation,
                limitPrice: order.basePrice,
                stopProfitPrice: stopProfitPrice,
                stopLossPrice: stopLossPrice,
                balance: 0,
                fee: 0,
                status: 0
            });

            await compareOrder(orderIndex);
            await compareTrustOrder(index);
        };

        // BuyWithStopOrder
        const buyWithStopOrder = async function(
            sender, channelIndex, lever, orientation, amount, stopProfitPrice, stopLossPrice) {
            await listAccounts(true);
            await nestTrustFuturesV1.buyWithStopOrder(
                channelIndex, 
                lever, 
                orientation, 
                amount * NEST_BASE, 
                toBigInt(stopProfitPrice), 
                toBigInt(stopLossPrice)
            );
            await listAccounts(true);

            let channel = await updateChannel(channelIndex, amount * lever, orientation);

            const index = ctx.orders.length;
            ctx.orders.push({
                index: index, 
                owner: sender.address,
                balance: amount,
                appends: 0,
                channelIndex: channelIndex,
                lever: lever,
                orientation: orientation,
                basePrice: lastPrice(channelIndex),
                Pt: channel.Pt
            });

            ctx.trustOrders.push({
                index: ctx.trustOrders.length,
                owner: sender.address,
                orderIndex: index,
                channelIndex: channelIndex,
                lever: lever,
                orientation: orientation,
                limitPrice: lastPrice(channelIndex),
                stopProfitPrice: stopProfitPrice,
                stopLossPrice: stopLossPrice,
                balance: 0,
                fee: 0,
                status: 0
            });

            await compareOrder(index);
            await compareTrustOrder(ctx.trustOrders.length - 1);

            const totalNest = amount + amount * lever * FEE_RATE;
            FEQ({ a: totalNest, b: parseFloat(previous.owner.NEST) - parseFloat(accounts.owner.NEST) }, true);
            FEQ({ a: totalNest, b: parseFloat(accounts.nestVault.NEST) - parseFloat(previous.nestVault.NEST) }, true);
        };

        // Update LimitPrice
        const updateLimitPrice = async function(sender, trustOrderIndex, limitPrice) {
            await nestTrustFuturesV1.updateLimitPrice(trustOrderIndex, toBigInt(limitPrice));
            let trustOrder = ctx.trustOrders[trustOrderIndex];
            let order = ctx.orders[trustOrder.orderIndex];
            order.basePrice = limitPrice;
            trustOrder.limitPrice = limitPrice;

            await compareOrder(trustOrder.orderIndex);
            await compareTrustOrder(trustOrderIndex);
        };

        // Update StopPrice
        const updateStopPrice = async function(sender, trustOrderIndex, stopProfitPrice, stopLossPrice) {
            await nestTrustFuturesV1.updateStopPrice(trustOrderIndex, toBigInt(stopProfitPrice), toBigInt(stopLossPrice));

            let trustOrder = ctx.trustOrders[trustOrderIndex];
            trustOrder.stopProfitPrice = stopProfitPrice;
            trustOrder.stopLossPrice = stopLossPrice;

            await compareOrder(trustOrder.orderIndex);
            await compareTrustOrder(trustOrderIndex);
        };

        // Cancel LimitOrder
        const cancelLimitOrder = async function(sender, trustOrderIndex) {
            await listAccounts(true);
            await nestTrustFuturesV1.cancelLimitOrder(trustOrderIndex);
            await listAccounts(true);

            let trustOrder = ctx.trustOrders[trustOrderIndex];
            const totalNest = trustOrder.balance + trustOrder.fee + 15;
            trustOrder.status = 2;

            await compareOrder(trustOrder.orderIndex);
            await compareTrustOrder(trustOrderIndex);

            FEQ({
                a: totalNest,
                b: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
                d: 0.0000000001
            }, true);
            FEQ({
                a: totalNest,
                b: parseFloat(previous.nestTrustFuturesV1.NEST) - parseFloat(accounts.nestTrustFuturesV1.NEST),
                d: 0.0000000001
            }, true);
        };

        // Execute StopOrder
        const executeStopOrder = async function(sender, trustOrderIndices) {
            await listAccounts(true);
            await nestTrustFuturesV1.executeStopOrder(trustOrderIndices);
            await listAccounts(true);

            let totalNest = 0;
            let totalExecuteFee = 0;

            for (let i = 0; i < trustOrderIndices.length; ++i) {
                let trustOrder = ctx.trustOrders[trustOrderIndices[i]];
                let order = ctx.orders[trustOrder.orderIndex];
                
                let oraclePrice = lastPrice(order.channelIndex);
                let channel = await updateChannel(order.channelIndex, -order.balance * order.lever, order.orientation, true);
                let miuT = channel.Pt - order.Pt;
                let value = _valueOf(
                    miuT,
                    order.balance,
                    order.lever,
                    order.orientation,
                    order.basePrice,
                    oraclePrice
                );

                let fee = order.balance * order.lever * oraclePrice / order.basePrice * FEE_RATE;

                if (value > fee + 15) {
                    totalNest += (value - fee - 15);
                }
                totalExecuteFee += 15;

                order.balance = 0;
                order.appends = 0;
            }

            for (let i = 0; i < trustOrderIndices.length; ++i) {
                let trustOrder = ctx.trustOrders[trustOrderIndices[i]];
                await compareOrder(trustOrder.orderIndex);
                await compareTrustOrder(trustOrderIndices[i]);
            }

            FEQ({
                a: totalNest,
                b: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
                d: 0.0000000001
            }, true);
            FEQ({
                a: totalExecuteFee,
                b: parseFloat(accounts.nestTrustFuturesV1.NEST) - parseFloat(previous.nestTrustFuturesV1.NEST),
                d: 0.0000000001
            }, true);
            FEQ({
                a: totalNest + totalExecuteFee,
                b: parseFloat(previous.nestVault.NEST) - parseFloat(accounts.nestVault.NEST),
                d: 0.0000000001
            }, true);
        };

        await post(200, [1250, 250, 16000]);
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

        if (true) {
            console.log('3. add');
            await add(owner, 2, 9527);
        }

        if (true) {
            console.log('4. liquidate');
            console.log((await nestTrustFuturesV1.balanceOf(2, 1662500717000000000000n)).toString());
            await post(200, [1662.500717, 250, 16000]);
            await liquidate(owner, [0, 1, 2, 3]);
            await updateChannel(0, 0, false);
        }

        console.log('------------------------- Trust Order ----------------------------');

        if (true) {
            console.log('5. New TrustOrder');
            await newTrustOrder(owner, 0, 9, false, 9989, 1900, 1200, 2500);
            await updateLimitPrice(owner, 0, 1999);
            await updateStopPrice(owner, 0, 1000, 2000);
            await executeLimitOrder(owner, [0]);

            // await executeStopOrder(owner, [0]);
            //await cancelLimitOrder(owner, 0);
            await newStopOrder(owner, 4, 1111, 2222);
        }

        if (true) {
            console.log('6. buyWithStopOrder');
            await buyWithStopOrder(owner, 0, 3, true, 10000, 3000, 300);
        }
    });
});
