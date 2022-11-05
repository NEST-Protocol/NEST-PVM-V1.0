const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

describe('deploy', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, usdt, nest, 
            cofi,
            pusd,
            peth,
            nestPRCSwap,

            nestCyberInk, nestNFTAuction,
            nestFuturesWithPrice, nestMarket,

            nestGovernance,
            nestOptions, nestFutures,
            nestPriceFacade
        } = await deploy();

        console.log('ok');
        // Release to element address
        console.log('Release to element, 150|75|15');
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 0  ) << 8) | 0x0a, 256, 150);
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 0  ) << 8) | 0x05, 256, 75);
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 0  ) << 8) | 0x01, 256, 15);

        // Release to pearDAO address
        console.log('Release to pearDAO, 150|75|15');
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 150) << 8) | 0x0a, 256, 150);
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 75 ) << 8) | 0x05, 256, 75);
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 15 ) << 8) | 0x01, 256, 15);

        // Release to nestMarket address
        console.log('Release to nestMarket, 500|250|50');
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 300) << 8) | 0x0a, 256, 250);
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 550) << 8) | 0x0a, 256, 250);
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 150) << 8) | 0x05, 256, 250);
        await nestCyberInk.release('0x0000000000000000000000000000000000000001', ((10000 + 30 ) << 8) | 0x01, 256, 50);
        
		return;
        //await nestCyberInk.release(nestMarket.address, 2560001, 256, 16);
        //await nestCyberInk.release(nestMarket.address, 2560005, 256, 16);
        //await nestCyberInk.release(nestMarket.address, 2560010, 256, 16);
        
        let whiteList = [
            '0x688f016CeDD62AD1d8dFA4aBcf3762ab29294489',
            '0xDa23cc497BE691044F2944734EDa6d4f55bC41BA',
            '0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4',
            '0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681',
            '0xa0c5832EAB3363159dB8baC849473FBCfd454686',
            '0x871e642fB0047DC6CE7E79297f07C3ee02D81fC0',
            '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
            '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9',
            '0x8A791620dd6260079BF849Dc5567aDC3F2FdC318',
            '0x0B306BF915C4d645ff596e518fAf3F9669b97016'
        ];

        const nodes = whiteList.map(addr=>keccak256(addr));
        const merkleTree = new MerkleTree(nodes, keccak256, { sortPairs: true });
        await nestMarket.whiteListBuy(2562821, merkleTree.getHexProof(nodes[2]));

        // await nestMarket.setMerkleRoot(merkleTree.getRoot());
        // await nest.approve(nestMarket.address, 100000000000000000000000000n);
        // await nest.transfer(owner.address, 100000000000000000000000000n);
        
        // 概率        抽奖nft起始编号（16进制）                          首发nft起始编号（16进制）
        // ------------------------------------------------------------------------------------
        // 1%          16777216（0x1000000）                           16807216（0x1007530）
        // 5%          83886080（0x5000000）                           83926080（0x5009c40）
        // 10%        167772160（0xa000000）                          167822160（0xa00c350）
        // await nestCyberInk.release(nestMarket.address, 0x1007530, 1, 16);
        // await nestCyberInk.release(nestMarket.address, 0x5009c40, 1, 16);
        // await nestCyberInk.release(nestMarket.address, 0xa00c350, 1, 16);

        
        // const h = keccak256('0x52f57297d97a84de7bdf53a239d5f1c446e6ff8e4e0d175868a241ddff7729d8a3571888cfbca68776ab582afabed39268990974a4835e694b767474e2d63a4d');
        // console.log(h);

        // const pf = merkleTree.getHexProof(nodes[5]);
        // for (var i = 0; i < pf.length; ++i) {
        //     console.log(pf[i]);
        // }
        // console.log(nodes[5]);
    });
});
