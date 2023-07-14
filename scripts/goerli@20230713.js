// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestToken = await ethers.getContractFactory('NestToken');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestVault = await ethers.getContractFactory('NestVault');
    const NestOptions = await ethers.getContractFactory('NestOptions');
    const NestFutures = await ethers.getContractFactory('NestFutures');
    const NestProbability = await ethers.getContractFactory('NestProbability');
    const NestBuybackPool = await ethers.getContractFactory('NestBuybackPool');

    console.log('** Deploy: goerli@20230713.js **');
    
    //     ** Deploy: goerli@20220924.js **
    // nest: 0xE2975bf674617bbCE57D2c72dCfC926716D8AC1F
    // peth: 0x17322b20752cC7d6094209f6Fa73275375Cf7B27
    // pusd: 0x5cbb73B367FD69807381d06BC2041BEc86d8487d
    // pbtc: 0x48e5c876074549cD4Bb7be0800154450b59b1eB6
    // nestGovernance: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestBatchMining: 0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA

    //     ** Deploy: goerli@20220924.js **
    // nest: 0xE2975bf674617bbCE57D2c72dCfC926716D8AC1F
    // pusd: 0x5cbb73B367FD69807381d06BC2041BEc86d8487d
    // pbtc: 0x48e5c876074549cD4Bb7be0800154450b59b1eB6
    // dabsGovernance: 0x6f66390f80E669BdDf2cE060795Add17ce46C80b
    // dabsPlatform: 0x6eb987Bd8ACE2a41438a3C747B96b0bB7c654B26
    // dabsLedger: 0x4FFED6AE89fA86Ce1cb732caB11899fB695ad265
    // nestGovernance: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestBatchMining: 0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA
    // cofixGovernance: 0xEfDeFDAC7d73A03f05e16743Eed28816F0c63D82
    // cofixRouter: 0x5F1ae37aF4716d12E336d706E2D9bDdA710425c5

    //     ** Deploy: goerli@20221006.js **
    // nest: 0xE2975bf674617bbCE57D2c72dCfC926716D8AC1F
    // pusd: 0x5cbb73B367FD69807381d06BC2041BEc86d8487d
    // pbtc: 0x48e5c876074549cD4Bb7be0800154450b59b1eB6
    // dcu: 0x2E5963e4385Fc85B81B81A7146adC58236AF3f33
    // nestPriceFacade: 0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA
    // nestGovernance: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestVault: 0x7D707d7c44768b7e0A10E24D897dFDaAD2d732e1
    // nestOptions: 0xc4513DE545d02DC8F61D742530620CcFd0E977D8
    // nestFutures: 0x3713Ac1FF40a191905D568E4Db65cb392474BCEC
    // nestProbability: 0x6E9c56E319feb8050e6dB2E597eEaBE529fa84A2
    // nestBuybackPool: 0xdA83DF38F34Cd4E8756827C185f7826C98Db97f0
    const nest = await TestERC20.attach('0xE2975bf674617bbCE57D2c72dCfC926716D8AC1F');
    console.log('nest: ' + nest.address);

    const pusd = await TestERC20.attach('0x5cbb73B367FD69807381d06BC2041BEc86d8487d');
    console.log('pusd: ' + pusd.address);

    const pbtc = await TestERC20.attach('0x48e5c876074549cD4Bb7be0800154450b59b1eB6');
    console.log('pbtc: ' + pbtc.address);

    //const dcu = await TestERC20.deploy('DCU', 'DCU', 18);
    const dcu = await TestERC20.attach('0x2E5963e4385Fc85B81B81A7146adC58236AF3f33');
    console.log('dcu: ' + dcu.address);

    const nestPriceFacade = await NestPriceFacade.attach('0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    const nestGovernance = await NestGovernance.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestVault = await upgrades.deployProxy(NestVault, [nestGovernance.address], { initializer: 'initialize' });
    const nestVault = await NestVault.attach('0x7D707d7c44768b7e0A10E24D897dFDaAD2d732e1');
    console.log('nestVault: ' + nestVault.address);

    //const nestOptions = await upgrades.deployProxy(NestOptions, [nestGovernance.address], { initializer: 'initialize' });
    const nestOptions = await NestOptions.attach('0xc4513DE545d02DC8F61D742530620CcFd0E977D8');
    console.log('nestOptions: ' + nestOptions.address);

    //const nestFutures = await upgrades.deployProxy(NestFutures, [nestGovernance.address], { initializer: 'initialize' });
    const nestFutures = await NestFutures.attach('0x3713Ac1FF40a191905D568E4Db65cb392474BCEC');
    console.log('nestFutures: ' + nestFutures.address);

    //const nestProbability = await upgrades.deployProxy(NestProbability, [nestGovernance.address], { initializer: 'initialize' });
    const nestProbability = await NestProbability.attach('0x6E9c56E319feb8050e6dB2E597eEaBE529fa84A2');
    console.log('nestProbability: ' + nestProbability.address);
    
    //const nestBuybackPool = await upgrades.deployProxy(NestBuybackPool, [nestGovernance.address], { initializer: 'initialize' });
    const nestBuybackPool = await NestBuybackPool.attach('0xdA83DF38F34Cd4E8756827C185f7826C98Db97f0');
    console.log('nestBuybackPool: ' + nestBuybackPool.address);

    // await nestGovernance.registerAddress('nest.v4.openPrice', nestPriceFacade.address);
    // await nestGovernance.registerAddress('nest.app.vault', nestVault.address);
    // await nestGovernance.registerAddress('nest.app.dcu', dcu.address);
    // await nestGovernance.registerAddress('nest.app.prc', nestProbability.address);

    // console.log('4. nestVault.update()');
    // await nestVault.update(nestGovernance.address);
    // console.log('5. nestOptions.update()');
    // await nestOptions.update(nestGovernance.address);
    // console.log('6. nestFutures.update()');
    // await nestFutures.update(nestGovernance.address);
    // console.log('8. nestProbability.update()');
    // await nestProbability.update(nestGovernance.address);
    // console.log('8. nestBuybackPool.update()');
    // await nestBuybackPool.update(nestGovernance.address);

    // // 2.4. Register ETH ans HBTC
    // console.log('7. nestOptions.register(eth.address)');
    // await nestOptions.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // });

    // console.log('8. nestOptions.register(pbtc.address)');
    // await nestOptions.register(pbtc.address, {
    //     channelId: 0,
    //     pairIndex: 1,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // }, { nonce: 72});
    // 3.4. Register ETH and HBTC
    // console.log('9. nestFutures.register(eth.address)');
    // await nestFutures.register(eth.address, {
    //     channelId: 0,
    //     pairIndex: 0,
        
    //     sigmaSQ: 45659142400n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // }, { nonce: 73 });
    
    // console.log('10. nestFutures.register(pbtc.address)');
    // await nestFutures.register(pbtc.address, {
    //     channelId: 0,
    //     pairIndex: 1,
        
    //     sigmaSQ: 31708924900n,
    //     miuLong: 64051194700n,
    //     miuShort: 0n
    // }, { nonce: 74 });

    // console.log('8.2 create lever');
    
    // // 3.5. Register levels for ETH
    // console.log('13. create eth long lever');
    // await nestFutures.create(eth.address, [1, 2, 3, 4, 5], true, { nonce: 75 });
    // console.log('14. create eth short lever');
    // await nestFutures.create(eth.address, [1, 2, 3, 4, 5], false, { nonce: 76 });
    
    // // 3.5. Register levels for HBTC
    // console.log('13. create pbtc long lever');
    // await nestFutures.create(pbtc.address, [1, 2, 3, 4, 5], true, { nonce: 77 });
    // console.log('14. create pbtc short lever');
    // await nestFutures.create(pbtc.address, [1, 2, 3, 4, 5], false, { nonce: 78 });

    // await nest.transfer(nestVault.address, 1000000000000000000000000n, { nonce: 86 });
    // await nest.approve(nestOptions.address, 100000000000000000000000000n, { nonce: 83 });
    // await nest.approve(nestFutures.address, 100000000000000000000000000n, { nonce: 84 });
    // await nest.approve(nestProbability.address, 100000000000000000000000000n, { nonce: 85 });
    // await nestVault.approve(nestOptions.address, 100000000000000000000000000n, { nonce: 80 });
    // await nestVault.approve(nestFutures.address, 100000000000000000000000000n, { nonce: 81 });
    // await nestVault.approve(nestProbability.address, 500000000000000000000000n, { nonce: 82 });

    const newNestToken = await NestToken.deploy();
    console.log('newNestToken: ' + newNestToken.address);

    console.log('---------- OK ----------');
    
    const BLOCK_TIME = 12;
    const MIU_LONG = 3 / 10000 / 86400;
    const MIU_SHORT = 0;

    const contracts = {
        eth: eth,
        pusd: pusd,
        pbtc: pbtc,
        nest: nest,
        dcu: dcu,

        nestGovernance: nestGovernance,
        nestOptions: nestOptions,
        nestFutures: nestFutures,
        nestProbability: nestProbability,
        nestPriceFacade: nestPriceFacade,
        nestBuybackPool: nestBuybackPool,

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