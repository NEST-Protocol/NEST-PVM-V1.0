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

        const FortOptionToken = await ethers.getContractFactory('FortOptionToken');
        const FortLeverToken = await ethers.getContractFactory('FortLeverToken');
        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

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
        
        const align = function(price) {
            let decimals = 0;
            while (price >= 10000000) {
                price = Math.floor(price / 10);
                ++decimals;
            }
            return price * 10 ** decimals;
        }

        if (true) {
            console.log('1. list');
            let l = await fortLever.list(0, 20, 0);
            console.log(l);
            l = await fortLever.list(0, 20, 1);
            console.log(l);
        }

        let addrs = [eth.address, hbtc.address];
        let levers = [1, 2, 5];
        let oriens = [true, false];
        if (true) {
            console.log('2. getTokenCount');
            let tokenCount = await fortLever.getTokenCount();
            console.log('tokenCount=' + tokenCount);
            let l = await fortLever.list(0, tokenCount, 0);
            for (var i = 0; i < l.length; ++i) {
                let addr = l[i];
                let fot = await FortLeverToken.attach(addr);
                let ti = await fot.getLeverInfo();
                console.log({
                    name: await fot.name(),
                    tokenAddress: ti.tokenAddress.toString(),
                    price: ti.price.toString(),
                    blockNumber: ti.blockNumber.toString()
                })
            }

            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lotAddress = await fortLever.getLeverToken(addrs[addr], levers[lever], oriens[orien]);
                        let lot = await FortLeverToken.attach(lotAddress);
                        console.log(await lot.name());
                    }
                }
            }
        }

        if (true) {
            console.log('3. create');
            let receipt = await fortLever.create(hbtc.address, 3, false);
            await showReceipt(receipt);
            let tokenCount = await fortLever.getTokenCount();
            console.log('tokenCount=' + tokenCount);
            let l = await fortLever.list(0, tokenCount, 0);
            for (var i = 0; i < l.length; ++i) {
                let addr = l[i];
                let fot = await FortLeverToken.attach(addr);
                let ti = await fot.getLeverInfo();
                console.log({
                    name: await fot.name(),
                    tokenAddress: ti.tokenAddress.toString(),
                    price: ti.price.toString(),
                    blockNumber: ti.blockNumber.toString()
                })
            }
        }

        if (true) {
            console.log('4. buyDirect');
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lotAddress = await fortLever.getLeverToken(addrs[addr], levers[lever], oriens[orien]);
                        let lot = await FortLeverToken.attach(lotAddress);
                        let receipt = await fortLever.buyDirect(lotAddress, toBigInt(100), {
                            value: addrs[addr] == eth.address ? toBigInt(0.01) : toBigInt(0.02)
                        });
                        await showReceipt(receipt);
                        
                        console.log(toDecimal(await lot.balanceOf(owner.address)) + await lot.name() + ' ' + (await lot.getLeverInfo()).price);
                    }
                }
            }
        }

        if (true) {
            console.log('5. 将eth价格改为3000usdt');
            await nestPriceFacade.setPrice(usdt.address, '3000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lotAddress = await fortLever.getLeverToken(addrs[addr], levers[lever], oriens[orien]);
                        let lot = await FortLeverToken.attach(lotAddress);
                        await lot.update(owner.address, { value: toBigInt(0.02) });
                        console.log(toDecimal(await lot.balanceOf(owner.address)) + await lot.name() + ' ' + (await lot.getLeverInfo()).price);

                        let x = 100 * (1 + levers[lever] * (3000 - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await lot.balanceOf(owner.address)));
                        expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }
        if (true) {
            console.log('6. 将eth价格改为2000usdt');
            await nestPriceFacade.setPrice(usdt.address, '2000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lotAddress = await fortLever.getLeverToken(addrs[addr], levers[lever], oriens[orien]);
                        let lot = await FortLeverToken.attach(lotAddress);
                        await lot.update(owner.address, { value: toBigInt(0.02) });
                        console.log(toDecimal(await lot.balanceOf(owner.address)) + await lot.name() + ' ' + (await lot.getLeverInfo()).price);

                        let x = 100 * (1 + levers[lever] * (2000 - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await lot.balanceOf(owner.address)));
                        if (x < 0) {
                            x = 0;
                        }
                        expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }

        if (true) {
            console.log('7. 清算0账户');
            //await nestPriceFacade.setPrice(usdt.address, '2000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lotAddress = await fortLever.getLeverToken(addrs[addr], levers[lever], oriens[orien]);
                        let lot = await FortLeverToken.attach(lotAddress);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });

                        await fortLever.settle(lot.address, owner.address, { value: toBigInt(0.02) });
                        console.log(toDecimal(await lot.balanceOf(owner.address)) + await lot.name() + ' ' + (await lot.getLeverInfo()).price);

                        let x = 100 * (1 + levers[lever] * (2000 - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await lot.balanceOf(owner.address)));
                        if (x < 0) {
                            x = 0;
                        }
                        //expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }

        if (true) {
            console.log('8. 将eth价格回复到3510usdt');
            await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lotAddress = await fortLever.getLeverToken(addrs[addr], levers[lever], oriens[orien]);
                        let lot = await FortLeverToken.attach(lotAddress);
                        await lot.update(owner.address, { value: toBigInt(0.02) });
                        console.log(toDecimal(await lot.balanceOf(owner.address)) + await lot.name() + ' ' + (await lot.getLeverInfo()).price);

                        let x = 100 * (1 + levers[lever] * (3510 - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await lot.balanceOf(owner.address)));
                        if (x < 0) {
                            x = 0;
                        }
                        //expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }

        if (true) {
            console.log('11. sync');
            await nestPriceFacade.setPrice(usdt.address, '1000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lotAddress = await fortLever.getLeverToken(addrs[addr], levers[lever], oriens[orien]);
                        await fortLever.sync([lotAddress]);
                    }
                }
            }
        }

        if (true) {
            console.log('9. updateLeverInfo');
            await nestPriceFacade.setPrice(usdt.address, '1000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lotAddress = await fortLever.getLeverToken(addrs[addr], levers[lever], oriens[orien]);
                        let lot = await FortLeverToken.attach(lotAddress);
                        let before = await fort.balanceOf(owner.address); 
                        console.log(toDecimal(await fort.balanceOf(owner.address)) + 'fort');
                        await fortLever.updateLeverInfo([lotAddress], owner.address, {
                            value: toBigInt(0.02)
                        });
                        console.log(toDecimal(await fort.balanceOf(owner.address)) + 'fort');
                        console.log(toDecimal(await fort.balanceOf(owner.address) - before) + 'earn');
                        console.log();
                        // let x = 100 * (1 + levers[lever] * (3510 - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        // let b = parseFloat(toDecimal(await lot.balanceOf(owner.address)));
                        // if (x < 0) {
                        //     x = 0;
                        // }
                        //expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }

        if (true) {
            console.log('10. sell');
            await nestPriceFacade.setPrice(usdt.address, '1000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lotAddress = await fortLever.getLeverToken(addrs[addr], levers[lever], oriens[orien]);
                        let lot = await FortLeverToken.attach(lotAddress);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });
                        console.log(toDecimal(await lot.balanceOf(owner.address)) + await lot.name() + ' ' + (await lot.getLeverInfo()).price);
                        await fortLever.sell(lot.address, await lot.balanceOf(owner.address), { 
                            value: toBigInt(0.02)
                        });
                        console.log(toDecimal(await lot.balanceOf(owner.address)) + await lot.name() + ' ' + (await lot.getLeverInfo()).price);
                        console.log(toDecimal(await fort.balanceOf(owner.address)) + 'fort');
                        console.log();
                        // let x = 100 * (1 + levers[lever] * (3510 - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        // let b = parseFloat(toDecimal(await lot.balanceOf(owner.address)));
                        // if (x < 0) {
                        //     x = 0;
                        // }
                        //expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }

        if (true) {
            console.log('12. getKey');
            const test = async function(tokenAddress, lever, orientation) {
                let key = await fortLever._getKey(tokenAddress, lever, orientation);
                console.log(key);
            };

            await test(eth.address, 1, true);
            await test(eth.address, 2, true);
            await test(eth.address, 5, true);
            await test(eth.address, 1, false);
            await test(eth.address, 2, false);
            await test(eth.address, 5, false);
            await test(hbtc.address, 1, true);
            await test(hbtc.address, 2, true);
            await test(hbtc.address, 5, true);
            await test(hbtc.address, 1, false);
            await test(hbtc.address, 2, false);
            await test(hbtc.address, 5, false);

            await test(fort.address, 1, true);
            await test(fort.address, 2, true);
            await test(fort.address, 5, true);
            await test(fort.address, 1, false);
            await test(fort.address, 2, false);
            await test(fort.address, 5, false);
        }
    });
});
