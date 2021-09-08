const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, fort, 
            fortEuropeanOption, fortLever, nestPriceFacade, fortGovernance,
            fortVaultForStaking, fortDAO
        } = await deploy();

        await fort.setMinter(owner.address, 1);
        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address) )+ 'fort');
        console.log('owner: ' + owner.address);

        const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
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
                fort: await getAccountInfo(fort),
                fortDAO: await getAccountInfo(fortDAO),
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
            console.log('1. update');
            await fortEuropeanOption.update(fortGovernance.address);
            await fortEuropeanOption.update(fortGovernance.address);
            await fortEuropeanOption.update(fortGovernance.address);
            await fortEuropeanOption.update(fortGovernance.address);
            await fortEuropeanOption.update(fortGovernance.address);
            await fortEuropeanOption.update(fortGovernance.address);
        }

        if (true) {
            console.log('2. setUsdtTokenAddress');
            await fortEuropeanOption.setUsdtTokenAddress(fortGovernance.address);
        }
    });
});
