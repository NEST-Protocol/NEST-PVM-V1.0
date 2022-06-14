// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const FortGovernance = await ethers.getContractFactory('FortGovernance');
    const DCU = await ethers.getContractFactory('DCU');
    const FortDAO = await ethers.getContractFactory('FortDAO');
    const FortOptions = await ethers.getContractFactory('FortOptions');
    const FortFutures = await ethers.getContractFactory('FortFutures');
    const FortVaultForStaking = await ethers.getContractFactory('FortVaultForStaking');

    console.log('** Deploy: rinkeby@20210819.js **');
    
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838

    // proxyAdmin: 0x0d60094a1DC03457682060C8f3Ee9eA8AaFC047a
    // fortGovernance: 0xE1328C673620433e0c1847e5BfB698DbCED9688b
    // dcu: 0x6747972f3Fc6f4A4fC9c8a1fF4C2899dc83c4DF7

    //     ** Deploy: rinkeby@20210819.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // fortGovernance: 0xE1328C673620433e0c1847e5BfB698DbCED9688b
    // dcu: 0x6747972f3Fc6f4A4fC9c8a1fF4C2899dc83c4DF7
    // fortDAO: 0x55D6Fe1C851181F5C1779Bf04822675Ae144b38F
    // fortOptions: 0x66bD0139b6216B740820a54a71a2CDFf2070e76B
    // fortFutures: 0xc5086B5a9AC3A4036416690E382AbD7808DC307c
    // fortVaultForStaking: 0x4A0C01665c10a7635fB33BCC45198dfC2f31db0C

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    const usdt = await TestERC20.attach('0x2d750210c0b5343a0b79beff8F054C9add7d2411');
    console.log('usdt: ' + usdt.address);

    //const nestPriceFacade = await NestPriceFacade.deploy();
    const nestPriceFacade = await NestPriceFacade.attach('0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838');
    console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const fortGovernance = await upgrades.deployProxy(FortGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const fortGovernance = await FortGovernance.attach('0xE1328C673620433e0c1847e5BfB698DbCED9688b');
    console.log('fortGovernance: ' + fortGovernance.address);

    //const dcu = await DCU.deploy();
    const dcu = await DCU.attach('0x6747972f3Fc6f4A4fC9c8a1fF4C2899dc83c4DF7');
    console.log('dcu: ' + dcu.address);

    //const fortDAO = await upgrades.deployProxy(FortDAO, [fortGovernance.address], { initializer: 'initialize' });
    const fortDAO = await FortDAO.attach('0x55D6Fe1C851181F5C1779Bf04822675Ae144b38F');
    console.log('fortDAO: ' + fortDAO.address);

    //const fortOptions = await upgrades.deployProxy(FortOptions, [fortGovernance.address], { initializer: 'initialize' });
    const fortOptions = await FortOptions.attach('0x66bD0139b6216B740820a54a71a2CDFf2070e76B');
    console.log('fortOptions: ' + fortOptions.address);

    //const fortFutures = await upgrades.deployProxy(FortFutures, [fortGovernance.address], { initializer: 'initialize' });
    const fortFutures = await FortFutures.attach('0xc5086B5a9AC3A4036416690E382AbD7808DC307c');
    console.log('fortFutures: ' + fortFutures.address);

    //const fortVaultForStaking = await upgrades.deployProxy(FortVaultForStaking, [fortGovernance.address], { initializer: 'initialize' });
    const fortVaultForStaking = await FortVaultForStaking.attach('0x4A0C01665c10a7635fB33BCC45198dfC2f31db0C');
    console.log('fortVaultForStaking: ' + fortVaultForStaking.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        usdt: usdt,

        dcu: dcu,
        fortDAO: fortDAO,
        fortOptions: fortOptions,
        fortFutures: fortFutures,
        fortVaultForStaking: fortVaultForStaking,
        nestPriceFacade: nestPriceFacade
    };

    return contracts;
}