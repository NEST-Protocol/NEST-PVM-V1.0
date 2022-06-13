const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, fortOptions, fortFutures, nestPriceFacade, 
            BLOCK_TIME, USDT_DECIMALS, MIU_LONG, MIU_SHORT } = await deploy();
        const USDT_BASE = (10 ** USDT_DECIMALS);

        const sigma = 0.00017807;
        //const miu = 0.000000025367;

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
                hbtc: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
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
            let c = await fortOptions.getConfig(tokenAddress);
            return {
                sigmaSQ: c.sigmaSQ.toString(),
                miu: c.miu.toString(),
                minPeriod: c.minPeriod.toString()
            }
        }
        
        if (true) {
            console.log('3. list1');
            console.log('tokenCount=' + await fortOptions.getOptionCount());
            let options = await fortOptions.list(0, 5, 0);
            console.log(options);

            options = await fortOptions.list(0, 5, 1);
            console.log(options);
        }

        if (false) {
            console.log('4. list2');

            console.log('tokenCount=' + await fortOptions.getOptionCount());
            await fortOptions.open(hbtc.address, 2450000000, true, 100000, toBigInt(1000), {
                value: toBigInt(0.01)
            });

            await fortOptions.open(hbtc.address, 52450000000, false, 100000, toBigInt(100000), {
                value: toBigInt(0.02)
            });
            console.log('tokenCount=' + await fortOptions.getOptionCount());
            let options = await fortOptions.list(0, 5, 0);
            console.log(options);

            options = await fortOptions.list(0, 5, 1);
            console.log(options);

            let fot1 = await fortOptions.getOptionInfo(hbtc.address, 2450000000, true, 100000);
            let fot2 = await fortOptions.getOptionInfo(hbtc.address, 52450000000, false, 100000);

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
            console.log('5. Open call option');
            const BLOCK = 2000000;
            for (var i = toBigInt(2450, USDT_DECIMALS) / 3n; i < toBigInt(2450, USDT_DECIMALS) * 3n; ) {
                //i = Math.floor(i);
                console.log('call, price:' + i);
                await fortOptions.open(hbtc.address, i, true, BLOCK, toBigInt(1000), {
                    value: toBigInt(0.01)
                });
                //let fot = await fortOptions.getOptionInfo(hbtc.address, i, true, BLOCK);
                let fot =  { index: j++ };
                console.log('fot: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)));
                let vc = Vc(oraclePrice, i, sigma, MIU_LONG, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let cal = 1000 * USDT_BASE / vc;
                console.log({
                    cal: cal.toString(),
                    bal: toDecimal(await fortOptions.balanceOf(fot.index, owner.address))
                });

                expect(Math.abs(parseFloat(toDecimal(await fortOptions.balanceOf(fot.index, owner.address))) - cal)).to.lt(0.0001);
                
                // exercise
                let fotBalance = await fortOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await fortOptions.exercise(fot.index, await fortOptions.balanceOf(fot.index, owner.address), {
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
            console.log('6. Open put option');
            const BLOCK = 2000000;
            for (var i = toBigInt(2650, USDT_DECIMALS); i < toBigInt(2450, USDT_DECIMALS) * 5n; ) {
                //i = Math.floor(i);
                console.log('put, price:' + i);
                await fortOptions.open(hbtc.address, i, false, BLOCK, toBigInt(1000), {
                    value: toBigInt(0.01)
                });
                // let fot = await fortOptions.getOptionInfo(hbtc.address, i, false, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)));
                let vp = Vp(oraclePrice, i, sigma, MIU_SHORT, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let put = 1000 * USDT_BASE / vp;
                console.log('put: ' + put);

                expect(Math.abs(parseFloat(toDecimal(await fortOptions.balanceOf(fot.index, owner.address))) - put)).to.lt(0.00001);
                
                // exercise
                let fotBalance = await fortOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await fortOptions.exercise(fot.index, await fortOptions.balanceOf(fot.index, owner.address), {
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
            console.log('7. Open call option');
            const BLOCK = 2000000;
            for (var i = toBigInt(2450, USDT_DECIMALS) / 3n; i < toBigInt(2450, USDT_DECIMALS) * 3n; ) {
                //i = Math.floor(i);
                console.log('call, price:' + i);
                await fortOptions.open(hbtc.address, i, true, BLOCK, toBigInt(1000), {
                    value: toBigInt(0.01)
                });
                // let fot = await fortOptions.getOptionInfo(hbtc.address, i, true, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)));
                let vc = Vc(oraclePrice, i, sigma, MIU_LONG, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let cal = 1000 * USDT_BASE / vc;
                console.log('cal: ' + cal);

                expect(Math.abs(parseFloat(toDecimal(await fortOptions.balanceOf(fot.index, owner.address))) - cal)).to.lt(0.0001);
                
                // exercise
                let fotBalance = await fortOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await fortOptions.exercise(fot.index, await fortOptions.balanceOf(fot.index, owner.address), {
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
            console.log('8. Open put option');
            const BLOCK = 2000000;
            for (var i = toBigInt(2650, USDT_DECIMALS); i < toBigInt(2450, USDT_DECIMALS) * 5n; ) {
                //i = Math.floor(i);
                console.log('put, price:' + i);
                await fortOptions.open(hbtc.address, i, false, BLOCK, toBigInt(1000), {
                    value: toBigInt(0.01)
                });
                // let fot = await fortOptions.getOptionInfo(hbtc.address, i, false, BLOCK);
                let fot = { index: j++ };
                console.log('fot: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)));
                let vp = Vp(oraclePrice, i, sigma, MIU_SHORT, (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME);
                let put = 1000 * USDT_BASE / vp;
                console.log('put: ' + put);

                expect(Math.abs(parseFloat(toDecimal(await fortOptions.balanceOf(fot.index, owner.address))) - put)).to.lt(0.00001);
                
                // exercise
                let fotBalance = await fortOptions.balanceOf(fot.index, owner.address);
                let before = BigInt(await dcu.balanceOf(owner.address));
                await fortOptions.exercise(fot.index, await fortOptions.balanceOf(fot.index, owner.address), {
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
    });
});
