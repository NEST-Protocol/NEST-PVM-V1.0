const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp, UI, FEQ } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

describe('2.NestSwitch.js', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, nest, nest_old, nestSwitch, commonGovernance, BLOCK_TIME } = await deploy();

        const tokens = [eth, nest, nest_old, usdt];
        let previous;
        let accounts;
        const listAccounts = async function(silent) {
            previous = accounts;
            accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                addr1: await listBalances(addr1, tokens),
                nestSwitch: await listBalances(nestSwitch, tokens),
            };
            if (!silent) console.log(accounts);
            return accounts;
        }

        const getCalldata = function(methodName, argumentTypes, args) {
            // let fullMethodName = 'function ' + methodName + '(' + argumentTypes.join(',') + ') external';
            // //console.log(fullMethodName);
            // const calldata0 = new ethers.utils.Interface([fullMethodName]).encodeFunctionData(methodName, args);
            // //console.log('calldata0: ' + calldata0);
            
            let method = methodName + '(' + argumentTypes.join(',') + ')';
            //console.log(method);
            const signatureData = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(method)).substring(0, 10);
            const argumentData = ethers.utils.defaultAbiCoder.encode(argumentTypes, args).substring(2);
            const calldata1 = signatureData + argumentData;
            //console.log('calldata1: ' + calldata1);
    
            return calldata1;
        };

        const NEST_BASE = 10000;
        const MIU_DECIMALS = 1e12;
        const FEE_RATE = 0.0005;
        const S_CLEARED = 0x00;
        const S_BUY_REQUEST = 0x01;
        const S_NORMAL = 0x02;
        const S_SELL_REQUEST = 0x03;
        const S_LIMIT_REQUEST = 0x04;
        const S_CANCELED = 0xFF;
        const SLIDING_POINT = 0.0002;
        const ownerNestBalance = 100000000000000000000000000n;

        await nest_old.mintTo(owner.address, toBigInt(8000));
        await nest_old.approve(nestSwitch.address, toBigInt(10000000));
        await nest.transfer(nestSwitch.address, toBigInt(100000000));

        console.log('owner: ' + owner.address);
        await listAccounts();

        if (true) {
            console.log('1. switchOld');
            await nestSwitch.switchOld(toBigInt(3700));
            await listAccounts();
        }

        let whiteList = [
            '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
            '0x2a69bb61416b9eb9582a96eaa63b758c6458a820'
        ];
        for (var i = 0; i < whiteList.length; ++i) {
            for (var j = i + 1; j < whiteList.length; ++j) {
                if (BigInt(whiteList[i]) == BigInt(whiteList[j])) {
                    console.log('i = %d, j = %d', i, j);
                }
            }
        }
        const nodes = whiteList.map(addr=>keccak256(addr));
        const merkleTree = new MerkleTree(nodes, keccak256, { sortPairs: true });
        if (true) {
            console.log('2. set merkle root');

            //console.log(merkleTree.toString());
            //await nestMarket.whiteListBuy(2562821, merkleTree.getHexProof(nodes[2]));
            //await nestSwitch.setMerkleRoot(merkleTree.getRoot());
            await commonGovernance.execute(nestSwitch.address, getCalldata('setMerkleRoot', ['bytes32'], [merkleTree.getRoot()]));

            console.log('root: ' + merkleTree.getRoot());
        }

        if (true) {
            console.log('3. withdrawNew');
            await nestSwitch.withdrawNew(merkleTree.getHexProof(nodes[0]));
            await listAccounts();
        }
    });
});
