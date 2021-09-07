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
            console.log("1. open"); 
            for (var i = 0; i < 10; ++i)
            {
                let receipt = await fortEuropeanOption.open(hbtc.address, 45000000000, true, 100000, toBigInt(100000), {
                    value: toBigInt(0.02)
                });
                await showReceipt(receipt);
                let fot = await FortOptionToken.attach(await fortEuropeanOption.getEuropeanToken(hbtc.address, 45000000000, true, 100000));
                console.log('fot: ' + toDecimal(await fot.balanceOf(owner.address)));
                let info = await fot.getOptionInfo();
                console.log({
                    tokenAddress: info.tokenAddress.toString(), 
                    price: info.price.toString(),
                    orientation: info.orientation.toString(),
                    endblock: info.endblock.toString()
                });

                // await fot.mint(owner.address, toBigInt(10));
                // console.log('fot: ' + toDecimal(await fot.balanceOf(owner.address)));
                // await fot.burn(owner.address, toBigInt(10));
                // console.log('fot: ' + toDecimal(await fot.balanceOf(owner.address)));
            }
        }
    });
});
