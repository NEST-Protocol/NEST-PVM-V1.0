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
        
        if (true) {
            console.log('1. 读取配置');
            console.log(await cfg(usdt.address));
            console.log(await cfg(eth.address));
            console.log(await cfg(hbtc.address));
        }

        if (true) {
            console.log('2. 设置配置');
            await fortEuropeanOption.setConfig(eth.address, {
                sigmaSQ: '99999999',
                miu: '88888',
                minPeriod: '77777'
            });

            await fortEuropeanOption.setConfig(hbtc.address, {
                sigmaSQ: '333333',
                miu: '22222',
                minPeriod: '1111'
            });

            console.log(await cfg(usdt.address));
            console.log(await cfg(eth.address));
            console.log(await cfg(hbtc.address));
        }

        if (true) {
            console.log('3. list1');
            console.log('tokenCount=' + await fortEuropeanOption.getTokenCount());
            let options = await fortEuropeanOption.list(0, 5, 0);
            console.log(options);

            options = await fortEuropeanOption.list(0, 5, 1);
            console.log(options);
        }

        if (true) {
            console.log('4. list2');

            console.log('tokenCount=' + await fortEuropeanOption.getTokenCount());
            await fortEuropeanOption.open(eth.address, 2450000000, true, 100000, toBigInt(1000), {
                value: toBigInt(0.01)
            });

            await fortEuropeanOption.open(hbtc.address, 52450000000, false, 100000, toBigInt(100000), {
                value: toBigInt(0.02)
            });
            console.log('tokenCount=' + await fortEuropeanOption.getTokenCount());
            let options = await fortEuropeanOption.list(0, 5, 0);
            console.log(options);

            options = await fortEuropeanOption.list(0, 5, 1);
            console.log(options);

            let fot1 = await FortOptionToken.attach(await fortEuropeanOption.getEuropeanToken(eth.address, 2450000000, true, 100000));
            let fot2 = await FortOptionToken.attach(await fortEuropeanOption.getEuropeanToken(hbtc.address, 52450000000, false, 100000));

            console.log('fot1: ' + fot1.address);
            console.log('fot2: ' + fot2.address);

            console.log('fot1-name: ' + await fot1.name());
            console.log('fot2-name: ' + await fot2.name());

            console.log('fot1-symbol: ' + await fot1.symbol());
            console.log('fot2-symbol: ' + await fot2.symbol());
        }
    });
});
