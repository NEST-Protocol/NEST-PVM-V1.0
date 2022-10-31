const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('33.NFT', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, nest, dcu, nestOptions, nestFutures, nestLPGuarantee, nestProbability, nestCyberInk,
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

        //await listAccounts();
        //await nest.transfer(owner.address, 100000000000000000000000000n);
        // await nest.approve(nestCyberInk.address, 100000000000000000000000000n);
        // await nest.approve(nestNFTAuction.address, 100000000000000000000000000n);
        if (true) {
            console.log('1. mint');
            for (var i = 0; i < 100; ++i) {
                await nestCyberInk.mint();
                if (i > 0) {
                    await nestCyberInk.claim(i - 1);
                    console.log({
                        total: (await nestCyberInk.totalSupply(0)).toString(),
                        nft1: (await nestCyberInk.totalSupply(1)).toString(),
                        nft2: (await nestCyberInk.totalSupply(2)).toString(),
                        nft3: (await nestCyberInk.totalSupply(3)).toString(),
                    });
                }
            }
        }

        if (true) {
            console.log('2. auction');
            await nestCyberInk.release(owner.address, [9527]);
            //await nestCyberInk.approve();
            
            await nestCyberInk.setApprovalForAll(nestNFTAuction.address, true);
            await nestNFTAuction.startAuction(9527, 100000000n, 3601);

            await nestNFTAuction.bid(0, 150000000n);

            for (var i = 0; i < 101; ++i) {
                await nest.transfer(owner.address, 0);
            }
            await nestNFTAuction.endAuction(0);
        }

        if (true) {
            console.log('3. tokenURI');
            await nestCyberInk.release(owner.address, [(3n << 64n) | 9527n]);
            await nestCyberInk.setUriFormat('{ "image": "ipfs://bafybeicb6n7ycknloyap4xwlfn6a75pp7u6j7e7skkc5aboo2whybmylsu/%u.jpg", "external_url": "https://nestprotocol.org/", "description": "NEST NFT", "name": "NEST NFT #%u" }');
            console.log('tokenURI: ' + await nestCyberInk.tokenURI((3n << 64n) | 9527n));
        }
    });
});
