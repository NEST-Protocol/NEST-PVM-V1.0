const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, fort, 
            fortEuropeanOption, fortLever, nestPriceFacade, fortGovernance,
            fortVaultForStaking
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
                addr1: await getAccountInfo(addr1),
                fortVaultForStaking: await getAccountInfo(fortVaultForStaking),
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

        const StringHelper = await ethers.getContractFactory('StringHelper');
        const sh = await StringHelper.deploy();

        let TEST_PRIVATE = false;
        if (TEST_PRIVATE) {
            console.log('1. toUpper');
            console.log(await sh.toUpper('ChenFei'));
            console.log(await sh.toUpper('chenfei'));
            console.log(await sh.toUpper('chenf'));
            console.log(await sh.toUpper(''));
            console.log(await sh.toUpper('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz'));
        }

        if (TEST_PRIVATE) {
            console.log('1. toLower');
            console.log(await sh.toLower('ChenFei'));
            console.log(await sh.toLower('chenfei'));
            console.log(await sh.toLower('chenf'));
            console.log(await sh.toLower(''));
            console.log(await sh.toLower('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz'));
        }

        if (TEST_PRIVATE) {
            console.log('1. sprintf');
            console.log('[%d=' + await sh.sprintf("%d", 123) + ']');
            console.log('[%u=' + await sh.sprintf("%u", 123) + ']');
            console.log('[%x=' + await sh.sprintf("%x", 123) + ']');
            console.log('[%f=' + await sh.sprintf("%f", 123) + ']');
            console.log('[%s=' + await sh.sprintf("%s", 123) + ']');
            console.log('[%S=' + await sh.sprintf("%S", 123) + ']');
            console.log('[%X=' + await sh.sprintf("%X", 123) + ']');

            console.log();
            console.log('[%d=' + await sh.sprintf("%d", 0) + ']');
            console.log('[%u=' + await sh.sprintf("%u", 0) + ']');
            console.log('[%x=' + await sh.sprintf("%x", 0) + ']');
            console.log('[%f=' + await sh.sprintf("%f", 0) + ']');
            console.log('[%s=' + await sh.sprintf("%s", 0) + ']');
            console.log('[%S=' + await sh.sprintf("%S", 0) + ']');
            console.log('[%X=' + await sh.sprintf("%X", 0) + ']');
        }
    });
});
