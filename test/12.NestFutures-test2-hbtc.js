const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('12.NestFutures-test2-hbtc', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, nest, nestOptions, nestFutures, nestPriceFacade, 
            BLOCK_TIME, USDT_DECIMALS, miuT } = await deploy();
        const TestERC20 = await ethers.getContractFactory('TestERC20');

        await nest.transfer(owner.address, 10000000000000000000000000n);
        
        const tokens = [eth, nest];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                addr1: await listBalances(addr1, tokens),
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const cfg = async function(tokenAddress) {
            let c = await nestOptions.getConfig(tokenAddress);
            return {
                sigmaSQ: c.sigmaSQ.toString(),
                miu: c.miu.toString(),
                minPeriod: c.minPeriod.toString()
            }
        }
        
        const align = function(price) {
            // let decimals = 0;
            // while (price >= 10000000) {
            //     price = Math.floor(price / 10);
            //     ++decimals;
            // }
            // return price * 10 ** decimals;
            return price;
        }

        if (true) {
            console.log('1. list');
            let l = await nestFutures.list(0, 20, 0);
            console.log(l);
            l = await nestFutures.list(0, 20, 1);
            console.log(l);
        }

        let addrs = [hbtc.address/*, hbtc.address*/];
        let futures = [2, 3, 5];
        let oriens = [true, false];
        if (true) {
            console.log('2. getFutureCount');
            let tokenCount = await nestFutures.getFutureCount();
            console.log('tokenCount=' + tokenCount);
            let l = await nestFutures.list(0, tokenCount, 0);
            for (var i = 0; i < l.length; ++i) {
                // let addr = l[i];
                // let ti = await fot.getFutureInfo();
                // console.log({
                //     name: await fot.name(),
                //     tokenAddress: ti.tokenAddress.toString(),
                //     price: ti.price.toString(),
                //     blockNumber: ti.blockNumber.toString()
                // })
                let fi = l[i];
                console.log({
                    index: fi.index.toString(),
                    tokenAddress: fi.tokenAddress,
                    lever: fi.lever.toString(),
                    orientation: fi.orientation
                });
            }

            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let fi = await nestFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        console.log({
                            index: fi.index.toString(),
                            tokenAddress: fi.tokenAddress,
                            lever: fi.lever.toString(),
                            orientation: fi.orientation
                        });
                    }
                }
            }
        }

        if (true) {
            console.log('3. create');
            let receipt = await nestFutures.create(hbtc.address, [6], false);
            await showReceipt(receipt);
            let tokenCount = await nestFutures.getFutureCount();
            console.log('tokenCount=' + tokenCount);
            let l = await nestFutures.list(0, tokenCount, 0);
            for (var i = 0; i < l.length; ++i) {
                let fi = l[i];
                console.log({
                    index: fi.index.toString(),
                    tokenAddress: fi.tokenAddress,
                    lever: fi.lever.toString(),
                    orientation: fi.orientation
                });
            }
        }

        const queryPrice = async function(tokenAddress) {
            let tokenAmount = 1e18;
            let usdtAmount = (await nestPriceFacade.latestPriceView(usdt.address)).price;
            let decimals = 18;
            if (tokenAddress != hbtc.address) {
                decimals = await (await TestERC20.attach(tokenAddress)).decimals();
                tokenAmount = (await nestPriceFacade.latestPriceView(tokenAddress)).price;
            }
            
            return Math.floor(usdtAmount * 10 ** decimals / tokenAmount);
        };

        if (true) {
            console.log('4. buyDirect');
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await nestFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        let receipt = await nestFutures.buyDirect(lot.index, toBigInt(100), {
                            value: addrs[addr] == hbtc.address ? toBigInt(0.01) : toBigInt(0.02)
                        });
                        await showReceipt(receipt);
                        
                        let oraclePrice = queryPrice(addrs[addr]);
                        console.log(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');
                    }
                }
            }
        }

        //const MIU = 0.000000025367;

        if (true) {
            console.log('5. Set hbtc pricve to 3000usdt');
            await nestPriceFacade.setPrice(usdt.address, '3000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await nestFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });
                        let oraclePrice = queryPrice(addrs[addr]);
                        console.log(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');

                        let bn = parseFloat(lot.baseBlock);
                        let nbn = parseFloat(await ethers.provider.getBlockNumber());
                        let x = 100 * (1 + futures[lever] * (3000 / miuT((oriens[orien]), (nbn - bn)) - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)));
                        expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }
        if (true) {
            console.log('6. Set hbtc price to 2000usdt');
            await nestPriceFacade.setPrice(usdt.address, '2000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await nestFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });
                        let oraclePrice = queryPrice(addrs[addr]);
                        console.log(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');

                        let bn = parseFloat(lot.baseBlock);
                        let nbn = parseFloat(await ethers.provider.getBlockNumber());
                        let x = 100 * (1 + futures[lever] * (2000 / miuT((oriens[orien]), (nbn - bn)) - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)));
                        if (x < 0) {
                            x = 0;
                        }
                        expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }

        if (true) {
            console.log('7. Settle');
            //await nestPriceFacade.setPrice(usdt.address, '2000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await nestFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });

                        await nestFutures.settle(lot.index, [owner.address], { value: toBigInt(0.02) });
                        let oraclePrice = queryPrice(addrs[addr]);
                        console.log(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');

                        let bn = parseFloat(lot.baseBlock);
                        let nbn = parseFloat(await ethers.provider.getBlockNumber());
                        let x = 100 * (1 + futures[lever] * (2000 / miuT((oriens[orien]), (nbn - bn)) - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)));
                        if (x < 0) {
                            x = 0;
                        }
                        //expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }

        if (true) {
            console.log('8. Set hbtc price to 3510usdt');
            await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await nestFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        // await lot.update(owner.address, { value: toBigInt(0.02) });
                        let oraclePrice = queryPrice(addrs[addr]);
                        console.log(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');

                        let bn = parseFloat(lot.baseBlock);
                        let nbn = parseFloat(await ethers.provider.getBlockNumber());
                        let x = 100 * (1 + futures[lever] * (3510 / miuT((oriens[orien]), (nbn - bn)) - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)));
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
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        // let lotAddress = await nestFutures.getLeverToken(addrs[addr], futures[lever], oriens[orien]);
                        // await nestFutures.sync([lotAddress]);
                    }
                }
            }
        }

        if (true) {
            console.log('9. updateLeverInfo');
            await nestPriceFacade.setPrice(usdt.address, '1000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await nestFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        let before = await nest.balanceOf(owner.address); 
                        console.log(toDecimal(await nest.balanceOf(owner.address)) + 'nest');
                        // await nestFutures.updateLeverInfo([lotAddress], owner.address, {
                        //     value: toBigInt(0.02)
                        // });
                        console.log(toDecimal(await nest.balanceOf(owner.address)) + 'nest');
                        console.log(toDecimal(await nest.balanceOf(owner.address) - before) + 'earn');
                        console.log();
                        // let x = 100 * (1 + futures[lever] * (3510 - 3510) / 3510 * (oriens[orien] ? 1 : -1));
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
            for(var i = 0; i < 90; ++i) {
                await usdt.transfer(owner.address, 0);
            }
            await nestPriceFacade.setPrice(usdt.address, '1000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await nestFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });
                        let oraclePrice = queryPrice(addrs[addr]);
                        console.log(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');
                        await nestFutures.sell(lot.index, lot.balance, { 
                            value: toBigInt(0.02)
                        });
                        console.log(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');
                        console.log(toDecimal(await nest.balanceOf(owner.address)) + 'nest');
                        console.log();
                        // let x = 100 * (1 + futures[lever] * (3510 - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        // let b = parseFloat(toDecimal(await lot.balanceOf(owner.address)));
                        // if (x < 0) {
                        //     x = 0;
                        // }
                        //expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }

        if (false) {
            console.log('12. getKey');
            const test = async function(tokenAddress, lever, orientation) {
                let key = await nestFutures._getKey(tokenAddress, lever, orientation);
                console.log(key);
            };

            await test(hbtc.address, 1, true);
            await test(hbtc.address, 2, true);
            await test(hbtc.address, 5, true);
            await test(hbtc.address, 1, false);
            await test(hbtc.address, 2, false);
            await test(hbtc.address, 5, false);
            await test(hbtc.address, 1, true);
            await test(hbtc.address, 2, true);
            await test(hbtc.address, 5, true);
            await test(hbtc.address, 1, false);
            await test(hbtc.address, 2, false);
            await test(hbtc.address, 5, false);

            await test(nest.address, 1, true);
            await test(nest.address, 2, true);
            await test(nest.address, 5, true);
            await test(nest.address, 1, false);
            await test(nest.address, 2, false);
            await test(nest.address, 5, false);
        }
    });
});
