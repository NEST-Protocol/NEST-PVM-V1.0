const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, usdt, fort, 
            fortGovernance,
            fortEuropeanOption, fortLever, fortVaultForStaking 
        } = await deploy();

        const ERC20 = await ethers.getContractFactory('ERC20_LIB');
        // 1. 设置挖矿通道参数
        // @FLY @依维柯大金杯～ 第一期 4000万fort
        // 锁仓1个月（或者2周）：nest 150万 nhbtc 50w  cofi 50w pusd 50w  peth 50w  for 50w   3000w用于nest 1年期锁仓
        // 1.锁仓时间 1个月  和  1年
        // 分配上次已经提供了
        // 这几个加起来不到4000万
        // 1年是3500
        // 那加起来3900万
        // 改成250吧
        const nest = await ERC20.attach('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
        const nhbtc = await ERC20.attach('0x1F832091fAf289Ed4f50FE7418cFbD2611225d46');
        const cofi = await ERC20.attach('0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1');
        const pusd = await ERC20.attach('0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0');
        const peth = await ERC20.attach('0x53f878Fb7Ec7B86e4F9a0CB1E9a6c89C0555FbbD');
        const fortube = await ERC20.attach('0x1FCdcE58959f536621d76f5b7FfB955baa5A672F');

        const ONE_MONTH = 200000;
        const ONE_YEAR = 2400000;

        let xtokens = [
            nest.address,
            nhbtc.address,
            cofi.address,
            pusd.address,
            peth.address,
            fortube.address,
            nest.address
        ];

        let cycles = [
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_YEAR
        ];

        let weights = [
            2500000,
            500000,
            500000,
            500000,
            500000,
            500000,
            35000000,
        ];

        await fortVaultForStaking.batchSetPoolWeight(xtokens, cycles, weights);

        // 2. 设置挖矿启动参数
        await fortVaultForStaking.setConfig(toBigInt(1), 0, 1000);

        let total = 0n;
        for (var i = 0; i < xtokens.length; ++i) {
            let xi = await fortVaultForStaking.getChannelInfo(xtokens[i], cycles[i]);
            total += BigInt(xi.totalRewards);
        }

        console.log('total: ' + total);

        // const FortVaultForStaking = await ethers.getContractFactory('FortVaultForStaking');
        // const fvfs = await FortVaultForStaking.deploy();
        // console.log('fvfs:' + fvfs.address);
        // //const BoxV2 = await ethers.getContractFactory("BoxV2");
        // //const upgraded = await upgrades.upgradeProxy(fortVaultForStaking.address, FortVaultForStaking);
        // //console.log(upgraded);

        // // await fortVaultForStaking.setConfig(1000000000000000000n, 9266520n, 9266600n);
        // // await fortVaultForStaking.batchSetPoolWeight(
        // //     [usdt.address, fort.address], 
        // //     [100n, 1000n], 
        // //     [3, 7]
        // // );

        // //await usdt.transfer(owner.address, 10000000000n);
        // await usdt.approve(fortVaultForStaking.address, 10000000000n);
        // await fortVaultForStaking.stake(usdt.address, 100n, 700000000n);
        
    });
});
