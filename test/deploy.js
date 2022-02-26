const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const FortOptions = await ethers.getContractFactory('FortOptions');
        const FortFutures = await ethers.getContractFactory('FortFutures');

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

        // fortOptions: 0x741AD178C22b901dFEDAB44491534BD2C90Dc7Ed
        // newFortFutures: 0x831fE938eEEC8dd7b993aB64F5B596dEdE9513D0
        //const fortOptions = await upgrades.deployProxy(FortOptions, [hedgeGovernance.address], { initializer: 'initialize' });
        const fortOptions = await FortOptions.attach('0x741AD178C22b901dFEDAB44491534BD2C90Dc7Ed');
        console.log('fortOptions: ' + fortOptions.address);

        //const newFortFutures = await FortFutures.deploy(); //.attach('0xB31f969571e09d832E582820457d614Ca482C822');
        //console.log('newFortFutures: ' + newFortFutures.address);
        
        const hbtc = { address: '0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B' };
        console.log('8.2 create lever');
        await hedgeFutures.create(hbtc.address, 1, true);
        await hedgeFutures.create(hbtc.address, 2, true);
        await hedgeFutures.create(hbtc.address, 3, true);
        await hedgeFutures.create(hbtc.address, 4, true);
        await hedgeFutures.create(hbtc.address, 5, true);
        await hedgeFutures.create(hbtc.address, 1, false);
        await hedgeFutures.create(hbtc.address, 2, false);
        await hedgeFutures.create(hbtc.address, 3, false);
        await hedgeFutures.create(hbtc.address, 4, false);
        await hedgeFutures.create(hbtc.address, 5, false);

        return;

        let count = await hedgeOptions.getOptionCount();
        console.log(count.toString());
        const M96 = 1n << 96n;
        let list = await hedgeOptions.list(0, 298, 0);
        let clist = [];
        for (var i = 0; i < list.length; ++i) {
            clist.push(list[i]);
        }
        list = clist;
        for (var i = 0; i < list.length; ++i) {
            for (var j = i + 1; j < list.length; ++j) {
                if (BigInt(list[i].balance) > BigInt(list[j].balance)) {
                    var tmp = list[i];
                    list[i] = list[j];
                    list[j] = tmp;
                }
            }
        }

        for (var i = 0; i < list.length; ++i) {
            let o = list[i];
            let r = {
                index: o.index.toString(),
                tokenAddress: o.tokenAddress.toString(),
                strikePrice: o.strikePrice.toString(),
                orientation: o.orientation.toString(),
                exerciseBlock: o.exerciseBlock.toString(),
                balance: o.balance.toString()
            };
            if (BigInt(o.balance) >= M96) {
                console.log(r);
            }
        }

        return;

        //await nest.approve(hedgeSwap.address, toBigInt(100000000));
        //await hedgeSwap.setNestTokenAddress(nest.address);
        //await hedgeSwap.deposit(1);

        //await usdt.approve('0x4A448cBb12e449D7031f36C8122eCE6dDdf9cc84', toBigInt(10000000));
        //await usdt.transfer(owner.address, toBigInt(10000000));
        //console.log(await usdt.balanceOf(owner.address) + 'usdt');


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
        console.log('9.hedgeVaultForStaking.setConfig()');
        await hedgeVaultForStaking.setConfig(1000000000000000000n, 9500233, 9500500);
        console.log('10.hedgeVaultForStaking.batchSetPoolWeight()');
        await hedgeVaultForStaking.batchSetPoolWeight(xtokens, cycles, weights);
        }

        if (true) {
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
