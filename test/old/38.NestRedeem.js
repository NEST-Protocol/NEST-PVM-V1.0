const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('38.NestRedeem', function() {
    it('First', async function() {
        const NestRedeem = await ethers.getContractFactory('NestRedeem');
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
            nestNFTAuction, nestFuturesWithPrice, nestVault, nestGovernance,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();
        const nestRedeem = await NestRedeem.deploy(dcu.address, nest.address, toBigInt(0.5));
        await nestRedeem.initialize(nestGovernance.address);

        const tokens = [eth, nest, dcu];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestRedeem: await listBalances(nestRedeem, tokens),
                addr2: await listBalances(addr2, tokens)
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();
        await nest.transfer(owner.address, 100000000000000000000000000n);

        if (true) {
            console.log('1. redeem');
            await nest.transfer(nestRedeem.address, toBigInt(10000));
            await dcu.transfer(owner.address, toBigInt(10000));
            await dcu.approve(nestRedeem.address, toBigInt(100000));
            await listAccounts();
            await nestRedeem.redeem(toBigInt(7));
            console.log('2. after redeem');
            await listAccounts();
        }

        if (true) {
            console.log('3. migrate');
            await nestGovernance.setBuiltinAddress(
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                addr2.address,
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000',
                '0x0000000000000000000000000000000000000000'
            );
            await nestRedeem.migrate(nest.address, 9996500000000000000000n);
            await nestRedeem.migrate(dcu.address, 7000000000000000000n);
            await listAccounts();
        }
    });
});
