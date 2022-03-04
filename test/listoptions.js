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
            eth, usdt, dcu, hbtc,
            cofi,
            pusd,
            peth,

            hedgeGovernance,
            hedgeOptions, hedgeFutures,
            fortOptions, fortFutures,
            nestPriceFacade, hedgeSwap
        } = await deploy();

        console.log('ok');

        const M112 = 1n << 96n;
        const Zero = 0n;
        {
            console.log('hedgeOptions: ' + hedgeOptions.address);
            let count = await hedgeOptions.getOptionCount();
            console.log('count: ' + count);

            let options = await hedgeOptions.list(0, count, 1);
            for (var i = 0; i < options.length; ++i) {
                let o = options[i];
                let b = BigInt(o.balance);
                if (b >= 1n) {
                    let option = {
                        index: o.index.toString(),
                        tokenAddress: o.tokenAddress.toString(),
                        strikePrice: o.strikePrice.toString(),
                        orientation: o.orientation.toString(),
                        exerciseBlock: o.exerciseBlock.toString(),
                        balance: o.balance.toString()
                    };
                    console.log(option);
                }
            }

            console.log('end');
        }
    });
});
