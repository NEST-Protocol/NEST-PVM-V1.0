const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI, FEQ } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('46.NestFutures3V3-swapBuy.js', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction, nestTrustFuturesV3, nestVault, pancakeFactory, pancakeRouter,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();
        const pair = await pancakeFactory.getPair(usdt.address, nest.address);

        // await pancakeRouter.swapExactTokensForTokens(
        //     toBigInt(400000),
        //     0,
        //     [nest.address, usdt.address],
        //     owner.address,
        //     99999999999n
        // );

        const tokens = [eth, nest, usdt];
        let previous;
        let accounts;
        const listAccounts = async function(silent) {
            previous = accounts;
            accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestVault: await listBalances(nestVault, tokens),
                nestTrustFuturesV3: await listBalances(nestTrustFuturesV3, tokens),
                pair: await listBalances(pair, tokens),
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
                { lastPrice: 0, miu: 0, PtL: 0, PtS: 0, bn: 0 },
                { lastPrice: 0, miu: 0, PtL: 0, PtS: 0, bn: 0 },
                { lastPrice: 0, miu: 0, PtL: 0, PtS: 0, bn: 0 }
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
            await nestTrustFuturesV3.post(period, [toBigInt(prices[0]), toBigInt(prices[1]), toBigInt(prices[2])]);
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
            const co = UI((await nestTrustFuturesV3.list(index, 1, 1))[0]);
            // Parse Order to local format
            const po = {
                index: co.index,
                owner: co.owner,
                balance: parseFloat(co.balance) / NEST_BASE,
                channelIndex: co.channelIndex,
                appends: parseFloat(co.appends) / NEST_BASE,
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
        const currentPt = async function(channel, oraclePrice) {
            // If channel.Lp + channel.Sp not 0, update Pt
            if (await bn() > channel.bn && channel.bn > 0) {
                //let miu = (channel.Lp - channel.Sp) * 0.02 / (channel.Lp + channel.Sp) / 86400;
                //return channel.Pt + miu * (await bn() - channel.bn) * BLOCK_TIME;
                //let miuL = channel.miu > 0 ? channel.miu : 0;
                //let miuS = channel.miu < 0 ? channel.miu : 0;
                let miu = 0.0895
                        * (oraclePrice - channel.lastPrice) 
                        / channel.lastPrice 
                        / (await bn() - channel.bn) 
                        / BLOCK_TIME;
                return {
                    PtL: channel.PtL + (miu + 0.00000001027) * (await bn() - channel.bn) * BLOCK_TIME,
                    PtS: channel.PtS + miu * (await bn() - channel.bn) * BLOCK_TIME,
                    miu: miu
                };
            }
            return { PtL: channel.PtL, PtS: channel.PtS, miu: channel.miu };
        };

        // Decode the floating-point representation of fraction * 16 ^ exponent to uint
        const decodeFloat = function(floatValue) {
            const bi = BigInt(floatValue);
            return (bi >> 6n) << ((bi & 0x3Fn) << 2n);
        };

        // Update channel parameter
        const updateChannel = async function(channelIndex, oraclePrice, uncheck, echo) {
            let channel = ctx.channels[channelIndex];
            if (oraclePrice > 0) {
                let pt = await currentPt(channel, oraclePrice);
                channel.PtL = pt.PtL;
                channel.PtS = pt.PtS;
                channel.miu = pt.miu;
                // if (await bn() > channel.bn && channel.bn > 0) {
                //     channel.miu = 0.0895
                //                 * (oraclePrice - channel.lastPrice) 
                //                 / channel.lastPrice 
                //                 / (await bn() - channel.bn) 
                //                 / BLOCK_TIME;
                // }
                channel.lastPrice = oraclePrice;
                channel.bn = await bn();
            }

            if (!uncheck) 
            {
                const cp = UI(await nestTrustFuturesV3.getChannel(channelIndex));
                const pp = {
                    lastPrice: toDecimal(decodeFloat(cp.lastPrice)),
                    PtL: parseFloat(cp.PtL) / MIU_DECIMALS,
                    PtS: parseFloat(cp.PtS) / MIU_DECIMALS,
                    miu: parseFloat(cp.miu) / MIU_DECIMALS,
                    bn: cp.bn
                }
                if (echo) 
                {
                    console.log({ jc: channel, cc: pp });
                }
                FEQ({ a: channel.lastPrice, b: pp.lastPrice, d: 0.0000000001 }, true);
                FEQ({ a: channel.miu, b: pp.miu, d: 0.0000000001 }, true);
                FEQ({ a: channel.PtL, b: pp.PtL, d: 0.0001 }, true);
                FEQ({ a: channel.PtS, b: pp.PtS, d: 0.0001 }, true);
            }

            return channel;
        }

        // Calculate value with current variables
        const _valueOf = function(miuT, balance, lever, orientation, basePrice, oraclePrice, appends) {
            if (orientation) {
                if (miuT < 0) miuT = 0;
            } else {
                if (miuT > 0) miuT = 0;
            }
            let Rt = lever * (oraclePrice / expMiuT(miuT) - basePrice) / basePrice;
            let b = 0;
            if (orientation) {
                b = balance * (1 + Rt) + appends;
            } else {
                b = balance * (1 - Rt) + appends;
            }
            if (b < 0) b = 0;
            return b;
        };

        // Calculate value of the order
        const balanceOf = async function(orderIndex, oraclePrice) {
            const order = ctx.orders[orderIndex];
            const pt = await currentPt(ctx.channels[order.channelIndex], oraclePrice);
            const miuT = (order.orientation ? pt.PtL : pt.PtS) - order.Pt;
            const value = _valueOf(
                miuT, order.balance, order.lever, order.orientation, order.basePrice, oraclePrice, order.appends);
            const cb = parseFloat(toDecimal(await nestTrustFuturesV3.balanceOf(orderIndex, toBigInt(oraclePrice))));
            FEQ({ a: value, b: cb, d: 0.00000001 });
            return value;
        };

        // Buy order
        const buy = async function(sender, channelIndex, lever, orientation, amount, echo) {
            await listAccounts(true);
            await nestTrustFuturesV3.buy(channelIndex, lever, orientation, amount * NEST_BASE);
            await listAccounts(true);

            let channel = await updateChannel(channelIndex, lastPrice(channelIndex));

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
                Pt: orientation ? channel.PtL : channel.PtS
            });

            await compareOrder(index);

            const totalNest = amount + amount * lever * FEE_RATE;
            if (echo) console.log({ totalNest });
            FEQ({ a: totalNest, b: parseFloat(previous.owner.NEST) - parseFloat(accounts.owner.NEST) }, true);
            FEQ({ a: totalNest, b: parseFloat(accounts.nestVault.NEST) - parseFloat(previous.nestVault.NEST) }, true);

            return index;
        };

        // Append order
        const add = async function(sender, index, amount) {
            await listAccounts(true);
            await nestTrustFuturesV3.add(index, amount * NEST_BASE);
            await listAccounts(true);

            ctx.orders[index].appends += amount;

            await compareOrder(index);
        };

        // Sell order
        const sell = async function(sender, index, echo) {
            await listAccounts(true);
            await nestTrustFuturesV3.sell(index);
            await listAccounts(true);

            let order = ctx.orders[index];
            // Update channel
            let channel = await updateChannel(order.channelIndex, lastPrice(order.channelIndex));
            
            // μT = P1 - P0
            let miuT = (order.orientation ? channel.PtL : channel.PtS) - order.Pt;
            // Query last price
            let oraclePrice = lastPrice(order.channelIndex);
            // Calculate value of order
            let value = _valueOf(
                miuT, 
                order.balance, 
                order.lever, 
                order.orientation, 
                order.basePrice, 
                oraclePrice,
                order.appends
            );
            // Service fee
            let fee = order.balance * order.lever * oraclePrice / order.basePrice * FEE_RATE;
            // Update order
            order.balance = 0;
            order.appends = 0;

            let totalNest = value - fee;
            if (echo) console.log({ totalNest, fee });
            if (totalNest < 0) totalNest = 0;

            FEQ({
                a: totalNest,
                b: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
                d: 0.000000001
            }, true);
            FEQ({
                a: totalNest,
                b: parseFloat(previous.nestVault.NEST) - parseFloat(accounts.nestVault.NEST),
                d: 0.000000001
            }, true);
        };

        // Liquidate orders
        const liquidate = async function(sender, indices) {
            await listAccounts(true);
            await nestTrustFuturesV3.liquidate(indices);
            await listAccounts(true);

            let reward = 0;
            for (let i = 0; i < indices.length; ++i) {
                let index = indices[i];
                
                let order = ctx.orders[index];
                let channel = ctx.channels[order.channelIndex];
                let oraclePrice = lastPrice(order.channelIndex);

                if (order.lever > 1 && order.balance > 0) {
                    // μT = P1 - P0
                    const pt = await currentPt(channel, oraclePrice);
                    let miuT = (order.orientation ? pt.PtL : pt.PtS) - order.Pt;
                    // Calculate value of order
                    let value = _valueOf(
                        miuT, 
                        order.balance, 
                        order.lever, 
                        order.orientation, 
                        order.basePrice, 
                        oraclePrice,
                        order.appends
                    );
                    if (value < 0) value = 0;

                    // Compare with liquidate line
                    if (value < order.balance * order.lever * oraclePrice / order.basePrice * FEE_RATE + 15 ||
                        value < order.balance * order.lever * 0.5 / 100
                    ) {
                        // Liquidated, update channel
                        await updateChannel(order.channelIndex, oraclePrice, true);

                        reward += value;
                        order.balance = 0;
                        order.appends = 0;

                        order.index = 0;
                        order.owner = '0x0000000000000000000000000000000000000000';
                        order.channelIndex = 0;
                        order.lever = 0;
                        order.orientation = false;
                        order.basePrice = 0;
                        order.Pt = 0;
                    }
                }

                await compareOrder(index);
            }

            FEQ({
               a: reward,
               b: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
               d: 0.0000001
            }, false);
            FEQ({
                a: reward,
                b: parseFloat(previous.nestVault.NEST) - parseFloat(accounts.nestVault.NEST),
                d: 0.0000001
            }, false);

            for (let i = 0; i < indices.length; ++i) {
                let index = indices[i];
                let order = ctx.orders[index];
                await updateChannel(order.channelIndex, ctx.prices[order.channelIndex], false);
            }
        };

        // Compare TrustOrder
        const compareTrustOrder = async function(index) {
            const to = UI((await nestTrustFuturesV3.listTrustOrder(index, 1, 1))[0]);
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
            await nestTrustFuturesV3.newTrustOrder(
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
                b: parseFloat(accounts.nestTrustFuturesV3.NEST) - parseFloat(previous.nestTrustFuturesV3.NEST),
                d: 0.000000001
            }, true);
        };

        // Execute LimitOrder
        const executeLimitOrder = async function(sender, trustOrderIndices) {
            await listAccounts(true);
            await nestTrustFuturesV3.executeLimitOrder(trustOrderIndices);
            await listAccounts(true);

            let totalNest = 0;

            for (let i = 0; i < trustOrderIndices.length; ++i) {
                let trustOrder = ctx.trustOrders[trustOrderIndices[i]];

                let order = ctx.orders[trustOrder.orderIndex];
                order.balance = trustOrder.balance;
                order.basePrice = ctx.prices[order.channelIndex];
                const pt = (await updateChannel(order.channelIndex, order.basePrice, true));
                order.Pt = order.orientation ? pt.PtL : pt.PtS;

                totalNest += (trustOrder.balance + trustOrder.fee);

                trustOrder.limitPrice = ctx.prices[order.channelIndex];
                trustOrder.balance = 0;
                trustOrder.fee = 0;
                trustOrder.status = 0;

                await compareOrder(order.index);
                await compareTrustOrder(trustOrderIndices[i]);
            }

            for (let i = 0; i < trustOrderIndices.length; ++i) {
                let trustOrder = ctx.trustOrders[trustOrderIndices[i]];
                await compareOrder(trustOrder.orderIndex);
                await compareTrustOrder(trustOrderIndices[i]);
                await updateChannel(ctx.orders[trustOrder.orderIndex].channelIndex, 0, false);
            }

            FEQ({
                a: totalNest,
                b: parseFloat(previous.nestTrustFuturesV3.NEST) - parseFloat(accounts.nestTrustFuturesV3.NEST),
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
            await nestTrustFuturesV3.newStopOrder(orderIndex, toBigInt(stopProfitPrice), toBigInt(stopLossPrice));

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
            await nestTrustFuturesV3.buyWithStopOrder(
                channelIndex, 
                lever, 
                orientation, 
                amount * NEST_BASE, 
                toBigInt(stopProfitPrice), 
                toBigInt(stopLossPrice)
            );
            await listAccounts(true);

            let channel = await updateChannel(channelIndex, lastPrice(channelIndex));

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
                Pt: orientation ? channel.PtL : channel.PtS
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
            FEQ({ a: totalNest, b: parseFloat(previous.owner.NEST) - parseFloat(accounts.owner.NEST), d: 0.000000001 }, true);
            FEQ({ a: totalNest, b: parseFloat(accounts.nestVault.NEST) - parseFloat(previous.nestVault.NEST), d: 0.000000001 }, true);
        };

        // Update LimitPrice
        const updateLimitPrice = async function(sender, trustOrderIndex, limitPrice) {
            await nestTrustFuturesV3.updateLimitPrice(trustOrderIndex, toBigInt(limitPrice));
            let trustOrder = ctx.trustOrders[trustOrderIndex];
            let order = ctx.orders[trustOrder.orderIndex];
            order.basePrice = limitPrice;
            trustOrder.limitPrice = limitPrice;

            await compareOrder(trustOrder.orderIndex);
            await compareTrustOrder(trustOrderIndex);
        };

        // Update StopPrice
        const updateStopPrice = async function(sender, trustOrderIndex, stopProfitPrice, stopLossPrice) {
            await nestTrustFuturesV3.updateStopPrice(trustOrderIndex, toBigInt(stopProfitPrice), toBigInt(stopLossPrice));

            let trustOrder = ctx.trustOrders[trustOrderIndex];
            trustOrder.stopProfitPrice = stopProfitPrice;
            trustOrder.stopLossPrice = stopLossPrice;

            await compareOrder(trustOrder.orderIndex);
            await compareTrustOrder(trustOrderIndex);
        };

        // Cancel LimitOrder
        const cancelLimitOrder = async function(sender, trustOrderIndex) {
            await listAccounts(true);
            await nestTrustFuturesV3.cancelLimitOrder(trustOrderIndex);
            await listAccounts(true);

            let trustOrder = ctx.trustOrders[trustOrderIndex];
            const totalNest = trustOrder.balance + trustOrder.fee + 15;
            trustOrder.balance = 0;
            trustOrder.fee = 0;
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
                b: parseFloat(previous.nestTrustFuturesV3.NEST) - parseFloat(accounts.nestTrustFuturesV3.NEST),
                d: 0.0000000001
            }, true);
        };

        // Execute StopOrder
        const executeStopOrder = async function(sender, trustOrderIndices) {
            await listAccounts(true);
            await nestTrustFuturesV3.executeStopOrder(trustOrderIndices);
            await listAccounts(true);

            let totalNest = 0;
            let totalExecuteFee = 0;

            for (let i = 0; i < trustOrderIndices.length; ++i) {
                let trustOrder = ctx.trustOrders[trustOrderIndices[i]];
                let order = ctx.orders[trustOrder.orderIndex];
                if (order.balance > 0) {
                    let oraclePrice = lastPrice(order.channelIndex);
                    let channel = await updateChannel(order.channelIndex, oraclePrice, true);
                    let miuT = (order.orientation ? channel.PtL : channel.PtS) - order.Pt;
                    let value = _valueOf(
                        miuT,
                        order.balance,
                        order.lever,
                        order.orientation,
                        order.basePrice,
                        oraclePrice,
                        order.appends
                    );

                    let fee = order.balance * order.lever * oraclePrice / order.basePrice * FEE_RATE;

                    if (value > fee + 15) {
                        totalNest += (value - fee - 15);
                    }
                    totalExecuteFee += 15;

                    order.balance = 0;
                    order.appends = 0;
                }
            }

            for (let i = 0; i < trustOrderIndices.length; ++i) {
                let trustOrder = ctx.trustOrders[trustOrderIndices[i]];
                await compareOrder(trustOrder.orderIndex);
                await compareTrustOrder(trustOrderIndices[i]);

                //await updateChannel(ctx.orders[trustOrder.orderIndex].channelIndex, 0, false);
            }

            FEQ({
                a: totalNest,
                b: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST),
                d: 0.0000000001
            }, true);
            FEQ({
                a: totalExecuteFee,
                b: parseFloat(accounts.nestTrustFuturesV3.NEST) - parseFloat(previous.nestTrustFuturesV3.NEST),
                d: 0.0000000001
            }, true);
            FEQ({
                a: totalNest + totalExecuteFee,
                b: parseFloat(previous.nestVault.NEST) - parseFloat(accounts.nestVault.NEST),
                d: 0.0000000001
            }, true);
        };

        // list Order
        const list = async function(sender, offset, count, order) {
            const cl = await nestTrustFuturesV3.list(offset, count, order);
            const jl = [];
            if (order == 0) {
                for (let i = 0; i < count; ++i) {
                    jl.push(ctx.orders[ctx.orders.length - 1 - i]);
                }
            } else {
                for (let i = 0; i < count; ++i) {
                    jl.push(ctx.orders[i]);
                }
            }
            
            for (let i = 0; i < count; ++i) {
                let jo = UI(jl[i]);
                let co = UI(cl[i]);
                co = {
                    index: co.index,
                    owner: co.owner,
                    balance: parseFloat(co.balance) / NEST_BASE,
                    channelIndex: co.channelIndex,
                    appends: parseFloat(co.appends) / NEST_BASE,
                    lever: co.lever,
                    orientation: co.orientation,
                    basePrice: toDecimal(co.basePrice),
                    Pt: parseFloat(co.Pt) / MIU_DECIMALS
                };
                console.log({ jo, co });
                
                // Compare two Order: basePrice, balance, appends, lever, valueOf, Pt
                FEQ({ a: jo.basePrice, b: co.basePrice, d: 0.00000000001 }, true);
                FEQ({ a: jo.balance, b: co.balance, d: 0.00000000001 }, true);
                FEQ({ a: jo.appends, b: co.appends, d: 0.00000000001 }, true);
                FEQ({ a: jo.lever, b: co.lever }, true);
                FEQ({ a: jo.Pt, b: co.Pt, d: 0.00001 }, true);
            }
        };

        // list TrustOrder
        const listTrustOrder = async function(sender, offset, count, order) {
            const cl = await nestTrustFuturesV3.listTrustOrder(offset, count, order);
            const jl = [];
            if (order == 0) {
                for (let i = 0; i < count; ++i) {
                    jl.push(ctx.trustOrders[ctx.trustOrders.length - 1 - i]);
                }
            } else {
                for (let i = 0; i < count; ++i) {
                    jl.push(ctx.trustOrders[i]);
                }
            }
            
            for (let i = 0; i < count; ++i) {
                let jo = UI(jl[i]);
                let co = UI(cl[i]);
                co = {
                    index: co.index,
                    owner: co.owner,
                    orderIndex: co.orderIndex,
                    channelIndex: co.channelIndex,
                    lever: co.lever,
                    orientation: co.orientation,
                    limitPrice: parseFloat(toDecimal(co.limitPrice)),
                    stopProfitPrice: parseFloat(toDecimal(co.stopProfitPrice)),
                    stopLossPrice: parseFloat(toDecimal(co.stopLossPrice)),
                    balance: parseFloat(co.balance) / NEST_BASE,
                    fee: parseFloat(co.fee) / NEST_BASE,
                    status: co.status
                };
                console.log({ jo, co });

                FEQ({ a: jo.orderIndex, b: co.orderIndex }, true);
                FEQ({ a: jo.channelIndex, b: co.channelIndex }, true);
                FEQ({ a: jo.lever, b: co.lever }, true);
                FEQ({ a: jo.limitPrice, b: co.limitPrice, d: 0.0000000001 }, true);
                FEQ({ a: jo.stopProfitPrice, b: co.stopProfitPrice, d: 0.0000000001 }, true);
                FEQ({ a: jo.stopLossPrice, b: co.stopLossPrice, d: 0.0000000001 }, true);
                FEQ({ a: jo.balance, b: co.balance }, true);
                FEQ({ a: jo.fee, b: co.fee }, true);
                FEQ({ a: jo.status, b: co.status }, true);
            }
        };

        // liquidate line
        const liquidateLine = function(sender, index) {
            let order = ctx.orders[index];
            let l1 = order.balance * order.lever * lastPrice(order.channelIndex) / order.basePrice * FEE_RATE + 15;
            let l2 = order.balance * order.lever * 0.5 / 100;
            return l1 < l2 ? l2 : l1;
        };

        await post(200, [1250, 16000, 250]);
        await usdt.transfer(owner.address, 10000000000000000000000000n);
        if (true) {
            console.log('1. create');
            await usdt.approve(pancakeRouter.address, 1000000000000000000000000n);
            await nest.approve(pancakeRouter.address, 1000000000000000000000000n);
            await pancakeRouter.addLiquidity(
                usdt.address,
                nest.address,
                toBigInt(10000),
                toBigInt(500000),
                0,
                0,
                owner.address,
                100000000000n
            );

            await listAccounts();
        }

        if (true) {
            console.log('2. buyWithUsdt');
            await usdt.approve(nestTrustFuturesV3.address, 1000000000000000000000000n);
            await nestTrustFuturesV3.buyWithUsdt(
                toBigInt(100),
                500,
                0,
                7,
                false,
                0,
                0
            );

            await listAccounts();
            console.log(UI(await nestTrustFuturesV3.list(0, 2, 0)));
        }
        
        if (true) {
            console.log('3. newTrustOrderWithUsdt');
            await nestTrustFuturesV3.newTrustOrderWithUsdt(
                toBigInt(50),
                500,
                0,
                7,
                true,
                toBigInt(1700),
                toBigInt(1800),
                toBigInt(1500)
            );
            await listAccounts();
            console.log(UI(await nestTrustFuturesV3.listTrustOrder(0, 2, 0)));
        }
    })
});
