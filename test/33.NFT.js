const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('33.NFT', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestBlindBox,
            nestNFTAuction,
            nestPriceFacade, nestBuybackPool, BLOCK_TIME, USDT_DECIMALS
        } = await deploy();

        const tokens = [eth, nest, dcu];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                nestBuybackPool: await listBalances(nestBuybackPool, tokens)
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();
        await nest.transfer(owner.address, 100000000000000000000000000n);
        await nest.approve(nestBlindBox.address, 100000000000000000000000000n);
        await nest.approve(nestNFTAuction.address, 100000000000000000000000000n);
        if (true) {
            console.log('1. mint');

            for (var i = 0; i < 100; ++i) {
                await nestBlindBox.mint();
                if (i > 0) {
                    await nestBlindBox.claim(i - 1);
                }
            }
        }

        if (true) {
            console.log('2. auction');
            await nestBlindBox.release(owner.address, [9527]);
            //await nestBlindBox.approve();
            
            await nestBlindBox.setApprovalForAll(nestNFTAuction.address, true);
            await nestNFTAuction.startAuction(nestBlindBox.address, 9527, 10000000000000000000000n, 100);

            await nestNFTAuction.bid(0, 15000000000000000000000n);

            for (var i = 0; i < 101; ++i) {
                await nest.transfer(owner.address, 0);
            }
            await nestNFTAuction.endAuction(0);
        }

        if (true) {
            console.log('3. tokenURI');
            await nestBlindBox.release(owner.address, [(3n << 64n) | 9527n]);
            await nestBlindBox.setUriFormat('{ "image": "ipfs://bafybeicb6n7ycknloyap4xwlfn6a75pp7u6j7e7skkc5aboo2whybmylsu/%u.jpg", "external_url": "https://nestprotocol.org/", "description": "NEST NFT", "name": "NEST NFT #%u" }');
            console.log('tokenURI: ' + await nestBlindBox.tokenURI((3n << 64n) | 9527n));
        }
    });
});
