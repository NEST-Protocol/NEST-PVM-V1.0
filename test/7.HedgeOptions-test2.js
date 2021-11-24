const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, hedgeOptions, hedgeFutures, nestPriceFacade, BLOCK_TIME, USDT_DECIMALS } = await deploy();
        const USDT_BASE = (10 ** USDT_DECIMALS);

        const sigma = 0.00021368;
        const miu = 0.000000025367;

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, toBigInt(3510, USDT_DECIMALS), 1);

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), USDT_DECIMALS),
                dcu: toDecimal(await dcu.balanceOf(account), 18),
            };
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
            };
        }

        const cfg = async function(tokenAddress) {
            let c = await hedgeOptions.getConfig(tokenAddress);
            return {
                sigmaSQ: c.sigmaSQ.toString(),
                miu: c.miu.toString(),
                minPeriod: c.minPeriod.toString()
            }
        }
        
        // if (true) {
        //     console.log('1. 读取配置');
        //     console.log(await cfg(usdt.address));
        //     console.log(await cfg(eth.address));
        //     console.log(await cfg(hbtc.address));
        // }

        // if (false) {
        //     console.log('2. 设置配置');
        //     await hedgeOptions.setConfig(eth.address, {
        //         sigmaSQ: '99999999',
        //         miu: '88888',
        //         minPeriod: '77777'
        //     });

        //     await hedgeOptions.setConfig(hbtc.address, {
        //         sigmaSQ: '333333',
        //         miu: '22222',
        //         minPeriod: '1111'
        //     });

        //     console.log(await cfg(usdt.address));
        //     console.log(await cfg(eth.address));
        //     console.log(await cfg(hbtc.address));
        // }

        if (true) {
            console.log('3. list1');
            console.log('tokenCount=' + await hedgeOptions.getOptionCount());
            let options = await hedgeOptions.list(0, 5, 0);
            console.log(options);

            options = await hedgeOptions.list(0, 5, 1);
            console.log(options);
        }

        if (false) {
            console.log('4. list2');

            console.log('tokenCount=' + await hedgeOptions.getOptionCount());
            await hedgeOptions.open(eth.address, 2450000000, true, 100000, toBigInt(1000), {
                value: toBigInt(0.01)
            });

            await hedgeOptions.open(hbtc.address, 52450000000, false, 100000, toBigInt(100000), {
                value: toBigInt(0.02)
            });
            console.log('tokenCount=' + await hedgeOptions.getOptionCount());
            let options = await hedgeOptions.list(0, 5, 0);
            console.log(options);

            options = await hedgeOptions.list(0, 5, 1);
            console.log(options);

            let fot1 = await hedgeOptions.getOptionInfo(eth.address, 2450000000, true, 100000);
            let fot2 = await hedgeOptions.getOptionInfo(hbtc.address, 52450000000, false, 100000);

            console.log('fot1: ' + fot1.index);
            console.log('fot2: ' + fot2.index);

            console.log('fot1-name: ' + fot1);
            console.log('fot2-name: ' + fot2);
        }

        const align = function(price) {
            // let decimals = 0;
            // while (price >= 10000000) {
            //     price = Math.floor(price / 10);
            //     ++decimals;
            // }
            // return price * 10 ** decimals;
            return parseFloat(price);
        }

        let oraclePrice = parseFloat(toBigInt(3510, USDT_DECIMALS));
        let j = 0;

        if (true) {
            console.log('5. 看涨期权买入算法');
            const BLOCK = 2000000;
            for (var i = toBigInt(2450, USDT_DECIMALS) / 3n; i < toBigInt(2450, USDT_DECIMALS) * 3n; ) {
                //i = Math.floor(i);
                console.log('看涨, 价格:' + i);
                await hedgeOptions.open(eth.address, i, true, BLOCK, toBigInt(1000), {
                    value: toBigInt(0.01)
                });
                //let fot = await hedgeOptions.getOptionInfo(eth.address, i, true, BLOCK);
                let fot =  { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vc = Vc(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let cal = 1000 * USDT_BASE / vc;
                console.log({
                    cal: cal.toString(),
                    bal: toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))
                });

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - cal)).to.lt(0.0001);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.01)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * (oraclePrice - align(i)) / USDT_BASE;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + toBigInt(2450, USDT_DECIMALS) / 3n;
            }
        }

        if (true) {
            console.log();
            console.log('6. 看跌期权买入算法');
            const BLOCK = 2000000;
            for (var i = toBigInt(2650, USDT_DECIMALS); i < toBigInt(2450, USDT_DECIMALS) * 5n; ) {
                //i = Math.floor(i);
                console.log('看跌, 价格:' + i);
                await hedgeOptions.open(eth.address, i, false, BLOCK, toBigInt(1000), {
                    value: toBigInt(0.01)
                });
                // let fot = await hedgeOptions.getOptionInfo(eth.address, i, false, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vp = Vp(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let put = 1000 * USDT_BASE / vp;
                console.log('put: ' + put);

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - put)).to.lt(0.00001);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.01)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * (align(i) - oraclePrice) / USDT_BASE;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + toBigInt(2450, USDT_DECIMALS) / 3n;
            }
        }

        oraclePrice = toBigInt(3410, USDT_DECIMALS);
        await nestPriceFacade.setPrice(usdt.address, oraclePrice, 1);
        if (true) {
            console.log('7. 看涨期权买入算法');
            const BLOCK = 2000000;
            for (var i = toBigInt(2450, USDT_DECIMALS) / 3n; i < toBigInt(2450, USDT_DECIMALS) * 3n; ) {
                //i = Math.floor(i);
                console.log('看涨, 价格:' + i);
                await hedgeOptions.open(eth.address, i, true, BLOCK, toBigInt(1000), {
                    value: toBigInt(0.01)
                });
                // let fot = await hedgeOptions.getOptionInfo(eth.address, i, true, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vc = Vc(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let cal = 1000 * USDT_BASE / vc;
                console.log('cal: ' + cal);

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - cal)).to.lt(0.0001);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.01)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * parseFloat(oraclePrice - BigInt(align(i))) / USDT_BASE;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + toBigInt(2450, USDT_DECIMALS) / 3n;
            }
        }

        if (true) {
            console.log();
            console.log('8. 看跌期权买入算法');
            const BLOCK = 2000000;
            for (var i = toBigInt(2650, USDT_DECIMALS); i < toBigInt(2450, USDT_DECIMALS) * 5n; ) {
                //i = Math.floor(i);
                console.log('看跌, 价格:' + i);
                await hedgeOptions.open(eth.address, i, false, BLOCK, toBigInt(1000), {
                    value: toBigInt(0.01)
                });
                // let fot = await hedgeOptions.getOptionInfo(eth.address, i, false, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vp = Vp(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let put = 1000 * USDT_BASE / vp;
                console.log('put: ' + put);

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - put)).to.lt(0.00001);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.01)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * parseFloat(BigInt(align(i)) - oraclePrice) / USDT_BASE;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + toBigInt(2450, USDT_DECIMALS) / 3n;
            }
        }

        oraclePrice = 46081081081;
        if (false) {
            console.log('9. 看涨期权买入算法HBTC');
            const BLOCK = 2000000;
            for (var i = 40000000000 / 3; i < 40000000000 * 2; ) {
                i = Math.floor(i);
                console.log('看涨, 价格:' + i);
                await hedgeOptions.open(hbtc.address, i, true, BLOCK, toBigInt(100000), {
                    value: toBigInt(0.02)
                });
                // let fot = await hedgeOptions.getOptionInfo(hbtc.address, i, true, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vc = Vc(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let cal = 100000 * 1000000 / vc;
                console.log('cal: ' + cal);

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - cal)).to.lt(0.001);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.02)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * (oraclePrice - align(i)) / 1000000;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + 40000000000 / 3;
            }
        }

        if (false) {
            console.log();
            console.log('10. 看跌期权买入算法HBTC');
            const BLOCK = 2000000;
            for (var i = 38000000000; i < 40000000000 * 5; ) {
                i = Math.floor(i);
                console.log('看跌, 价格:' + i);
                await hedgeOptions.open(hbtc.address, i, false, BLOCK, toBigInt(100000), {
                    value: toBigInt(0.02)
                });
                // let fot = await hedgeOptions.getOptionInfo(hbtc.address, i, false, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vp = Vp(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let put = 100000 * 1000000 / vp;
                console.log('put: ' + put);

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - put)).to.lt(0.002);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.02)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * (align(i) - oraclePrice) / 1000000;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + 40000000000 / 3;
            }
        }

        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);
        oraclePrice = 47432432432;
        if (false) {
            console.log('11. 看涨期权买入算法HBTC');
            const BLOCK = 2000000;
            for (var i = 40000000000 / 3; i < 40000000000 * 2; ) {
                i = Math.floor(i);
                console.log('看涨, 价格:' + i);
                await hedgeOptions.open(hbtc.address, i, true, BLOCK, toBigInt(100000), {
                    value: toBigInt(0.02)
                });
                // let fot = await hedgeOptions.getOptionInfo(hbtc.address, i, true, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vc = Vc(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let cal = 100000 * 1000000 / vc;
                console.log('cal: ' + cal);

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - cal)).to.lt(0.001);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.02)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * (oraclePrice - align(i)) / 1000000;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + 40000000000 / 3;
            }
        }

        if (false) {
            console.log();
            console.log('12. 看跌期权买入算法HBTC');
            const BLOCK = 2000000;
            for (var i = 38000000000; i < 40000000000 * 5; ) {
                i = Math.floor(i);
                console.log('看跌, 价格:' + i);
                await hedgeOptions.open(hbtc.address, i, false, BLOCK, toBigInt(100000), {
                    value: toBigInt(0.02)
                });
                // let fot = await hedgeOptions.getOptionInfo(hbtc.address, i, false, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vp = Vp(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let put = 100000 * 1000000 / vp;
                console.log('put: ' + put);

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - put)).to.lt(0.00001);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.02)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * (align(i) - oraclePrice) / 1000000;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + 40000000000 / 3;
            }
        }

        await nestPriceFacade.setPrice(hbtc.address, '73000000000000000', 1);
        oraclePrice = 48082191780;
        if (false) {
            console.log('13. 看涨期权买入算法HBTC');
            const BLOCK = 2000000;
            for (var i = 40000000000 / 3; i < 40000000000 * 2; ) {
                i = Math.floor(i);
                console.log('看涨, 价格:' + i);
                await hedgeOptions.open(hbtc.address, i, true, BLOCK, toBigInt(100000), {
                    value: toBigInt(0.02)
                });
                // let fot = await hedgeOptions.getOptionInfo(hbtc.address, i, true, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vc = Vc(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let cal = 100000 * 1000000 / vc;
                console.log('cal: ' + cal);

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - cal)).to.lt(0.001);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.02)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * (oraclePrice - align(i)) / 1000000;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + 40000000000 / 3;
            }
        }

        if (false) {
            console.log();
            console.log('14. 看跌期权买入算法HBTC');
            const BLOCK = 2000000;
            for (var i = 38000000000; i < 40000000000 * 5; ) {
                i = Math.floor(i);
                console.log('看跌, 价格:' + i);
                await hedgeOptions.open(hbtc.address, i, false, BLOCK, toBigInt(100000), {
                    value: toBigInt(0.02)
                });
                //let fot = await hedgeOptions.getOptionInfo(hbtc.address, i, false, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address)));
                let vp = Vp(oraclePrice, i, sigma, miu, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let put = 100000 * 1000000 / vp;
                console.log('put: ' + put);

                expect(Math.abs(parseFloat(toDecimal(await hedgeOptions.balanceOf(fot.index, owner.address))) - put)).to.lt(0.0001);
                
                // 行权
                let fotBalance = await hedgeOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await hedgeOptions.exercise(fot.index, await hedgeOptions.balanceOf(fot.index, owner.address), {
                    value: toBigInt(0.02)
                });
                let earn = BigInt(await dcu.balanceOf(owner.address)) - before;
                earn = toDecimal(earn);
                console.log('earn: ' + earn);

                let calc = parseFloat(toDecimal(fotBalance)) * (align(i) - oraclePrice) / 1000000;
                if (calc < 0) {
                    calc = 0;
                }
                console.log('calc: ' + calc);
                expect(Math.abs(earn - calc)).to.lt(0.0000000001);

                i = i + 40000000000 / 3;
            }
        }
    });
});
