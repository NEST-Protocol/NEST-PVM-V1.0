const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('35.NestNFTAuction', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
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
        // await nest.transfer(owner.address, 100000000000000000000000000n);
        // await nest.approve(nestCyberInk.address, 100000000000000000000000000n);
        // await nest.approve(nestNFTAuction.address, 100000000000000000000000000n);
        
        const TOKEN_ID = (1<<24) | 9527;
        if (false) {
            console.log('1. mint');
            await nestCyberInk.release(owner.address, [TOKEN_ID]);
            await listAccounts();
        }

        if (true) {
            console.log('2. auction');
            //await nestCyberInk.release(owner.address, [9527]);
            //await nestCyberInk.approve();
            
            await nestCyberInk.setApprovalForAll(nestNFTAuction.address, true);
            await nestNFTAuction.startAuction(TOKEN_ID, 10000000, 3601);
            await listAccounts();
        }

        if (true) {
            console.log('3. bid');
            await nestNFTAuction.bid(0, 12000000);
            await listAccounts();
        }
        if (true) {
            console.log('4. bid');
            await nestNFTAuction.bid(0, 15000000);
            await listAccounts();
        }
        if (true) {
            console.log('5. bid');
            await nestNFTAuction.bid(0, 150000000);
            await listAccounts();
        }
        if (true) {
            console.log('6. bid');
            await nestNFTAuction.bid(0, 200000000);
            await listAccounts();
        }

        if (true) {
            console.log('7. end auction');
            await nestNFTAuction.endAuction(0);
            await listAccounts();
        }

        if (false) {
            console.log('8. end auction');
            await nestNFTAuction.endAuction(0);
            await listAccounts();
        }
    });
});
