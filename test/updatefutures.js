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
            nestPriceFacade, hedgeSwap
        } = await deploy();

        console.log('ok');

        // 3.4. FortFutures升级
        // 将FortOptions合约升级为新结构，支持NEST4.3预言机，支持BTC，并兼容之前的历史数据

        // 相关信息
        // proxyAdmin: 0xB16260599777EFFB17fd2a8fD30c449e5b71C088
        // hedgeFutures: 0x8c5052f7747D8Ebc2F069286416b6aE8Ad3Cc149
        // oldHedgeFuturesImpl: 0xEa1B84713C01cADfad981Bc61F617DF5Ad228596
        // eth: 0x0000000000000000000000000000000000000000
        // btc: 0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b
        // dcu: 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF

        // 步骤
        // 1.	部署新FortFutures合约，记录合约地址，并购在bscscan上验证合约代码
        // 2.	遍历全部期货单子，并记录
        // 3.	通过proxyAdmin将FortFutures的实现合约更新为新的合约地址（注意记录更新前状态以便核对）
        // 4.	向FortFutures注册eth和btc开通信息
        // 5.	遍历全部期货单子，和步骤2中的期货单子数据进行比较，结果必须一致
        // 6.	从DCU恢复FortFuturs的挖矿权限
        // 7.	通知王露露检查合约参数

        return;
        let newFortFutures = await FortFutures.deploy();
        console.log('newFortFutures: ' + newFortFutures.address);
        return;

    });
});
