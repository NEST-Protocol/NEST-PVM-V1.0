const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('10.NestOptions-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, nest, nestOptions, nestFutures, nestPriceFacade, USDT_DECIMALS } = await deploy();

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
            let decimals = 0;
            while (price >= 10000000) {
                price = Math.floor(price / 10);
                ++decimals;
            }
            return price * 10 ** decimals;
        }

        if (false) {
            console.log("1. open"); 
            for (var i = 0; i < 10; ++i)
            {
                let receipt = await nestOptions.open(hbtc.address, 45000000000, true, 100000, toBigInt(100000), {
                    value: toBigInt(0.02)
                });
                await showReceipt(receipt);
                let fot = await nestOptions.getOptionInfo(hbtc.address, 45000000000, true, 100000);
                console.log('fot: ' + toDecimal(await nestOptions.balanceOf(fot.index, owner.address)));
                let info = await nestOptions.getOptionInfo(hbtc.address, 45000000000, true, 100000);
                console.log({
                    tokenAddress: info.tokenAddress.toString(), 
                    strikePrice: info.strikePrice.toString(),
                    orientation: info.orientation.toString(),
                    exerciseBlock: info.exerciseBlock.toString()
                });

                // await fot.mint(owner.address, toBigInt(10));
                // console.log('fot: ' + toDecimal(await fot.balanceOf(owner.address)));
                // await fot.burn(owner.address, toBigInt(10));
                // console.log('fot: ' + toDecimal(await fot.balanceOf(owner.address)));
            }
        }
    });
});
