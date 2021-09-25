const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, fort, fortEuropeanOption, fortLever, nestPriceFacade } = await deploy();

        await fort.setMinter(owner.address, 1);
        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address) )+ 'fort');
        console.log('owner: ' + owner.address);

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const BLOCK = 100000;
        
        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                fort: toDecimal(await fort.balanceOf(account), 18),
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
            let c = await fortEuropeanOption.getConfig(tokenAddress);
            return {
                sigmaSQ: c.sigmaSQ.toString(),
                miu: c.miu.toString(),
                minPeriod: c.minPeriod.toString()
            }
        }
        
        let TEST_PRIVATE = false;

        if (TEST_PRIVATE) {
            console.log('1. getKey');

            let key = await fortEuropeanOption._getKey(usdt.address, 99999, true, 1000000);
            console.log('key=' + key);
            key = await fortEuropeanOption._getKey(usdt.address, 99999, false, 1000000);
            console.log('key=' + key);

            key = await fortEuropeanOption._getKey(usdt.address, 99999 + 1, false, 1000000);
            console.log('key=' + key);

            key = await fortEuropeanOption._getKey(usdt.address, 99999 + 1, false, 1000000 - 1);
            console.log('key=' + key);

            key = await fortEuropeanOption._getKey(eth.address, 99999 + 1, false, 1000000 - 1);
            console.log('key=' + key);
        }

        if (TEST_PRIVATE) {
            console.log('2. align');

            console.log('align(0)=' + await fortEuropeanOption._align(0)); 
            console.log('align(1)=' + await fortEuropeanOption._align(1));
            console.log('align(10)=' + await fortEuropeanOption._align(10));
            console.log('align(100)=' + await fortEuropeanOption._align(100));
            console.log('align(1000)=' + await fortEuropeanOption._align(1000));
            console.log('align(10000)=' + await fortEuropeanOption._align(10000));
            console.log('align(100000)=' + await fortEuropeanOption._align(100000));
            console.log('align(1000000)=' + await fortEuropeanOption._align(1000000));
            console.log('align(10000000)=' + await fortEuropeanOption._align(10000000));
            console.log('align(100000000)=' + await fortEuropeanOption._align(100000000));
            console.log('align(123)=' + await fortEuropeanOption._align(123));
            console.log('align(1234567)=' + await fortEuropeanOption._align(1234567));
            console.log('align(12345678)=' + await fortEuropeanOption._align(12345678));
            console.log('align(9999999999)=' + await fortEuropeanOption._align(9999999999));
            console.log('align(34518)=' + await fortEuropeanOption._align(34518));
            console.log('align(9527)=' + await fortEuropeanOption._align(9527));
            console.log('align(245000000)=' + await fortEuropeanOption._align(245000000));
            console.log('align(99999999999999999999999999999999999)=' + await fortEuropeanOption._align('99999999999999999999999999999999999'));
            console.log('align(56666)=' + await fortEuropeanOption._align(56666));
            console.log('align(245000001)=' + await fortEuropeanOption._align(245000001));

            expect(await fortEuropeanOption._align(0)).to.equal(0);

            expect(await fortEuropeanOption._align(1)).to.equal(1);
            expect(await fortEuropeanOption._align(10)).to.equal(10);
            expect(await fortEuropeanOption._align(100)).to.equal(100);
            expect(await fortEuropeanOption._align(1000)).to.equal(1000);
            expect(await fortEuropeanOption._align(10000)).to.equal(10000);
            expect(await fortEuropeanOption._align(100000)).to.equal(100000);
            expect(await fortEuropeanOption._align(1000000)).to.equal(1000000);
            expect(await fortEuropeanOption._align(10000000)).to.equal(10000000);
            expect(await fortEuropeanOption._align(100000000)).to.equal(100000000);
            
            expect(await fortEuropeanOption._align(123)).to.equal(123);
            expect(await fortEuropeanOption._align(1234567)).to.equal(1234567);
            expect(await fortEuropeanOption._align(12345678)).to.eq(12345670);
            expect(await fortEuropeanOption._align(9999999999)).to.equal(9999999000);
            expect(await fortEuropeanOption._align(34518)).to.equal(34518);
            expect(await fortEuropeanOption._align(9527)).to.eq(9527);
            expect(await fortEuropeanOption._align(245000000)).to.eq(245000000);
            expect(await fortEuropeanOption._align('99999999999999999999999999999999999')).to.eq(BigInt('99999990000000000000000000000000000'));
            expect(await fortEuropeanOption._align(56666)).to.eq(56666);
            expect(await fortEuropeanOption._align(245000001)).to.eq(245000000);
        }

        // if (TEST_PRIVATE) {
        //     console.log("3. getDecimals");

        //     console.log('getDecimals(eth.address)=' + await fortEuropeanOption._getDecimals(eth.address));
        //     console.log('getDecimals(usdt.address)=' + await fortEuropeanOption._getDecimals(usdt.address));
        //     console.log('getDecimals(hbtc.address)=' + await fortEuropeanOption._getDecimals(hbtc.address));
        //     console.log('getDecimals(fort.address)=' + await fortEuropeanOption._getDecimals(fort.address));

        //     expect(await fortEuropeanOption._getDecimals(eth.address)).to.equal(18);
        //     expect(await fortEuropeanOption._getDecimals(usdt.address)).to.equal(6);
        //     expect(await fortEuropeanOption._getDecimals(hbtc.address)).to.equal(18);
        //     expect(await fortEuropeanOption._getDecimals(fort.address)).to.equal(18);
        // }

        if (TEST_PRIVATE) {
            console.log('4. optionName');
            const test = async function(name, price, orientation, endblock, v) {
                let n = await fortEuropeanOption._optionName(name, price, orientation, endblock);
                console.log({
                    name, price, orientation, endblock,
                    n
                });
                expect(n).to.eq(v);
            };

            await test("hbtc", 9999, true, 10000, "C9.999000-3HBTC10000");
            await test("hbtc", 9999, false, 10000, "P9.999000-3HBTC10000");
            await test("hbtc", 9999999999, false, 10000, "P9.999999+3HBTC10000");
            await test("Eth", 9999999999, false, 10000, "P9.999999+3ETH10000");
            await test("Eth", 9999999999, false, 98989898998425, "P9.999999+3ETH98989898998425");
            await test("CoFi", 12345678901, false, 98989898998425, "P1.234567+4COFI98989898998425");
        }

        if (TEST_PRIVATE) {
            console.log('5. _d18TOb64');
            const test = async function(v) {
                let x = (v << BigInt(64)) / BigInt('1000000000000000000');
                let r = BigInt(await fortEuropeanOption._d18TOb64(v));
                console.log(v + '; ' + r + ':' + x);
                expect(x).to.eq(r);
            };

            await test(BigInt('0'));
            await test(BigInt('1'));
            await test(BigInt('2'));
            await test(BigInt('3'));
            await test(BigInt('4'));
            await test(BigInt('5'));
            await test(BigInt('6'));
            await test(BigInt('7'));
            await test(BigInt('8'));
            await test(BigInt('9'));
            await test(BigInt('10'));

            for (var bi = BigInt(1); bi < BigInt('0x6F05B59D3B200000000000000000000');) {
                await test(bi);
                bi = bi * BigInt(77);
            }
            await test(BigInt('0x6F05B59D3B200000000000000000000') - BigInt('1'));
        }

        if (TEST_PRIVATE) {
            console.log('6. _toInt128');

            const test = async function(v) {
                let x = v;
                let r = BigInt(await fortEuropeanOption._toInt128(v));
                console.log(v + '; ' + r + ':' + x);
                expect(x).to.eq(r);
            };

            await test(BigInt('0'));
            await test(BigInt('1'));
            await test(BigInt('2'));
            await test(BigInt('3'));
            await test(BigInt('4'));
            await test(BigInt('5'));
            await test(BigInt('6'));
            await test(BigInt('7'));
            await test(BigInt('8'));
            await test(BigInt('9'));
            await test(BigInt('10'));

            for (var bi = BigInt(1); bi < BigInt('0x80000000000000000000000000000000');) {
                await test(bi);
                bi = bi * BigInt(77);
            }
            await test(BigInt('0x80000000000000000000000000000000') - BigInt('1'));
        }

        if (TEST_PRIVATE) {
            console.log('7. _toUInt');

            const test = async function(v) {
                let x = v;
                let r = BigInt(await fortEuropeanOption._toUInt(v));
                console.log(v + '; ' + r + ':' + x);
                expect(x).to.eq(r);
            };

            await test(BigInt('0'));
            await test(BigInt('1'));
            await test(BigInt('2'));
            await test(BigInt('3'));
            await test(BigInt('4'));
            await test(BigInt('5'));
            await test(BigInt('6'));
            await test(BigInt('7'));
            await test(BigInt('8'));
            await test(BigInt('9'));
            await test(BigInt('10'));

            for (var bi = BigInt(1); bi < BigInt('0x80000000000000000000000000000000');) {
                await test(bi);
                bi = bi * BigInt(77);
            }
            await test(BigInt('0x80000000000000000000000000000000') - BigInt('1'));
            //test(BigInt('-1'));
            //test(BigInt('-10'));
        }

        if (TEST_PRIVATE) {
            console.log('8. _snd');

            const test = async function(v) {
                let s1 = snd(v);
                let vi = BigInt(Math.floor(v * 1e18));
                let s2 = await fortEuropeanOption._snd((vi << BigInt(64)) / BigInt(1e18));
                s2 = BigInt(s2) * BigInt(1e18) / (BigInt(1) << BigInt(64));
                s2 = parseFloat(toDecimal(s2));

                console.log('v=' + v + '; s1=' + s1 + '; s2=' + s2);
                expect(Math.abs(s1 - s2)).to.lt(0.00001);
            };

            await test(0.5);
            for (var x = 1000; x > 0.00001;) {
                await test(x);
                await test(-x);

                x *= 0.7;
            }
        }

        if (TEST_PRIVATE) {
            console.log('9. _calcVc');

            const test = async function(sigma, miu, S0, T, K) {
                console.log({ sigma, miu, S0, T, K });
                let s1 = Vc(S0, K, sigma, miu, T);
                console.log('s1=' + s1);
                let s2 = await fortEuropeanOption._calcVc({
                    sigmaSQ: Math.floor(sigma * sigma * 1e18),
                    miu: (BigInt(Math.floor(miu * 1e18)) << BigInt(64)) / BigInt(1e18),
                    minPeriod: 10
                }, S0, T, K);

                s2 = parseFloat(toDecimal(BigInt(s2) * BigInt(1e18))) / (4294967296.0) / (4294967296.0);

                //console.log('s1=' + s1 + '; s2=' + s2);
                console.log('s2=' + s2);
                console.log();  
                if (s1 / S0 < 0.01 && s2 / S0 < 0.01 ) {} else
                expect(Math.abs(s1 - s2) / s1).to.lt(0.1);
            };

            let MIU = 0.3 / 86400 / 365;
            await test(0.00001, MIU, 2450000000, 14 * 10000, 2450000000);
            for (var sigma = 0.00005; sigma < 0.1; sigma = sigma * 3.1) {
                for (var miu = MIU / 10; miu < MIU * 20; miu *= 7.1) {
                    for (var S0 = 10000000; S0 < 1e10; S0 *= 137) {
                        for (var T = 1000 * 14; T < 100000000 * 14; T *= 61) {
                            for (var b = 0.7; b < 1.5; b *= 1.9) {
                                await test(sigma, miu, S0, T, Math.floor(S0 * b));
                            }
                        }
                    }
                }
            }
        }

        if (TEST_PRIVATE) {
            console.log('10. _calcVp');

            const test = async function(sigma, miu, S0, T, K) {
                console.log({ sigma, miu, S0, T, K });
                let s1 = Vp(S0, K, sigma, miu, T);
                console.log('s1=' + s1);
                let s2 = await fortEuropeanOption._calcVp({
                    sigmaSQ: Math.floor(sigma * sigma * 1e18),
                    miu: (BigInt(Math.floor(miu * 1e18)) << BigInt(64)) / BigInt(1e18),
                    minPeriod: 10
                }, S0, T, K);

                s2 = parseFloat(toDecimal(BigInt(s2) * BigInt(1e18))) / (4294967296.0) / (4294967296.0);

                //console.log('s1=' + s1 + '; s2=' + s2);
                console.log('s2=' + s2);
                console.log();  
                if (s1 / S0 < 0.01 && s2 / S0 < 0.01 ) {} else
                expect(Math.abs(s1 - s2) / s1).to.lt(0.1);
            };

            let MIU = 0.3 / 86400 / 365;
            await test(0.00001, MIU, 2450000000, 14 * 10000, 2450000000);
            for (var sigma = 0.00005; sigma < 0.1; sigma = sigma * 3.1) {
                for (var miu = MIU / 10; miu < MIU * 20; miu *= 7.1) {
                    for (var S0 = 10000000; S0 < 1e10; S0 *= 137) {
                        for (var T = 1000 * 14; T < 100000000 * 14; T *= 61) {
                            for (var b = 0.7; b < 1.5; b *= 1.9) {
                                await test(sigma, miu, S0, T, Math.floor(S0 * b));
                            }
                        }
                    }
                }
            }
        }
    });
});
