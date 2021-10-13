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
        console.log('部署完成');
        // let total = 0n;
        // for (var i = 0; i < xtokens.length; ++i) {
        //     let xi = await hedgeVaultForStaking.getChannelInfo(xtokens[i], cycles[i]);
        //     total += BigInt(xi.totalRewards);
        // }
    });
});
