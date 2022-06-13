const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, fortOptions, fortFutures, nestPriceFacade, 
            BLOCK_TIME, USDT_DECIMALS, miuT } = await deploy();
        const TestERC20 = await ethers.getContractFactory('TestERC20');
        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

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
            let l = await fortFutures.list(0, 20, 0);
            console.log(l);
            l = await fortFutures.list(0, 20, 1);
            console.log(l);
        }

        let addrs = [hbtc.address/*, hbtc.address*/];
        let futures = [1, 2, 5];
        let oriens = [true, false];
        if (true) {
            console.log('2. getFutureCount');
            let tokenCount = await fortFutures.getFutureCount();
            console.log('tokenCount=' + tokenCount);
            let l = await fortFutures.list(0, tokenCount, 0);
            for (var i = 0; i < l.length; ++i) {
                //let addr = l[i];
                //let ti = await fot.getFutureInfo();
                let fi = l[i];
                console.log({
                    //name: await fot.name(),
                    // tokenAddress: fi.tokenAddress.toString(),
                    // price: fi.price.toString(),
                    // blockNumber: fi.blockNumber.toString()

                    index: fi.index.toString(),
                    tokenAddress: fi.tokenAddress.toString(),
                    lever: fi.lever.toString(),
                    orientation: fi.orientation.toString()
                })
            }

            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await fortFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        console.log(await lot.index);
                    }
                }
            }
        }

        if (true) {
            console.log('3. create');
            let receipt = await fortFutures.create(hbtc.address, [6], false);
            await showReceipt(receipt);
            let tokenCount = await fortFutures.getFutureCount();
            console.log('tokenCount=' + tokenCount);
            let l = await fortFutures.list(0, tokenCount, 0);
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
                    tokenAddress: fi.tokenAddress.toString(),
                    lever: fi.lever.toString(),
                    orientation: fi.orientation.toString()
                })
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
            console.log('4. buy');
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let receipt = await fortFutures.buy(addrs[addr], futures[lever], oriens[orien], toBigInt(100), {
                            value: addrs[addr] == hbtc.address ? toBigInt(0.01) : toBigInt(0.02)
                        });
                        await showReceipt(receipt);
                        let lot = await fortFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);

                        let oraclePrice = await queryPrice(addrs[addr]);
                        console.log(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');
                    }
                }
            }
        }

        //const MIU = 0.000000025367;

        if (true) {
            console.log('5. Set hbtc price to 3000usdt');
            await nestPriceFacade.setPrice(usdt.address, '3000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await fortFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });

                        let oraclePrice = await queryPrice(addrs[addr]);
                        console.log(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');
                        let bn = parseFloat(lot.baseBlock);
                        let nbn = parseFloat(await ethers.provider.getBlockNumber());
                        let x = 100 * (1 + futures[lever] * (3000 / miuT((oriens[orien]), (nbn - bn)) - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)));

                        console.log({
                            addr: addrs[addr],
                            x: x.toString(),
                            b: b.toString()
                        });
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
                        let lot = await fortFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });
                        let oraclePrice = await queryPrice(addrs[addr]);
                        console.log(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');

                        let bn = parseFloat(lot.baseBlock);
                        let nbn = parseFloat(await ethers.provider.getBlockNumber());
                        let x = 100 * (1 + futures[lever] * (2000 / miuT((oriens[orien]), (nbn - bn)) - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)));
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
                        let lot = await fortFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        let oraclePrice = await queryPrice(addrs[addr]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });

                        await fortFutures.settle(lot.index, [owner.address], { value: toBigInt(0.02) });
                        console.log(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');
                        
                        let bn = parseFloat(lot.baseBlock);
                        let nbn = parseFloat(await ethers.provider.getBlockNumber());
                        let x = 100 * (1 + futures[lever] * (2000 / miuT((oriens[orien]), (nbn - bn)) - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)));
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
                        let lot = await fortFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });
                        let oraclePrice = await queryPrice(addrs[addr]);
                        console.log(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');

                        let bn = parseFloat(lot.baseBlock);
                        let nbn = parseFloat(await ethers.provider.getBlockNumber());
                        let x = 100 * (1 + futures[lever] * (3510 / miuT((oriens[orien]), (nbn - bn)) - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)));
                        if (x < 0) {
                            x = 0;
                        }
                        //expect(Math.abs(x - b)).to.lt(0.00000001);
                    }
                }
            }
        }

        if (true) {
            console.log('9. sell');
            for(var i = 0; i < 90; ++i) {
                await usdt.transfer(owner.address, 0);
            }
            await nestPriceFacade.setPrice(usdt.address, '1000000000', 1);
            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await fortFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });
                        let oraclePrice = await queryPrice(addrs[addr]);
                        console.log(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');
                        // await fortFutures.sell(lot.index, lot.balance, { 
                        //     value: toBigInt(0.02)
                        // });
                        console.log(toDecimal(await fortFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');
                        console.log(toDecimal(await dcu.balanceOf(owner.address)) + 'dcu');
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
            console.log();
            console.log('10. find');
            console.log('count: ' + await fortFutures.getFutureCount());
            let find = await fortFutures.find(0, 3, 100, owner.address);
            for (var i = 0; i < find.length; ++i) {
                let fi = find[i];
                console.log({
                    index: fi.index.toString(),
                    tokenAddress: fi.tokenAddress.toString(),
                    lever: fi.lever.toString(),
                    orientation: fi.orientation.toString(),
                    
                    balance: fi.balance.toString(),
                    basePrice: fi.basePrice.toString(),
                    baseBlock: fi.baseBlock.toString()
                });
            }
        }
    });
});
