const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const HedgeOptions = await ethers.getContractFactory('HedgeOptions');
        const HedgeFutures = await ethers.getContractFactory('HedgeFutures');

        const { 
            eth, usdt, dcu, 
            cofi,
            pusd,
            peth,

            hedgeGovernance,
            hedgeOptions, hedgeFutures,
            nestPriceFacade, hedgeSwap
        } = await deploy();

        console.log('ok');

        const newHedgeOptions = await HedgeOptions.deploy();
        console.log('newHedgeOptions: ' + newHedgeOptions.address);
        
        const newHedgeFutures = await HedgeFutures.deploy();
        console.log('newHedgeFutures: ' + newHedgeFutures.address);

        return;

        //await nest.approve(hedgeSwap.address, toBigInt(100000000));
        //await hedgeSwap.setNestTokenAddress(nest.address);
        //await hedgeSwap.deposit(1);

        //await usdt.approve('0x4A448cBb12e449D7031f36C8122eCE6dDdf9cc84', toBigInt(10000000));
        await usdt.transfer(owner.address, toBigInt(10000000));
        console.log(await usdt.balanceOf(owner.address) + 'usdt');
        return;

        const ONE_MONTH = 200000;
        const ONE_YEAR = ONE_MONTH * 12;
        const TWO_YEAR = ONE_YEAR * 2;

        let xtokens = [
            nest.address,
            nhbtc.address,
            cofi.address,
            pusd.address,
            peth.address,
            nest.address
        ];

        let cycles = [
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            TWO_YEAR
        ];

        let weights = [
            2000000,
            500000,
            500000,
            500000,
            500000,
            36000000
        ];

        if (false) {
        // 2. 设置挖矿启动参数
        // 取一个好数字，锁仓准备取为 13408888 ~ 13458888
        console.log('9.hedgeVaultForStaking.setConfig()');
        await hedgeVaultForStaking.setConfig(1000000000000000000n, 9500233, 9500500);
        console.log('10.hedgeVaultForStaking.batchSetPoolWeight()');
        await hedgeVaultForStaking.batchSetPoolWeight(xtokens, cycles, weights);
        }

        if (true) {
        // 2. 设置挖矿启动参数
        // 取一个好数字，锁仓准备取为 13408888 ~ 13458888
        console.log('9.hedgeVaultForStaking.setConfig()');
        await hedgeVaultForStaking.setConfig(100000000000000000n, 9500233, 9500400 - TWO_YEAR);
        console.log('10.hedgeVaultForStaking.batchSetPoolWeight()');
        await hedgeVaultForStaking.batchSetPoolWeight([nest.address], [TWO_YEAR], [36000000]);

        console.log('11.hedgeVaultForStaking.setConfig()');
        await hedgeVaultForStaking.setConfig(100000000000000000n, 9500233, 9500400 - ONE_MONTH);
        console.log('12.hedgeVaultForStaking.batchSetPoolWeight()');
        await hedgeVaultForStaking.batchSetPoolWeight([
            nest.address,
            nhbtc.address,
            cofi.address,
            pusd.address,
            peth.address
        ], [
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH
        ], [
            2000000,
            500000,
            500000,
            500000,
            500000
        ]);

        console.log('13.hedgeVaultForStaking.setConfig()');
        await hedgeVaultForStaking.setConfig(100000000000000000n, 9500233, 9500400);
        }
        let total = 0n;
        for (var i = 0; i < xtokens.length; ++i) {
            let xi = await hedgeVaultForStaking.getChannelInfo(xtokens[i], cycles[i]);
            total += BigInt(xi.totalRewards);
            
            let token = await TestERC20.attach(xtokens[i]);
            console.log({
                name: await token.name(),
                cycle: cycles[i],
                totalRewards: xi.totalRewards.toString(),
                totalStaked: xi.totalStaked.toString(),
                unlockBlock: xi.unlockBlock.toString()
            });
        }

        console.log('total: ' + total);

        return;

        let ba = await hedgeGovernance.getBuiltinAddress();
        console.log(ba);
        expect(ba.dcuToken).to.eq(dcu.address);
        expect(ba.hedgeVaultForStaking).to.eq(hedgeVaultForStaking.address);
        expect(ba.nestPriceFacade).to.eq(nestPriceFacade.address);
        
        expect(await hedgeGovernance.getDCUTokenAddress()).to.eq(dcu.address);
        expect(await hedgeGovernance.getHedgeVaultForStakingAddress()).to.eq(hedgeVaultForStaking.address);
        expect(await hedgeGovernance.getNestPriceFacade()).to.eq(nestPriceFacade.address);

        console.log('minter1: ' + await dcu.checkMinter(owner.address));
        console.log('minter2: ' + await dcu.checkMinter(hedgeVaultForStaking.address));

        console.log(await hedgeVaultForStaking.getConfig());
    });
});
