const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('23.NestFutures-settle', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, nest, nestOptions, nestFutures, nestPriceFacade, BLOCK_TIME, USDT_DECIMALS } = await deploy();
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

        const MIU = 0.000000025367;
        const queryPrice = async function(tokenAddress) {
            let tokenAmount = 1e18;
            let usdtAmount = (await nestPriceFacade.latestPriceView(usdt.address)).price;
            let decimals = 18;
            if (tokenAddress != eth.address) {
                decimals = await (await TestERC20.attach(tokenAddress)).decimals();
                tokenAmount = (await nestPriceFacade.latestPriceView(tokenAddress)).price;
            }
            
            return Math.floor(usdtAmount * 10 ** decimals / tokenAmount);
        };

        if (true) {
            console.log('1. Buy long future');
            //await nestPriceFacade.setPrice(usdt.address, '3000000000', 1);
            await nestFutures.buy(eth.address, 5, true, toBigInt(10000), {
                value: toBigInt(0.01)
            });
            await nestFutures.buy(eth.address, 5, false, toBigInt(10000), {
                value: toBigInt(0.01)
            });
            await usdt.transfer(owner.address, 0);

            let l1 = await nestFutures.getFutureInfo(eth.address, 5, true);
            let l2 = await nestFutures.getFutureInfo(eth.address, 5, false);
            let bn1 = parseFloat(l1.baseBlock);
            let bn2 = parseFloat(l2.baseBlock);
            let nbn = parseFloat(await ethers.provider.getBlockNumber());
            // let oraclePrice = await queryPrice(eth.address);
            // console.log('balance1: ' + toDecimal(await nestFutures.balanceOf(l1.index, parseInt(oraclePrice / Math.exp(MIU * (nbn - bn1) * BLOCK_TIME)), owner.address)));
            // console.log('balance2: ' + toDecimal(await nestFutures.balanceOf(l2.index, parseInt(oraclePrice / Math.exp(MIU * (nbn - bn2) * BLOCK_TIME)), owner.address)));

            let balance1 = async function() {
                let nbn = parseFloat(await ethers.provider.getBlockNumber());
                let oraclePrice = await queryPrice(eth.address);
                return toDecimal(await nestFutures.balanceOf(l1.index, parseInt(oraclePrice / Math.exp(MIU * (nbn - bn1) * BLOCK_TIME)), owner.address));
            };
            
            let balance2 = async function() {
                let nbn = parseFloat(await ethers.provider.getBlockNumber());
                let oraclePrice = await queryPrice(eth.address);
                return toDecimal(await nestFutures.balanceOf(l2.index, parseInt(oraclePrice / Math.exp(MIU * (nbn - bn2) * BLOCK_TIME)), owner.address));
            };
            console.log('balance1: ' + await balance1());            
            console.log('balance2: ' + await balance2());
            console.log();

            await nestPriceFacade.setPrice(usdt.address, '4150000000', 1);
            
            console.log('balance1: ' + await balance1());            
            console.log('balance2: ' + await balance2());
            console.log();

            await nestFutures.settle(l1.index, [owner.address], { value: toBigInt(0.01) });
            await nestFutures.settle(l2.index, [owner.address], { value: toBigInt(0.01) });

            console.log('balance1: ' + await balance1());            
            console.log('balance2: ' + await balance2());
            
            return;

            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < futures.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let lot = await nestFutures.getFutureInfo(addrs[addr], futures[lever], oriens[orien]);
                        //await lot.update(owner.address, { value: toBigInt(0.02) });

                        let oraclePrice = await queryPrice(addrs[addr]);
                        console.log(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '[' + lot.index + ']');
                        let bn = parseFloat(lot.baseBlock);
                        let nbn = parseFloat(await ethers.provider.getBlockNumber());
                        let x = 100 * (1 + futures[lever] * (3000 / Math.exp(MIU * (nbn - bn) * BLOCK_TIME) - 3510) / 3510 * (oriens[orien] ? 1 : -1));
                        let b = parseFloat(toDecimal(await nestFutures.balanceOf(lot.index, oraclePrice, owner.address)));

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
    });
});
