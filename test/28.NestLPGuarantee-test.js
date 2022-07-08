const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('28.NestLPGuarantee-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, nestOptions, nestFutures, nestLPGuarantee, 
            nestPriceFacade, nestGovernance, BLOCK_TIME, USDT_DECIMALS 
        } = await deploy();

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);

        const tokens = [eth, nest];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();

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

        await nest.transfer(owner.address, 10000000000000000000000000n);

        await listAccounts();

        let x0 = 2700;
        let y0 = 1;
        let exerciseBlock = 200000;
        let miu = 0.0000000034722222;
        let sigmaSQ = 0.00021368 * 0.00021368;
        
        if (true) {
            console.log('1. open');

            await nestLPGuarantee.open(0, toBigInt(x0), exerciseBlock, {
                value: toBigInt(0.1)
            });

            await listAccounts();

            let T = (exerciseBlock - parseInt(await ethers.provider.getBlockNumber())) * 3;
            let v = (Math.exp(miu * T) - Math.exp(miu * T / 2 - sigmaSQ * T / 8) * 2 + 1) * x0;
            console.log('v=' + v);
        }
        
        await nestPriceFacade.setPrice(usdt.address, '3510000000000000000000', 1);
        if (true) {
            console.log('2. exercise');

            for (var i = 0; i < 100; ++i) {
                await nest.transfer(owner.address, 0);
            }
            await nestLPGuarantee.exercise(0, {
                value: toBigInt(0.1)
            });

            await listAccounts();

            let T = (exerciseBlock - parseInt(await ethers.provider.getBlockNumber())) * 3;
            let e = Math.sqrt(x0*y0) * (3510/Math.sqrt(x0/y0) + Math.sqrt(x0/y0) - 2 * Math.sqrt(3510));
            console.log('e=' + e);
        }
        
    });
});
