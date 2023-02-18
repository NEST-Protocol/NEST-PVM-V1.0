// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestVault = await ethers.getContractFactory('NestVault');
    const NestTrustFutures = await ethers.getContractFactory('NestTrustFutures');

    console.log('** Deploy: bsc_test@20230218.js **');
    
    // ** Deploy: bsc_test@20230218.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestTrustFutures: 0x44224345b8CD7Cd3e54FAB464857A6122a0850Cf
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x5691dc0770D55B9469a3242DA282754687687935');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestVault = await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0x0649A02C15229Cb970CDcE456f9dd52248023520');
    console.log('nestVault: ' + nestVault.address);

    //const nestTrustFutures = await upgrades.deployProxy(NestTrustFutures, [nestGovernance.address], { initializer: 'initialize' });
    const nestTrustFutures = await NestTrustFutures.attach('0x44224345b8CD7Cd3e54FAB464857A6122a0850Cf');
    console.log('nestTrustFutures: ' + nestTrustFutures.address);

    // await nestGovernance.registerAddress('nest.app.vault', nestVault.address);
    // await nestGovernance.registerAddress('nest.app.futures', nestTrustFutures.address);
    // await nestGovernance.registerAddress('nest.app.directPoster', (await ethers.getSigners())[0].address)
    // await nestGovernance.registerAddress('nest.app.maintains', (await ethers.getSigners())[0].address);

    // console.log('1. nestTrustFutures.update()');
    // await nestTrustFutures.update(nestGovernance.address);

    // await nestTrustFutures.openChannel(0);
    // await nestTrustFutures.openChannel(1);
    // await nestTrustFutures.openChannel(2);

    // await nestVault.approve(nestTrustFutures.address, 100000000000000000000000000n);
    // await nest.approve(nestTrustFutures.address, 100000000000000000000000000n);

    /*
    // ** Deploy: bsc_test@20230218.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    // nestTrustFutures: 0x44224345b8CD7Cd3e54FAB464857A6122a0850Cf
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

    已经在bsc测试网上部署了期货合约，采用了新的动态μ算法，并合并代理合约功能，接口有对应变化，详情如下：
    1. buy(), add(), sell(), liquidate()分别对应期货买入，追加，卖出，清算
    2. post()接口用于直接报价，价格是一个定长为3的数组，分别对应eth, btc, bnb的价格，价格不再是相对于2000USD的价格，
       而是直接价格，例如eth:1700e18, btc: 25000e18, bnb: 300e18
    3. 删除了原来的tokenIndex和pairIndex概念，引入channelIndex概念，分别对应(eth:0, btc:1, bnb:2)
    4. newTrustOrder(), updateLimitPrice(), updateStopPrice(), newStopOrder(), cancelLimitOrder()分别对应
       创建限价单（包括止盈止损），更新限价，更新止盈止损价，给已生效期货单创建止盈止损单，取消限价单（包括止盈止损）
    5. executeLimitOrder(), executeStopOrder()分别对应执行限价单，执行止盈止损单
    详情见INestFutures3和INestTrustFutures接口
    
    注意事项：
    1. 价格是18位无符号整数，是直接价格，不再是相对于2000USD的的价格（例如eth:1700e18, btc: 25000e18, bnb: 300e18）
    2. 合约不再保存历史价格，每次报价是更新一个最后价格，历史价格需要后端存储
    3. 限价单的实现方式是在创建限价单的时候创建一个余额为0的期货单来实现的，因此创建限价单就可以查到对应的期货单
    4. 止盈止损单不再在期货单中实现，需要后台关联期货单的止盈止损单
    5. 通过newStopOrder()可以给一个期货单多次创建止盈止损单，任何一个止盈止损单满足执行条件都会执行对应的期货单，需要在前端限制不要重复创建
    6. 追加接口add()逻辑与之前的追加不同，其在计算剩余保证金的时候算法不同，影响卖出和清算接口，具体算法见期货最新文档
    7. 清算线有变化，详情见新期货文档
    8. 后面再更新合约后，清算时，会将被清算订单的所有字段清为0，后台需要对应处理（本次测试合约暂时只将balance和appends设置为0）
    9. list()和find()接口返回的订单信息中，增加了一个Pt字段，是一个有符号整形，12位小数，用于计算μT，μT详见新期货文档
    10. 下次将更新老的期货合约，删除了买入，追加接口，价格链接到新期货中，请各位在更新前在老合约中下几个单，方便更新后测试
    */
    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        nest: nest,

        nestGovernance: nestGovernance,
        nestVault: nestVault,
        nestTrustFutures: nestTrustFutures,

        BLOCK_TIME: BLOCK_TIME,
        USDT_DECIMALS: 18,

        MIU_LONG: MIU_LONG,
        MIU_SHORT: MIU_SHORT,
        miuT: function(orientation, blocks) {
            return Math.exp((orientation ? MIU_LONG : MIU_SHORT) * blocks * BLOCK_TIME);
        }
    };

    return contracts;
};