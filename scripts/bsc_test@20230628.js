// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const CommonProxy = await ethers.getContractFactory('CommonProxy');
    const CommonGovernance = await ethers.getContractFactory('CommonGovernance');
    const NestCraftSimple = await ethers.getContractFactory('NestCraftSimple');

    console.log('** Deploy: bsc_test@20230628.js **');
    
    // ** Deploy: bsc_test@20230628.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // commonGovernance: 0xb75947547dD02318692A0127e9c3f80F2c35ed0d
    // nestFuturesWithPrice: 0xA2D58989ef9981065f749C217984DB21970fF0b7
    // nestCraft: 0x1F51245Ec0cb1D40E4F27373FD180B6157DA44Cd
    // proxyAdmin: 0x43D2c8141E792D391A64F7140E708Ba05962C71A

    // ** Deploy: bsc_test@20230628.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // commonGovernance: 0xb75947547dD02318692A0127e9c3f80F2c35ed0d
    // nestCraftSimple: 0x06F86C308123e029ab80aCA18862Acfab52C47D8

    const deployProxy = async function(artifact, args) {
        const target = await artifact.deploy(args);
        const proxy = await CommonProxy.deploy(target.address);
        return artifact.attach(proxy.address);
    };

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

    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);

    //const commonGovernance = await CommonGovernance.deploy();
    const commonGovernance = await CommonGovernance.attach('0xb75947547dD02318692A0127e9c3f80F2c35ed0d');
    console.log('commonGovernance: ' + commonGovernance.address);

    //const nestCraft = await deployProxy(NestCraftSimple, []);
    const nestCraft = await NestCraftSimple.attach('0x06F86C308123e029ab80aCA18862Acfab52C47D8');
    console.log('nestCraft: ' + nestCraft.address);

    //await nest.approve(nestCraft.address, 1000000000000000000000000n);

    //await commonGovernance.registerAddress('nest.app.nest', nest.address);

    //await commonGovernance.execute(nestCraft.address, getCalldata('update', ['address'], [commonGovernance.address]));
    //await nestCraft.update(nestGovernance.address);

    // await nestCraft.registerTokenConfig({
    //     // The pairIndex for call nest price
    //     pairIndex: 0,

    //     // SigmaSQ for token
    //     sigmaSQ: 45659142400n, //toBigInt(0.0005),
    //     // MIU_LONG for token
    //     miu: 3472222200n //toBigInt(0.00001),
    // });
    // await nestCraft.registerTokenConfig({
    //     // The pairIndex for call nest price
    //     pairIndex: 1,

    //     // SigmaSQ for token
    //     sigmaSQ: 45659142400n, //toBigInt(0.0005),
    //     // MIU_LONG for token
    //     miu: 347222220n //toBigInt(0.00001),
    // });
    // await nestCraft.registerTokenConfig({
    //     // The pairIndex for call nest price
    //     pairIndex: 2,

    //     // SigmaSQ for token
    //     sigmaSQ: 45659142400n, //toBigInt(0.0005),
    //     // MIU for token
    //     miu: 3472222200n //toBigInt(0.00001),
    // });

    //await nest.approve(nestCraft.address, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 3;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        nest: nest,

        commonGovernance: commonGovernance,
        nestCraft: nestCraft,

        BLOCK_TIME: BLOCK_TIME,
        USDT_DECIMALS: 18,

        MIU_LONG: MIU_LONG,
        MIU_SHORT: MIU_SHORT,
        miuT: function(orientation, blocks) {
            return Math.exp((orientation ? MIU_LONG : MIU_SHORT) * blocks * BLOCK_TIME);
        }
    };

/*
    // ** Deploy: bsc_test@20230201.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestFuturesWithPrice: 0xA2D58989ef9981065f749C217984DB21970fF0b7
    // nestCraft: 0x1F51245Ec0cb1D40E4F27373FD180B6157DA44Cd

    已经在bsc测试网上部署了NestCraft测试合约，支持函数和自定义函数功能
    1. estimate(string memory expr). 计算产品表达式的价值，expr为表达式，表达式语法见末尾的【表达式说明】
    2. buy(string memory expr). 买入expr表示的产品，记录为订单，可以通过list接口查询
    3. sell(uint index). 卖出指定编号的订单
    4. list(uint offset, uint count, uint order). 查找买入的订单
    5. registerStaticCall(string memory functionName, address addr). 注册自定义函数

    【表达式说明】
    1. 表达式支持加（+）减（-）乘（*）除（/）以及指数运算（**）
    2. 表达式优先级 + -，* /，** 三个级别，
    3. 支持括号表达式，可以用括号改变计算优先级
    4. 支持字面值数字（可带小数点），计算过程中数字用18位小数表示，最多允许18位小数
    5. 不支持负数字面常量，如需负数，请用（0-47）这样的表达式
    6. 支持标识符，标识符以字母开头（区分大小写），后面可以跟字母或数字，最长31个字符
    7. 支持函数，包括内置函数和自定义函数，函数可嵌套，函数说明详见末尾的【函数说明】
    8. 表达式中所有字符必须是英文半角字符
    9. 表达式中各部分之间允许空格
    10. 表达式计算结果为18位小数表示

    【函数说明】
    1. 函数名称，函数名称以字母开头（区分大小写），后面可以跟字母或数字，最长31个字符，后面紧跟函数的括号
    2. 支持以下内置函数
        bn()                            获取当前区块号
        ts()                            获取当前时间戳
        op(int pairIndex)               从nestFuturesWithPrice（0xA2D58989ef9981065f749C217984DB21970fF0b7）合约获取最新价格
        oav(int pairIndex, int count)   从nestFuturesWithPrice获取最新count个价格，并计算平均值
        ln(int v)                       计算自然对数
        exp(int v)                      计算e的指数
        flo(int v)                      向下取整
        cel(int v)                      向上取整
        log(int a, int b)               计算对数
        pow(int a, int b)               计算指数
       内置函数可以在bscscan合约调用界面测试
    3. 支持自定义函数，具体要求如下
        3.1. 自定义函数的参数和返回值都是int类型表示的10位小数
        3.2. 自定义函数名称不要和内置函数和变量重名
        3.3. 自定义函数定义在独立的合约内，必须是只读的
        3.4. 自定义函数需要调用registerStaticCall(string memory functionName, address addr)注册，其中functionName是函数名称（不包含括号）
        3.5. 一个合约中允许包含多个自定义函数，需要多次调用registerStaticCall(）接口注册
    4. 支持以下鞅函数
        m1(int pairIndex)       线性函数, m1 = a * x + c
        m2(int pairIndex)       平方函数，m2 = a * x ** 2 + c
        m3(int pairIndex)       倒数函数，m3 = a / x + c
        m4(int pairIndex)       开方函数，m4 = a * x ** 0.5 + c
        m5(int pairIndex)       对数函数，m5 = a * ln(x) + c

        其中，pairIndex表示目标代币编号(0:ETH, 1:NEST, 2:BTC)
    
    表达式实例：1.23 * m1(0) + 2.34 * m2(0) + 3.45 * m3(0) + 4.56 * m4(0) + 5.67 * m5(0)
*/

    return contracts;
};