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

        let whiteList = [
            '0x688f016CeDD62AD1d8dFA4aBcf3762ab29294489',
            '0xDa23cc497BE691044F2944734EDa6d4f55bC41BA',
            '0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4',
            '0x5FbDB2315678afecb367f032d93F642f64180aa3',
            '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
            '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
            '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9',
            '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
            '0x8A791620dd6260079BF849Dc5567aDC3F2FdC318',
            '0x0B306BF915C4d645ff596e518fAf3F9669b97016'
        ];

        console.log(owner.address);

        const nodes = whiteList.map(addr=>keccak256(addr));
        const merkleTree = new MerkleTree(nodes, keccak256, { sortPairs: true });
        await nestMarket.whiteListBuy(0x1007530, merkleTree.getHexProof(nodes[2]));
        
        //await nestMarket.setMerkleRoot(merkleTree.getRoot());
        // 概率        抽奖nft起始编号（16进制）                          首发nft起始编号（16进制）
        // ------------------------------------------------------------------------------------
        // 1%          16777216（0x1000000）                           16807216（0x1007530）
        // 5%          83886080（0x5000000）                           83926080（0x5009c40）
        // 10%        167772160（0xa000000）                          167822160（0xa00c350）
        // await nestCyberInk.release(nestMarket.address, [
        //     0x1007530,
        //     0x1007531,
        //     0x1007532,
        //     0x1007533,
        //     0x1007534,
        //     0x1007535,
        //     0x1007536,
        //     0x1007537,
        //     0x1007538,
        //     0x1007539,
        //     0x100753a,
        //     0x100753b,
        //     0x100753c,
        //     0x100753d,
        //     0x100753e,
        //     0x100753f
        // ]);

        // await nestCyberInk.release(nestMarket.address, [
        //     0x5009c40,
        //     0x5009c41,
        //     0x5009c42,
        //     0x5009c43,
        //     0x5009c44,
        //     0x5009c45,
        //     0x5009c46,
        //     0x5009c47,
        //     0x5009c48,
        //     0x5009c49,
        //     0x5009c4a,
        //     0x5009c4b,
        //     0x5009c4c,
        //     0x5009c4d,
        //     0x5009c4e,
        //     0x5009c4f
        // ]);

        // await nestCyberInk.release(nestMarket.address, [
        //     0xa00c350,
        //     0xa00c351,
        //     0xa00c352,
        //     0xa00c353,
        //     0xa00c354,
        //     0xa00c355,
        //     0xa00c356,
        //     0xa00c357,
        //     0xa00c358,
        //     0xa00c359,
        //     0xa00c35a,
        //     0xa00c35b,
        //     0xa00c35c,
        //     0xa00c35d,
        //     0xa00c35e,
        //     0xa00c35f
        // ]);

        // await nest.approve(nestMarket.address, 100000000000000000000000000n);
        // await nest.transfer(owner.address, 100000000000000000000000000n);

        // await nestMarket.whiteListBuy(0x1007531, merkleTree.getHexProof(nodes[5]));
        // await nestMarket.whiteListBuy(0x1007532, merkleTree.getHexProof(nodes[5]));
        // await nestMarket.whiteListBuy(0x1007533, merkleTree.getHexProof(nodes[5]));
        // await nestMarket.whiteListBuy(0x1007534, merkleTree.getHexProof(nodes[5]));
        // await nestMarket.whiteListBuy(0x1007535, merkleTree.getHexProof(nodes[5]));
        // await nestMarket.whiteListBuy(0x1007536, merkleTree.getHexProof(nodes[5]));
        // await nestMarket.whiteListBuy(0x1007537, merkleTree.getHexProof(nodes[5]));
        // await nestMarket.whiteListBuy(0x1007538, merkleTree.getHexProof(nodes[5]));
        // await nestMarket.whiteListBuy(0x1007539, merkleTree.getHexProof(nodes[5]));
        //await nestMarket.whiteListBuy(0x100753a, proof);
        //await nestMarket.whiteListBuy(0x100753b, proof);
    });
});
