const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('36.PVM', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const PVM = await ethers.getContractFactory('PVM');
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();

        const tokens = [eth, nest];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestNFTAuction: await listBalances(nestNFTAuction, tokens)
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();
        await nest.transfer(owner.address, 100000000000000000000000000n);
        await nest.approve(nestCyberInk.address, 100000000000000000000000000n);
        await nest.approve(nestNFTAuction.address, 100000000000000000000000000n);
        
        const pvm = await PVM.deploy();

        let c = await pvm.calc('3 + (4 * 5) ');
        console.log('end');
        console.log('c=' + c.toString());
    });
});
