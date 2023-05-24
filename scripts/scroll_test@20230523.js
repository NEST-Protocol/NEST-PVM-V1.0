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
    const NestTrustFuturesV3 = await ethers.getContractFactory('NestTrustFuturesV3');
    const NestFutures4V3 = await ethers.getContractFactory('NestFutures4V3');
    const NestFutures4V5 = await ethers.getContractFactory('NestFutures4V5');
    const PancakeFactory = await ethers.getContractFactory('PancakeFactory');
    const PancakeRouter = await ethers.getContractFactory('PancakeRouter');

    console.log('** Deploy: scroll_test@20230523 **');
    
    // ** Deploy: scroll_test@20230523 **
    // ** Deploy: scroll_test@20230523 **
    // usdt: 0x5cbb73B367FD69807381d06BC2041BEc86d8487d
    // nest: 0x48e5c876074549cD4Bb7be0800154450b59b1eB6
    // nestGovernance: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestVault: 0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA
    // nestFutures4V5: 0xBaC502281e9C6F9c947D9b2a9b0AE828EECe4164
    // pancakeFactory: 0x73851c710953900dc8dE699A94762d21b1c941b2

    // ** Deploy: scroll_test@20230523 **
    // usdt: 0x5cbb73B367FD69807381d06BC2041BEc86d8487d
    // nest: 0x48e5c876074549cD4Bb7be0800154450b59b1eB6
    // nestGovernance: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestVault: 0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA
    // nestFutures4V5: 0xBaC502281e9C6F9c947D9b2a9b0AE828EECe4164
    // pancakeFactory: 0x73851c710953900dc8dE699A94762d21b1c941b2
    // pancakeRouter: 0xF50822767bEce47c277982d3fCFd39f0F561bf2E
    // nestUsdtPair: 0xAa44f0e4674633eFB94b91926cEABe6Be14a40FB
    // directPoster: 0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0x5cbb73B367FD69807381d06BC2041BEc86d8487d');
    console.log('usdt: ' + usdt.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x48e5c876074549cD4Bb7be0800154450b59b1eB6');
    console.log('nest: ' + nest.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestVault = await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA');
    console.log('nestVault: ' + nestVault.address);

    //const nestFutures4V5 = await upgrades.deployProxy(NestFutures4V5, [nestGovernance.address], { initializer: 'initialize' });
    const nestFutures4V5 = await NestFutures4V5.attach('0xBaC502281e9C6F9c947D9b2a9b0AE828EECe4164');
    console.log('nestFutures4V5: ' + nestFutures4V5.address);

    // -------- TEST --------
    //const pancakeFactory = await PancakeFactory.deploy('0x0000000000000000000000000000000000000000');
    const pancakeFactory = await PancakeFactory.attach('0x73851c710953900dc8dE699A94762d21b1c941b2');
    console.log('pancakeFactory: ' + pancakeFactory.address);
    
    //const pancakeRouter = await PancakeRouter.deploy(pancakeFactory.address, '0x0000000000000000000000000000000000000000');
    const pancakeRouter = await PancakeRouter.attach('0xF50822767bEce47c277982d3fCFd39f0F561bf2E');
    console.log('pancakeRouter: ' + pancakeRouter.address);
    
    //await pancakeFactory.createPair(usdt.address, nest.address);
    const nestUsdtPairAddress = await pancakeFactory.getPair(usdt.address, nest.address);
    console.log('nestUsdtPair: ' + nestUsdtPairAddress);

    // console.log('2. nestGovernance.setBuiltinAddress()');
    // await nestGovernance.setBuiltinAddress(
    //     nest.address,
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000'
    // );

    // await nestVault.approve(nestFutures4V5.address, 1000000000000000000000000n);

    // await nest.approve(nestFutures4V5.address, 1000000000000000000000000n);
    // await usdt.approve(nestFutures4V5.address, 1000000000000000000000000n);

    // await nestGovernance.registerAddress('pancake.app.router', pancakeRouter.address);
    // await nestGovernance.registerAddress('pancake.pair.nestusdt', nestUsdtPairAddress);
    // await nestGovernance.registerAddress('common.token.usdt', usdt.address);
    // await nestGovernance.registerAddress('pancake.app.router', pancakeRouter.address);
    // await nestGovernance.registerAddress('nest.app.vault', nestVault.address);
    // await nestGovernance.registerAddress('nest.app.directPoster', '0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681');
    // await nestFutures4V5.update(nestGovernance.address);

    console.log('nest: ' + await nestGovernance.getNestTokenAddress());
    console.log('nest.app.vault: ' + await nestGovernance.checkAddress("nest.app.vault"));
    console.log('nest.app.directPoster: ' + await nestGovernance.checkAddress("nest.app.directPoster"));
    console.log('pancake.pair.nestusdt: ' + await nestGovernance.checkAddress("pancake.pair.nestusdt"));
    console.log('common.token.usdt: ' + await nestGovernance.checkAddress("common.token.usdt"));

    //await usdt.transfer('0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4', 1000000000000000000000000n);
    //await nest.transfer('0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4', 1000000000000000000000000n);

    // await usdt.approve(pancakeRouter.address, 1000000000000000000000000n);
    // await nest.approve(pancakeRouter.address, 1000000000000000000000000n);

    // await pancakeRouter.addLiquidity(
    //     usdt.address,
    //     nest.address,
    //     10000000000000000000000n,
    //     500000000000000000000000n,
    //     0,
    //     0,
    //     '0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4',
    //     100000000000n
    // );
    // await usdt.approve(nestFutures4V5.address, 1000000000000000000000000n);
    // await pancakeRouter.swapExactTokensForTokens(
    //     100000000000000000000n,
    //     1000000000000000000000n,
    //     [usdt.address, nest.address],
    //     '0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4',
    //     100000000000n
    // );
    await nestFutures4V5.newBuyRequestWithUsdt(
        //uint usdtAmount,
        10000000000000000000n,
        //uint minNestAmount,
        100000000000000000000n,
        //uint channelIndex,
        0,
        //uint lever,
        1,
        //bool orientation,
        true,
        //uint basePrice,
        1230000000000000000000n,
        //bool limit,
        false,
        //uint stopProfitPrice,
        0,
        //uint stopLossPrice
        0
    );
    /*
    ** Deploy: bbsc_test@20230404.js **
    usdt: 0xDd4A68D8236247BDC159F7C5fF92717AA634cBCc
    nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    nestVault: 0x0649A02C15229Cb970CDcE456f9dd52248023520
    nestTrustFuturesV3: 0xE8b787EdE23997Ff5C64067e2220FBbd13b085A1
    nestFutures4V3: 0x35253D54A3866c21A7DdEFb82B122D75d94F5327
    nestFutures4V4: 0x476981D37FaA3bE8E8768E8E7d0d01625433126a
    pancakeFactory: 0x1D743a4a2313cf59083aFA48Aed90F815Fc073DC
    pancakeRouter: 0x7E9747Dd4a7390FCA7D86A400D14F031981Bc1E1
    nestUsdtPair: 0xF55D681c2D64310e2196E55562c402effCfe2E5E

    已经在bsc测试网部署了期货的新版本，接口和数据结构都有变化，主要接口如下：
    1. post(period, prices). 已删除

    2. execute(prices, orderIndices). 
       执行接口，删除了period参数，并且接口传入的价格只用于执行，不保存，因此对应的lastPrice()接口也已经删除
       执行时需要报价，同时需要传入需要执行的订单的索引数组，包括买入请求单，卖出请求单，限价请求单，止盈止损单，清算单，
       上述五个数组已经合并为一个数组，对于买入请求单，卖出请求单，限价请求单会根据其状态进行对应操作，
       对于状态为S_NORMAL(2)的订单，将先尝试是否符合清算条件，符合条件将被清算
       如果不能清算，则尝试是否符合止盈止损条件，符合条件将执行卖出

       增加了执行事件：
       Buy(orderIndex, amount, owner). 普通买入或者限价买入执行时触发
       Revert(orderIndex, amount, owner). 普通买入被退回时触发
       Sell(orderIndex, amount, owner, value). 卖出请求或者止盈止损单被执行时触发
       Liquidate(orderIndex, owner, reward). 订单被清算时触发，owner表示被清算账号

       上述事件中，amount 4位小数，value和reward 18位小数

       注意：
           1）不满足任何一种执行条件的订单传入后不会被执行，但是会增加额外的gas消耗
           2）将订单按照channelIndex排序可以一定程度的降低gas消耗

    3. newBuyRequest(channelIndex, lever, orientation, amount, basePrice, limit, stopProfitPrice, stopLossPrice).
       买入请求接口，可以创建普通期货单，限价单（limit为true，此时basePrice表示限价），止盈止损单（stopProfitPrice或stopLossPrice不为0）

       订单数据结构中增加了status字段表示订单状态，订单状态定义如下：
        S_CLEARED = 0x00;       被清理，卖出，止盈止损，被清算的订单都是这种状态
        S_BUY_REQUEST = 0x01;   买入请求单，用户发起普通买入请求后，尚未被执行时，处于此状态
        S_NORMAL = 0x02;        正常订单，用户的普通单或者限价单被执行后，都处于此状态
        S_SELL_REQUEST = 0x03;  卖出请求单，用户发起卖出请求后，尚未被执行时，处于此状态
        S_LIMIT_REQUEST = 0x04; 限价请求单，用户发起限价单请求后，尚未被执行时，处于此状态
        S_CANCELED = 0xFF;      已取消，买入请求单或者限价请求单尚未被执行时，可以取消，取消后将退回所有NEST

    4. newBuyRequestWithUsdt(usdtAmount, minNestAmount, channelIndex, lever, orientation, basePrice, limit, stopProfitPrice, stopLossPrice).
       用usdt发起买入
    
    5. cancelBuyRequest(orderIndex). 取消买入请求

    6. updateLimitPrice(orderIndex, limitPrice). 修改限价单限价

    7. updateStopPrice(orderIndex, stopProfitPrice, stopLossPrice). 修改止盈止损价格

    8. add(orderIndex, amount). 追加保证金

    9. newSellRequest(orderIndex). 卖出请求接口

    另外有如下修改
    1. 修改了订单数据结构，价格统一采用40位浮点表示
    2. 普通买入请求单执行时，使用执行价格（并进行了冲击成本修正）
    3. 删除了卖出请求事件
    */
    
    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        nest: nest,
        usdt: usdt,

        nestGovernance: nestGovernance,
        nestVault: nestVault,
        nestFutures4V5: nestFutures4V5,
        pancakeRouter: pancakeRouter,

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