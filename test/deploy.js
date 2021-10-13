const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, usdt, dcu, 
            nest,
            nhbtc,
            cofi,
            pusd,
            fortube,

            hedgeGovernance,
            hedgeOptions, hedgeFutures, hedgeVaultForStaking
        } = await deploy();

        const ERC20 = await ethers.getContractFactory('ERC20_LIB');
        
        // 1. 设置挖矿通道参数
        // @FLY @依维柯大金杯～ 第一期 4000万dcu
        // 锁仓1个月（或者2周）：nest 150万 nhbtc 50w  cofi 50w pusd 50w  peth 50w  for 50w   3000w用于nest 1年期锁仓
        // 1.锁仓时间 1个月  和  1年
        // 分配上次已经提供了
        // 这几个加起来不到4000万
        // 1年是3500
        // 那加起来3900万
        // 改成250吧

        // nest 
        // 地址：0x04abEdA201850aC0124161F037Efd70c74ddC74C
        // 锁仓时间：一月
        // 锁仓额度：2000000
        // ---
        // nest 
        // 地址：0x04abEdA201850aC0124161F037Efd70c74ddC74C
        // 锁仓时间：两年
        // 锁仓额度：36000000
        // ---
        // nhbtc 
        // 地址：0x1F832091fAf289Ed4f50FE7418cFbD2611225d46
        // 锁仓时间：一月
        // 锁仓额度：500000
        // ---
        // cofi 
        // 地址：0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1
        // 锁仓时间：一月
        // 锁仓额度：500000
        // ---
        // pusd 
        // 地址：0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0
        // 锁仓时间：一月
        // 锁仓额度：500000
        // ---
        // fortube 
        // 地址：0x1FCdcE58959f536621d76f5b7FfB955baa5A672F
        // 锁仓时间：一月
        // 锁仓额度：500000
        // 2021-10-12 11:40

        // const nest = await ERC20.attach('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
        // const nhbtc = await ERC20.attach('0x1F832091fAf289Ed4f50FE7418cFbD2611225d46');
        // const cofi = await ERC20.attach('0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1');
        // const pusd = await ERC20.attach('0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0');
        // const fortube = await ERC20.attach('0x1FCdcE58959f536621d76f5b7FfB955baa5A672F');

        return;
        const ONE_MONTH = 300;
        const ONE_YEAR = ONE_MONTH * 12;
        const TWO_YEAR = ONE_YEAR * 2;

        let xtokens = [
            nest.address,
            nhbtc.address,
            cofi.address,
            pusd.address,
            fortube.address,
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
            36000000,
        ];

        // await hedgeVaultForStaking.batchSetPoolWeight(xtokens, cycles, weights);

        // // 2. 设置挖矿启动参数
        // await hedgeVaultForStaking.setConfig(toBigInt(1), 9450600, 9451000);

        let total = 0n;
        for (var i = 0; i < xtokens.length; ++i) {
            let xi = await hedgeVaultForStaking.getChannelInfo(xtokens[i], cycles[i]);
            total += BigInt(xi.totalRewards);
        }

        console.log('total: ' + total);

        console.log(await nest.balanceOf(owner.address) + 'nest');
        console.log(await cofi.balanceOf(owner.address) + 'cofi');

        //await nest.approve(hedgeVaultForStaking.address, toBigInt(100000000));
        //await cofi.approve(hedgeVaultForStaking.address, toBigInt(100000000));
        // await hedgeVaultForStaking.stake(nest.address, ONE_MONTH, toBigInt(1000000));
        // await hedgeVaultForStaking.stake(nest.address, TWO_YEAR, toBigInt(10000000));
        // await hedgeVaultForStaking.stake(cofi.address, ONE_MONTH, toBigInt(2000000));

        console.log(await nest.balanceOf(owner.address) + 'nest');
        console.log(await cofi.balanceOf(owner.address) + 'cofi');
        // const HedgeVaultForStaking = await ethers.getContractFactory('HedgeVaultForStaking');
        // const fvfs = await HedgeVaultForStaking.deploy();
        // console.log('fvfs:' + fvfs.address);
        // //const BoxV2 = await ethers.getContractFactory("BoxV2");
        // //const upgraded = await upgrades.upgradeProxy(hedgeVaultForStaking.address, HedgeVaultForStaking);
        // //console.log(upgraded);

        // // await hedgeVaultForStaking.setConfig(1000000000000000000n, 9266520n, 9266600n);
        // // await hedgeVaultForStaking.batchSetPoolWeight(
        // //     [usdt.address, dcu.address], 
        // //     [100n, 1000n], 
        // //     [3, 7]
        // // );

        // //await usdt.transfer(owner.address, 10000000000n);
        // await usdt.approve(hedgeVaultForStaking.address, 10000000000n);
        // await hedgeVaultForStaking.stake(usdt.address, 100n, 700000000n);
        
    });
});
