const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI, FEQ } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('48.NestFutures4V3-algorithm1.js', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, nest, nestFutures4V3, nestVault, pancakeRouter, BLOCK_TIME } = await deploy();

        const tokens = [eth, nest, usdt];
        let previous;
        let accounts;
        const listAccounts = async function(silent) {
            previous = accounts;
            accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestVault: await listBalances(nestVault, tokens),
                nestFutures4V3: await listBalances(nestFutures4V3, tokens)
            };
            if (!silent) console.log(accounts);
            return accounts;
        }

        const NEST_BASE = 10000;
        const MIU_DECIMALS = 1e12;
        const FEE_RATE = 0.0005;
        const S_CLEARED = 0x00;
        const S_BUY_REQUEST = 0x01;
        const S_NORMAL = 0x02;
        const S_SELL_REQUEST = 0x03;
        const S_LIMIT_REQUEST = 0x04;
        const S_CANCELED = 0xFF;
        const SLIDING_POINT = 0.0002;
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

        // Impact cost
        const impactCost = function(vol) {
            return 5.556e-11 * vol + 0.0004444;
        };

        // Post price
        const post = async function(period, prices) {
            // Post price to the contract
            await nestFutures4V3.post(period, [toBigInt(prices[0]), toBigInt(prices[1]), toBigInt(prices[2])]);
            // Update price to context
            ctx.prices[0] = prices[0],
            ctx.prices[1] = prices[1],
            ctx.prices[2] = prices[2];
        };

        // Post price and execute
        const execute = async function(period, prices, buyOrderIndices, sellOrderIndices, limitOrderIndices, stopOrderIndices, liquidateOrderIndices) {
            await listAccounts(true);
            // Post price to the contract
            await nestFutures4V3.execute(period, [toBigInt(prices[0]), toBigInt(prices[1]), toBigInt(prices[2])], 
                buyOrderIndices,
                sellOrderIndices,
                limitOrderIndices,
                stopOrderIndices,
                liquidateOrderIndices
            );
            await listAccounts(true);
            // Update price to context
            ctx.prices[0] = prices[0],
            ctx.prices[1] = prices[1],
            ctx.prices[2] = prices[2];

            let totalNest = 0;
            let totalExecuteFee = 0;

            // 1. Execute buy orders
            for (var i = 0; i < buyOrderIndices.length; ++i) {
                let orderIndex = buyOrderIndices[i];
                let order = ctx.orders[orderIndex];
                let oraclePrice = ctx.prices[order.channelIndex];
                if (order.status == S_BUY_REQUEST) {
                    if (order.orientation) {
                        if (order.basePrice >= oraclePrice && order.basePrice <= oraclePrice * (1 + SLIDING_POINT)) {
                            order.basePrice = order.basePrice * (1 + impactCost(order.balance * order.lever));
                            order.status = S_NORMAL;
                            //order.openBlock = await bn();
                        } else {
                            order.status = S_CANCELED;
                            // TODO: balance
                            totalNest += (order.balance + order.fee);
                        }
                    } else {
                        if (order.basePrice <= oraclePrice && order.basePrice >= oraclePrice * (1 - SLIDING_POINT)) {
                            order.basePrice = order.basePrice / (1 + impactCost(order.balance * order.lever));
                            order.status = S_NORMAL;
                            //order.openBlock = await bn();
                        } else {
                            order.status = S_CANCELED;
                            // TODO: balance
                            totalNest += (order.balance + order.fee);
                        }
                    }
                }
            }

            // 2. Execute sell orders
            for (var i = 0; i < sellOrderIndices.length; ++i) {
                let orderIndex = sellOrderIndices[i];
                let order = ctx.orders[orderIndex];
                if (order.status == S_SELL_REQUEST) {
                    let order = ctx.orders[orderIndex];
                    
                    // μT = P1 - P0
                    //let miuT = (order.orientation ? channel.PtL : channel.PtS) - order.Pt;
                    let miuT = order.orientation
                            ? 3.472e-9 * (await bn() - order.openBlock) * BLOCK_TIME
                            :-3.472e-9 * (await bn() - order.openBlock) * BLOCK_TIME;
                    // Query last price
                    let oraclePrice = ctx.prices[order.channelIndex];
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
                    order.status = S_CLEARED;

                    let nest = value - fee;
                    //if (echo) console.log({ totalNest, fee });
                    if (nest < 0) nest = 0;
                    totalNest += nest;
                }
            }

            // 3. Execute limit orders
            for (var i = 0; i < limitOrderIndices.length; ++i) {
                let orderIndex = limitOrderIndices[i];
                let order = ctx.orders[orderIndex];
                order.openBlock = await bn();
                order.basePrice = order.orientation
                    ? ctx.prices[order.channelIndex] * (1 + impactCost(order.balance * order.lever))
                    : ctx.prices[order.channelIndex] / (1 + impactCost(order.balance * order.lever))
                ;

                //totalNest += (order.balance + order.fee);

                order.status = S_NORMAL;
            }

            // 4. Execute stop orders
            for (var i = 0; i < stopOrderIndices.length; ++i) {
                let orderIndex = stopOrderIndices[i];
                let order = ctx.orders[orderIndex];
                if (order.balance > 0) {
                    let oraclePrice = ctx.prices[order.channelIndex];
                    const miuT = order.orientation
                       ? 3.472e-9 * (await bn() - order.openBlock) * BLOCK_TIME
                       :-3.472e-9 * (await bn() - order.openBlock) * BLOCK_TIME;
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
                    order.status = S_CLEARED;
                }
            }

            // 5. Liquidate
            for (var i = 0; i < liquidateOrderIndices.length; ++i) {
                let orderIndex = liquidateOrderIndices[i];
                let order = ctx.orders[orderIndex];
                if (order.lever > 1 && order.balance > 0) {
                    let oraclePrice = ctx.prices[order.channelIndex];
                    const miuT = order.orientation
                       ? 3.472e-9 * (await bn() - order.openBlock) * BLOCK_TIME
                       :-3.472e-9 * (await bn() - order.openBlock) * BLOCK_TIME;
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
                        totalNest += value;
                        order.balance = 0;
                        order.fee = 0;
                        order.appends = 0;

                        //order.index = 0;
                        order.owner = '0x0000000000000000000000000000000000000000';
                        order.channelIndex = 0;
                        order.lever = 0;
                        order.orientation = false;
                        order.basePrice = 0;
                        order.openBlock = 0;
                        order.status = S_CLEARED;
                    }
                }
            }

            //console.log({ totalNest: totalNest, balanceD: parseFloat(accounts.owner.NEST) - parseFloat(previous.owner.NEST) })
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

            // buyOrderIndices, sellOrderIndices, limitOrderIndices, stopOrderIndices, liquidateOrderIndices
            for (var i = 0; i < buyOrderIndices.length; ++i) { await compareOrder(buyOrderIndices[i]); }
            for (var i = 0; i < sellOrderIndices.length; ++i) { await compareOrder(sellOrderIndices[i]); }
            for (var i = 0; i < limitOrderIndices.length; ++i) { await compareOrder(limitOrderIndices[i]); }
            for (var i = 0; i < stopOrderIndices.length; ++i) { await compareOrder(stopOrderIndices[i]); }
            for (var i = 0; i < liquidateOrderIndices.length; ++i) { await compareOrder(liquidateOrderIndices[i]); }
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
            const co = UI((await nestFutures4V3.list(index, 1, 1))[0]);
            // Parse Order to local format
            const po = {
                index: co.index,
                owner: co.owner,
                balance: parseFloat(co.balance) / NEST_BASE,
                channelIndex: co.channelIndex,
                lever: co.lever,
                appends: parseFloat(co.appends) / NEST_BASE,
                orientation: co.orientation,
                basePrice: toDecimal(co.basePrice),
                openBlock: co.openBlock,
                status: co.status,
                fee: parseFloat(co.fee) / NEST_BASE,
                stopProfitPrice: toDecimal(co.stopProfitPrice),
                stopLossPrice: toDecimal(co.stopLossPrice)
            };
            //console.log({ jo: jo, po: po });
            
            // Compare two Order: basePrice, balance, appends, lever, valueOf, Pt
            FEQ({ a: jo.basePrice, b: po.basePrice, d: 0.00000000001 }, true);
            FEQ({ a: jo.balance, b: po.balance, d: 0.00000000001 }, true);
            FEQ({ a: jo.appends, b: po.appends, d: 0.00000000001 }, true);
            FEQ({ a: jo.lever, b: po.lever }, true);
            //FEQ({ a: jo.Pt, b: po.Pt, d: 0.00001 }, true);
            FEQ({ a: jo.openBlock, b: po.openBlock }, true);
            FEQ({ a: jo.status, b: po.status }, true);

            // TODO: Compare more fields
            FEQ({ a: jo.fee, b: po.fee, d: 0.0000000001 }, true);
            FEQ({ a: jo.stopProfitPrice, b: po.stopProfitPrice, d: 0.0000000001 }, true);
            FEQ({ a: jo.stopLossPrice, b: po.stopLossPrice, d: 0.0000000001 }, true);
        };

        // Decode the floating-point representation of fraction * 16 ^ exponent to uint
        const decodeFloat = function(floatValue) {
            const bi = BigInt(floatValue);
            return (bi >> 6n) << ((bi & 0x3Fn) << 2n);
        };

        // Calculate value with current variables
        const _valueOf = function(miuT, balance, lever, orientation, basePrice, oraclePrice, appends) {
            if (orientation) {
                if (miuT < 0) miuT = 0;
            } else {
                if (miuT > 0) miuT = 0;
            }
            if (orientation) {
                oraclePrice = oraclePrice / (1 + impactCost(balance * lever * oraclePrice / basePrice));
            } else {
                oraclePrice = oraclePrice * (1 + impactCost(balance * lever * oraclePrice / basePrice));
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
            const miuT = order.orientation
                       ? 3.472e-9 * (await bn() - order.openBlock) * BLOCK_TIME
                       :-3.472e-9 * (await bn() - order.openBlock) * BLOCK_TIME;

            const value = _valueOf(
                miuT, order.balance, order.lever, order.orientation, order.basePrice, oraclePrice, order.appends);
            const cb = parseFloat(toDecimal(await nestFutures4V3.balanceOf(orderIndex, toBigInt(oraclePrice))));
            FEQ({ a: value, b: cb, d: 0.00000001 });
            return value;
        };

        // Create new buy request
        const newBuyRequest = async function(sender, channelIndex, lever, orientation, amount, basePrice,
            limit, stopProfitPrice, stopLossPrice, echo) {
            await listAccounts(true);
            await nestFutures4V3.newBuyRequest(channelIndex, lever, orientation, amount * NEST_BASE, 
                toBigInt(basePrice), limit, toBigInt(stopProfitPrice), toBigInt(stopLossPrice));
            await listAccounts(true);

            const index = ctx.orders.length;
            ctx.orders.push({
                index: index, 
                owner: sender.address,
                balance: amount,
                channelIndex: channelIndex,
                lever: lever,
                appends: 0,
                orientation: orientation,
                basePrice: basePrice,
                openBlock: await bn(),
                status: limit ? S_LIMIT_REQUEST : S_BUY_REQUEST,
                fee: amount * lever * FEE_RATE,
                stopProfitPrice: stopProfitPrice,
                stopLossPrice: stopLossPrice
            });

            await compareOrder(index);

            const totalNest = amount + amount * lever * FEE_RATE + (limit ? 15 : 0);
            if (echo) console.log({ totalNest });
            //console.log({ totalNest, balanceD: parseFloat(previous.owner.NEST) - parseFloat(accounts.owner.NEST) })
            FEQ({ a: totalNest, b: parseFloat(previous.owner.NEST) - parseFloat(accounts.owner.NEST), d: 0.0000001 }, true);
            FEQ({ a: totalNest, b: parseFloat(accounts.nestVault.NEST) - parseFloat(previous.nestVault.NEST), d: 0.0000001 }, true);

            return index;
        };

        // Append order
        const add = async function(sender, index, amount) {
            await listAccounts(true);
            await nestFutures4V3.add(index, amount * NEST_BASE);
            await listAccounts(true);

            ctx.orders[index].appends += amount;

            await compareOrder(index);
        };

        // Create new sell request
        const newSellRequest = async function(sender, index, echo) {
            await nestFutures4V3.newSellRequest(index);
            let order = ctx.orders[index];
            order.status = S_SELL_REQUEST;
        };

        // Update LimitPrice
        const updateLimitPrice = async function(sender, orderIndex, limitPrice) {
            await nestFutures4V3.updateLimitPrice(orderIndex, toBigInt(limitPrice));
            let order = ctx.orders[orderIndex];
            order.basePrice = limitPrice;

            await compareOrder(orderIndex);
        };

        // Update StopPrice
        const updateStopPrice = async function(sender, orderIndex, stopProfitPrice, stopLossPrice) {
            await nestFutures4V3.updateStopPrice(orderIndex, toBigInt(stopProfitPrice), toBigInt(stopLossPrice));

            let order = ctx.orders[orderIndex];
            order.stopProfitPrice = stopProfitPrice;
            order.stopLossPrice = stopLossPrice;

            await compareOrder(orderIndex);
        };

        // Cancel buy request
        const cancelBuyRequest = async function(sender, orderIndex) {
            await listAccounts(true);
            await nestFutures4V3.cancelBuyRequest(orderIndex);
            await listAccounts(true);
            
            let order = ctx.orders[orderIndex];
            const totalNest = order.balance + order.fee + (order.status == S_LIMIT_REQUEST ? 15 : 0);
            order.balance = 0;
            order.fee = 0;
            order.status = S_CANCELED;

            await compareOrder(orderIndex);

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

        // list Order
        const list = async function(sender, offset, count, order) {
            const cl = await nestFutures4V3.list(offset, count, order);
            const jl = [];
            if (order == 0) {
                for (let i = 0; i < count; ++i) {
                    jl.push(ctx.orders[ctx.orders.length - 1 - i - offset]);
                }
            } else {
                for (let i = 0; i < count; ++i) {
                    jl.push(ctx.orders[i + offset]);
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
                    lever: co.lever,
                    appends: parseFloat(co.appends) / NEST_BASE,
                    orientation: co.orientation,
                    basePrice: toDecimal(co.basePrice),
                    openBlock: co.openBlock,
                    status: co.status,
                    fee: parseFloat(co.fee) / NEST_BASE,
                    stopProfitPrice: toDecimal(co.stopProfitPrice),
                    stopLossPrice: toDecimal(co.stopLossPrice)
                };
                console.log({ jo, co });
                
                // Compare two Order: basePrice, balance, appends, lever, valueOf, Pt
                FEQ({ a: jo.basePrice, b: co.basePrice, d: 0.00000000001 }, true);
                FEQ({ a: jo.balance, b: co.balance, d: 0.00000000001 }, true);
                FEQ({ a: jo.appends, b: co.appends, d: 0.00000000001 }, true);
                FEQ({ a: jo.lever, b: co.lever }, true);
                FEQ({ a: jo.openBlock, b: co.openBlock }, true);
                FEQ({ a: jo.status, b: co.status }, true);
                FEQ({ a: jo.fee, b: co.fee }, true);
                FEQ({ a: jo.stopProfitPrice, b: co.stopProfitPrice, d: 0.00000000001 }, true);
                FEQ({ a: jo.stopLossPrice, b: co.stopLossPrice, d: 0.00000000001 }, true);
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
        
        // 1. Normal buy (eth&btc&bnb, long&short, lever0-51), check channel, check balance, check order
        if (true) {
            console.log('1. buy');

            // eth-long
            await newBuyRequest(owner, 0, 1, true, 1000, 1250, false, 0, 0);                 // 0
            await newBuyRequest(owner, 0, 2, true, 2000, 1250, false, 0, 0);                 // 1
            await newBuyRequest(owner, 0, 5, true, 5000, 1250, false, 0, 0);                 // 2
            await newBuyRequest(owner, 0, 10, true, 10000, 1250, false, 0, 0);               // 3
            await newBuyRequest(owner, 0, 20, true, 20000, 1250, false, 0, 0);               // 4
            await newBuyRequest(owner, 0, 50, true, 50000, 1250, false, 0, 0);               // 5

            // eth-short
            await newBuyRequest(owner, 0, 1, false, 1000, 1250, false, 0, 0);                // 6
            await newBuyRequest(owner, 0, 2, false, 2000, 1250, false, 0, 0);                // 7
            await newBuyRequest(owner, 0, 5, false, 5000, 1250, false, 0, 0);                // 8
            await newBuyRequest(owner, 0, 10, false, 10000, 1250, false, 0, 0);              // 9
            await newBuyRequest(owner, 0, 20, false, 20000, 1250, false, 0, 0);              // 10
            await newBuyRequest(owner, 0, 50, false, 50000, 1250, false, 0, 0);              // 11

            // btc-long
            await newBuyRequest(owner, 1, 1, true, 1000, 16000, false, 0, 0);                 // 12
            await newBuyRequest(owner, 1, 2, true, 2000, 16000, false, 0, 0);                 // 13
            await newBuyRequest(owner, 1, 5, true, 5000, 16000, false, 0, 0);                 // 14
            await newBuyRequest(owner, 1, 10, true, 10000, 16000, false, 0, 0);               // 15
            await newBuyRequest(owner, 1, 20, true, 20000, 16000, false, 0, 0);               // 16
            await newBuyRequest(owner, 1, 50, true, 50000, 16000, false, 0, 0);               // 17
            // btc-short
            await newBuyRequest(owner, 1, 1, false, 1000, 16000, false, 0, 0);                // 18
            await newBuyRequest(owner, 1, 2, false, 2000, 16000, false, 0, 0);                // 19
            await newBuyRequest(owner, 1, 5, false, 5000, 16000, false, 0, 0);                // 20
            await newBuyRequest(owner, 1, 10, false, 10000, 16000, false, 0, 0);              // 21
            await newBuyRequest(owner, 1, 20, false, 20000, 16000, false, 0, 0);              // 22
            await newBuyRequest(owner, 1, 50, false, 50000, 16000, false, 0, 0);              // 23

            // bnb-long
            await newBuyRequest(owner, 2, 1, true, 1000, 250, false, 0, 0);                 // 24
            await newBuyRequest(owner, 2, 2, true, 2000, 250, false, 0, 0);                 // 25
            await newBuyRequest(owner, 2, 5, true, 5000, 250, false, 0, 0);                 // 26
            await newBuyRequest(owner, 2, 10, true, 10000, 250, false, 0, 0);               // 27
            await newBuyRequest(owner, 2, 20, true, 20000, 250, false, 0, 0);               // 28
            await newBuyRequest(owner, 2, 50, true, 50000, 250, false, 0, 0);               // 29
            // bnb-short
            await newBuyRequest(owner, 2, 1, false, 1000, 250, false, 0, 0);                // 30
            await newBuyRequest(owner, 2, 2, false, 2000, 250, false, 0, 0);                // 31
            await newBuyRequest(owner, 2, 5, false, 5000, 250, false, 0, 0);                // 32
            await newBuyRequest(owner, 2, 10, false, 10000, 250, false, 0, 0);              // 33
            await newBuyRequest(owner, 2, 20, false, 20000, 250, false, 0, 0);              // 34
            await newBuyRequest(owner, 2, 50, false, 50000, 250, false, 0, 0);              // 35

            await list(owner, 0, 1, 1);
            await listAccounts();
        }

        if (true) {
            console.log('2. execute');
            await execute(200, [1250, 16000, 250], [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35], [], [], [], []);
            await list(owner, 0, 10, 1);
        }

        // 2. Normal sell (eth&btc&bnb, long&short, lever0-51), check channel, check balance, check order
        if (true) {
            console.log('2. sell');
            //await post(200, [1260, 17000, 260]);
            await newSellRequest(owner, 4, true);
            //await sell(owner, 10);
            //await updateChannel(0, 0, false, true);

            await newSellRequest(owner, 16, true);
            //await sell(owner, 22);
            //await updateChannel(1, 0, false, true);

            await newSellRequest(owner, 28, true);
            //await sell(owner, 34);
            //await updateChannel(2, 0, false, true);

            await execute(200, [1260, 17000, 260], [], [4, 16, 28], [], [], []);

            await listAccounts();
        }

        // 3. Normal add (eth&btc&bnb, long&short, lever0-51), check channel, check balance, check order
        if (true) {
            console.log('3. add');
            await add(owner, 34, 5049);
            //await add(owner, 16, 16);
            await add(owner, 23, 60000);
            for (let i = 0; i < 36; ++i) {
                console.log({
                    index: i,
                    balance: await balanceOf(i, lastPrice(ctx.orders[i].channelIndex)),
                    line: liquidateLine(owner, i),
                    bomb: await balanceOf(i, lastPrice(ctx.orders[i].channelIndex)) < liquidateLine(owner, i)
                });
            }
            await list(owner, 0, 1, 1);
        }

        // 4. Sell with added order (eth&btc&bnb, long&short, lever0-51), check channel, check balance, check order
        if (true) {
            console.log('4. sell');
            await newSellRequest(owner, 34, true);
            //await newSellRequest(owner, 16, true);
            await newSellRequest(owner, 23, true);
            await execute(200, [1260, 17000, 260], [], [34,23], [], [], []);

            await listAccounts();
        }

        // 5. Post different price and calculate order value, liquidate line
        if (false) {
            console.log('5. post');
            let i = 19;
            for (let p = 100; p < 100000; p = parseInt(p * 1.1)) {
                await post(200, [1260, p, 260]);
                console.log({ 
                    index: i,
                    oraclePrice: lastPrice(ctx.orders[i].channelIndex),
                    balance: await balanceOf(i, lastPrice(ctx.orders[i].channelIndex)),
                    line: liquidateLine(owner, i),
                    bomb: await balanceOf(i, lastPrice(ctx.orders[i].channelIndex)) < liquidateLine(owner, i)
                });
            }
        }

        // 6. Post different price and liquidate
        if (true) {
            console.log('6. liquidate');
            const orderIndices = [
                0,1,2,3,4,5,6,7,8,9,10,11,12,13,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,14,15,16,17,18,19,20,
                21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
                0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
                0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
                0,1,2,3,4,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,14,15,16,17,18,19,20,21,22,
                23,24,25,26,27,28,29,30,31,32,33,34,5,6,7,8,9,10,11,12,13,35,
                0,1,2,3,4,5,6,7,8,9,10,11,12,29,30,31,32,33,34,35
            ];
            await post(200, [1230, 15500, 245]);
            for (let i = 0; i < 36; ++i) { 
                if (false) {
                    console.log({
                        index: i,
                        balance: await balanceOf(i, lastPrice(ctx.orders[i].channelIndex)),
                        line: liquidateLine(owner, i),
                        bomb: await balanceOf(i, lastPrice(ctx.orders[i].channelIndex)) < liquidateLine(owner, i)
                    });
                }
            }
            await listAccounts();
            await execute(200, [1230, 15500, 245], [], [], [], [], orderIndices);
            await listAccounts();

            await list(owner, 5, 1, 1);
            await execute(200, [1230, 15500, 245], [], [], [], [], orderIndices);
            await listAccounts();
        }

        // 7. Create LimitOrder and execute (eth&btc&bnb, long&short, lever0-51), check channel, check balance, check order
        if (true) {
            console.log('7. createLimitOrder');
            await newBuyRequest(owner, 0, 3, true, 3000, 1235, true, 1800, 800);
            await newBuyRequest(owner, 1, 7, false, 88888, 15000, true, 10000, 20000);
            await newBuyRequest(owner, 2, 4, true, 5000, 200, true, 400, 100);
            await list(owner, 0, 4, 0);
        }

        // 8. updateLimitPrice
        if (true) {
            console.log('8. updateLimitPrice');
            await updateLimitPrice(owner, 37, 15100);
            await list(owner, 0, 4, 0);
        }

        // 9. updateStopPrice
        if (true) {
            console.log('9. updateStopPrice');
            await updateStopPrice(owner, 1, 11111, 22222);
            await list(owner, 0, 4, 0);
        }
        
        // 11. buyWithStopOrder
        if (false) {
            console.log('11. buyWithStopOrder');
            await buyWithStopOrder(owner, 1, 2, true, 100, 18888, 12222);
            await list(owner, 0, 1, 0);
            await listTrustOrder(owner, 0, 1, 0);
        }

        // 14. cancelLimitOrder
        if (false) {
            console.log('14. cancelLimitOrder');
            await cancelLimitOrder(owner, [1]);
            return;
        }
        // 12. executeLimitOrder
        else if (true) {
            console.log('13. executeLimitOrder');
            await execute(200, [1230, 15500, 245], [], [], [36, 37/*, 38*/], [], []);
            //await list(owner, 0, 4, 0);
        }
        // 10. newStopOrder
        if (true) {
            console.log('10. newStopOrder');
            await updateStopPrice(owner, 36, 1801, 801);
            await list(owner, 36, 1, 1);
        }
        // 13. executeStopOrder
        if (true) {
            console.log('11. executeStopOrder');
            await execute(200, [1801, 15500, 245], [], [], [], [36], []);
            await list(owner, 36, 1, 1);
        }
        
        if (true) {
            console.log('12. cancelBuyRequest');
            await cancelBuyRequest(owner, 38);
            await list(owner, 38, 1, 0);
            return;
        }

        if (true) {
            console.log('1. create');
            await usdt.transfer(owner.address, 1000000000000000000000000n);
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
            console.log('12. newBuyRequestWithUsdt');
            await usdt.approve(nestFutures4V3.address, 10000000000000000000000000n);
            
            await listAccounts();
            await nestFutures4V3.newBuyRequestWithUsdt(
                //uint usdtAmount,
                toBigInt(10),
                //uint minNestAmount,
                toBigInt(100),
                //uint channelIndex,
                0,
                //uint lever,
                1,
                //bool orientation,
                true,
                //uint basePrice,
                toBigInt(1230),
                //bool limit,
                false,
                //uint stopProfitPrice,
                0,
                //uint stopLossPrice
                0
            );
            await listAccounts();
        }
    });
});
