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

        // 3.3. FortOptions升级
        // 将FortOptions合约升级为新结构，支持NEST4.3预言机，支持BTC，并兼容之前的历史数据

        // 相关信息
        // proxyAdmin: 0xB16260599777EFFB17fd2a8fD30c449e5b71C088
        // hedgeOptions: 0x284935F8C571d054Df98eDA8503ea13cde5fd8Cc
        // oldHedgeOptionImpl: 0xb11A1Dd1E64895C0133BAE48CF5cC4efdCF02421
        // eth: 0x0000000000000000000000000000000000000000
        // btc: 0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b
        // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF

        // 步骤
        // 1.	部署新FortOptions合约，记录合约地址，并在bscscan上验证合约代码
        // 2.	遍历全部期权单子，并记录，确保所有期权单子的balance小于MAX(uint112)
        // 3.	通过proxyAdmin将FortOptions的实现合约更新为新的合约地址（注意记录更新前状态以便核对）
        // 4.	向FortOptions注册eth和btc开通信息
        // 5.	遍历全部期权单子，和步骤2中的期权单子数据进行比较，结果必须一致
        // 6.	从DCU恢复FortOptions的挖矿权限
        // 7.	通知王露露检查合约参数

        // let newFortOptions = await FortOptions.deploy();
        // console.log('newFortOptions: ' + newFortOptions.address);
        // return;

        // await fortOptions.register(eth.address, {
        //     channelId: 0,
        //     pairIndex: 0,
            
        //     sigmaSQ: 45659142400n,
        //     miuLong: 64051194700n,
        //     miuShort: 0n
        // });
        // return;
        // await fortOptions.register('0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b', {
        //     channelId: 0,
        //     pairIndex: 2,
            
        //     sigmaSQ: 31708924900n,
        //     miuLong: 64051194700n,
        //     miuShort: 0n
        // });
    });
});
