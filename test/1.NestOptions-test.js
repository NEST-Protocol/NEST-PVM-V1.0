const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, listBalances, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('1.NestOptions-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, nest, nestOptions, nestFutures, nestPriceFacade, 
            BLOCK_TIME, USDT_DECIMALS, MIU_LONG, MIU_SHORT } = await deploy();
        const USDT_BASE = BigInt(10 ** USDT_DECIMALS);

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

        await nestPriceFacade.setPrice(usdt.address, toBigInt(3510, USDT_DECIMALS), 1);
        const BLOCK = 100000;
        await nestOptions.open(eth.address, toBigInt(2450, USDT_DECIMALS), true, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        
        let fot = { index: 0 };
        console.log('owner: ' + toDecimal(await nest.balanceOf(owner.address)) + 'nest');
        console.log('owner: ' + toDecimal(await nestOptions.balanceOf(fot.index, owner.address)) + '(fot)');
        let v;
        {
            let S0 = 3510;
            let K = 2450;
            // 45659142400n
            let sigma = 0.00021368; //Math.sqrt(4168125400/1e18);
            //let miu = 0.000000025367;
            let T = (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME;

            let vc = Vc(S0, K, sigma, MIU_LONG, T);
            let vp = Vp(S0, K, sigma, MIU_SHORT, T);
            console.log('vc=' + vc);
            //console.log('vp=' + vp);
            console.log('FOT=' + 1000 / vc);
            expect(Math.abs(1000 / vc - (await nestOptions.balanceOf(fot.index, owner.address))/1e18)).to.lt(1e-5);
            console.log('gained=' + 1000 / vc * (3510 - 2450));
            v = 1000 / vc * (3510 - 2450) + (await nest.balanceOf(owner.address)) / 1e18;
        }

        await nestOptions.exercise(fot.index, await nestOptions.balanceOf(fot.index, owner.address), {
            value: toBigInt(0.01)
        });
        console.log('owner: ' + toDecimal(await nest.balanceOf(owner.address)) + 'nest');
        console.log('owner: ' + toDecimal(await nestOptions.balanceOf(fot.index, owner.address)) + '(fot)');
        expect(Math.abs(v - (await nest.balanceOf(owner.address)) / 1e18)).to.lt(1e-4);
        console.log();
    });
});
