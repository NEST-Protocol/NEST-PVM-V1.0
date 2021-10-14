const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const TestERC20 = await ethers.getContractFactory('TestERC20');

        const { 
            eth, usdt, dcu, 
            nest,
            nhbtc,
            cofi,
            pusd,
            fortube,
            peth,

            hedgeGovernance,
            hedgeOptions, hedgeFutures, hedgeVaultForStaking,
            nestPriceFacade
        } = await deploy();

        console.log('部署完成');

        const ONE_MONTH = 200000;
        const ONE_YEAR = ONE_MONTH * 12;
        const TWO_YEAR = ONE_YEAR * 2;

        let xtokens = [
            nest.address,
            nhbtc.address,
            cofi.address,
            pusd.address,
            fortube.address,
            nest.address,
            peth.address
        ];

        let cycles = [
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            ONE_MONTH,
            TWO_YEAR,
            ONE_MONTH
        ];

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
