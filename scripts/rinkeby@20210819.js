// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const HedgeGovernance = await ethers.getContractFactory('HedgeGovernance');
    const DCU = await ethers.getContractFactory('DCU');
    const HedgeDAO = await ethers.getContractFactory('HedgeDAO');
    const HedgeOptions = await ethers.getContractFactory('HedgeOptions');
    const HedgeFutures = await ethers.getContractFactory('HedgeFutures');
    const HedgeVaultForStaking = await ethers.getContractFactory('HedgeVaultForStaking');

    console.log('** 开始部署合约 rinkeby@20210819.js **');
    
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838

    // proxyAdmin: 0x0d60094a1DC03457682060C8f3Ee9eA8AaFC047a
    // hedgeGovernance: 0xE1328C673620433e0c1847e5BfB698DbCED9688b
    // dcu: 0x6747972f3Fc6f4A4fC9c8a1fF4C2899dc83c4DF7

    //     ** 开始部署合约 rinkeby@20210819.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // hedgeGovernance: 0xE1328C673620433e0c1847e5BfB698DbCED9688b
    // dcu: 0x6747972f3Fc6f4A4fC9c8a1fF4C2899dc83c4DF7
    // hedgeDAO: 0x55D6Fe1C851181F5C1779Bf04822675Ae144b38F
    // hedgeOptions: 0x66bD0139b6216B740820a54a71a2CDFf2070e76B
    // hedgeFutures: 0xc5086B5a9AC3A4036416690E382AbD7808DC307c

    //     ** 开始部署合约 rinkeby@20210819.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // hedgeGovernance: 0xE1328C673620433e0c1847e5BfB698DbCED9688b
    // dcu: 0x6747972f3Fc6f4A4fC9c8a1fF4C2899dc83c4DF7
    // hedgeDAO: 0x55D6Fe1C851181F5C1779Bf04822675Ae144b38F
    // hedgeOptions: 0x66bD0139b6216B740820a54a71a2CDFf2070e76B
    // hedgeFutures: 0xc5086B5a9AC3A4036416690E382AbD7808DC307c
    // hedgeVaultForStaking: 0x4A0C01665c10a7635fB33BCC45198dfC2f31db0C

    // 1. 部署依赖合约
    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x2d750210c0b5343a0b79beff8F054C9add7d2411');
    console.log('usdt: ' + usdt.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const hedgeGovernance = await upgrades.deployProxy(HedgeGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const hedgeGovernance = await HedgeGovernance.attach('0xE1328C673620433e0c1847e5BfB698DbCED9688b');
    console.log('hedgeGovernance: ' + hedgeGovernance.address);

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0x6747972f3Fc6f4A4fC9c8a1fF4C2899dc83c4DF7');
    console.log('dcu: ' + dcu.address);

    //const hedgeDAO = await upgrades.deployProxy(HedgeDAO, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeDAO = await HedgeDAO.attach('0x55D6Fe1C851181F5C1779Bf04822675Ae144b38F');
    console.log('hedgeDAO: ' + hedgeDAO.address);

    //const hedgeOptions = await upgrades.deployProxy(HedgeOptions, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeOptions = await HedgeOptions.attach('0x66bD0139b6216B740820a54a71a2CDFf2070e76B');
    console.log('hedgeOptions: ' + hedgeOptions.address);

    //const hedgeFutures = await upgrades.deployProxy(HedgeFutures, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeFutures = await HedgeFutures.attach('0xc5086B5a9AC3A4036416690E382AbD7808DC307c');
    console.log('hedgeFutures: ' + hedgeFutures.address);

    //const hedgeVaultForStaking = await upgrades.deployProxy(HedgeVaultForStaking, [hedgeGovernance.address], { initializer: 'initialize' });
    const hedgeVaultForStaking = await HedgeVaultForStaking.attach('0x4A0C01665c10a7635fB33BCC45198dfC2f31db0C');
    console.log('hedgeVaultForStaking: ' + hedgeVaultForStaking.address);

    // // await hedgeGovernance.initialize('0x0000000000000000000000000000000000000000');
    // console.log('1. dcu.initialize(hedgeGovernance.address)');
    // await dcu.initialize(hedgeGovernance.address);
    // // await hedgeDAO.initialize(hedgeGovernance.address);
    // // await hedgeOptions.initialize(hedgeGovernance.address);
    // // await hedgeFutures.initialize(hedgeGovernance.address);
    // // await hedgeVaultForStaking.initialize(hedgeGovernance.address);

    // console.log('2. hedgeGovernance.setBuiltinAddress()');
    // await hedgeGovernance.setBuiltinAddress(
    //     dcu.address,
    //     hedgeDAO.address,
    //     hedgeOptions.address,
    //     hedgeFutures.address,
    //     hedgeVaultForStaking.address,
    //     nestPriceFacade.address
    // );

    // console.log('3. dcu.update()');
    // await dcu.update(hedgeGovernance.address);
    // console.log('4. hedgeDAO.update()');
    // await hedgeDAO.update(hedgeGovernance.address);
    // console.log('5. hedgeOptions.update()');
    // await hedgeOptions.update(hedgeGovernance.address);
    // console.log('6. hedgeFutures.update()');
    // await hedgeFutures.update(hedgeGovernance.address);
    // console.log('7. hedgeVaultForStaking.update()');
    // await hedgeVaultForStaking.update(hedgeGovernance.address);

    // console.log('8. hedgeOptions.setConfig()');
    // await hedgeOptions.setConfig('175482725206');

    // console.log('9. dcu.setMinter(hedgeOptions.address, 1)');
    // await dcu.setMinter(hedgeOptions.address, 1);
    // console.log('10. dcu.setMinter(hedgeFutures.address, 1)');
    // await dcu.setMinter(hedgeFutures.address, 1);
    // console.log('11. dcu.setMinter(hedgeVaultForStaking.address, 1)');
    // await dcu.setMinter(hedgeVaultForStaking.address, 1);

    console.log('---------- OK ----------');
    
    const contracts = {
        usdt: usdt,

        dcu: dcu,
        hedgeDAO: hedgeDAO,
        hedgeOptions: hedgeOptions,
        hedgeFutures: hedgeFutures,
        hedgeVaultForStaking: hedgeVaultForStaking,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
}