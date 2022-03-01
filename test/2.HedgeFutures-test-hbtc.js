const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt } = require('./utils.js');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, hedgeOptions, hedgeFutures, nestPriceFacade, BLOCK_TIME } = await deploy();
        const TestERC20 = await ethers.getContractFactory('TestERC20');

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const BLOCK = 100000;
        
        const queryPrice = async function(tokenAddress) {
            let tokenAmount = 1e18;
            let usdtAmount = (await nestPriceFacade.latestPriceView(usdt.address)).price;
            let decimals = 18;
            if (tokenAddress != hbtc.address) {
                decimals = await (await TestERC20.attach(tokenAddress)).decimals();
                tokenAmount = (await nestPriceFacade.latestPriceView(tokenAddress)).price;
            }
            
            return Math.floor(usdtAmount * 10 ** decimals / tokenAmount);
        };

        const leverTest = async function(tokenAddress, lever, orientation, amount, fee) {
            await hedgeFutures.buy(tokenAddress, lever, orientation, amount, { value: fee });
            let lot = await hedgeFutures.getFutureInfo(tokenAddress, lever, orientation);
            let oraclePrice = await queryPrice(tokenAddress);
            console.log('owner: ' + toDecimal(await hedgeFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '(lot)');
        } 

        const show = async function(tokenAddress, lever, orientation, amount, fee) {
            //await hedgeFutures.buy(tokenAddress, lever, orientation, amount, { value: fee });
            let lot = await hedgeFutures.getFutureInfo(tokenAddress, lever, orientation);
            //await lot.update(owner.address, { value: fee });
            let oraclePrice = await queryPrice(tokenAddress);
            console.log('owner: ' + toDecimal(await hedgeFutures.balanceOf(lot.index, oraclePrice, owner.address)) + '(lot)');
        } 

        await leverTest(hbtc.address, 1, true, toBigInt(100),   toBigInt(0.01));
        await leverTest(hbtc.address, 2, true, toBigInt(100),   toBigInt(0.01));
        await leverTest(hbtc.address, 5, true, toBigInt(100),   toBigInt(0.01));
        await leverTest(hbtc.address, 1, false, toBigInt(100),  toBigInt(0.01));
        await leverTest(hbtc.address, 2, false, toBigInt(100),  toBigInt(0.01));
        await leverTest(hbtc.address, 5, false, toBigInt(100),  toBigInt(0.01));
        // await leverTest(hbtc.address, 1, true, toBigInt(100),  toBigInt(0.02));
        // await leverTest(hbtc.address, 2, true, toBigInt(100),  toBigInt(0.02));
        // await leverTest(hbtc.address, 5, true, toBigInt(100),  toBigInt(0.02));
        // await leverTest(hbtc.address, 1, false, toBigInt(100), toBigInt(0.02));
        // await leverTest(hbtc.address, 2, false, toBigInt(100), toBigInt(0.02));
        // await leverTest(hbtc.address, 5, false, toBigInt(100), toBigInt(0.02));

        console.log();
        await nestPriceFacade.setPrice(hbtc.address, '75000000000000000', 1);
        await show(hbtc.address, 1, true, toBigInt(100),   toBigInt(0.01));
        await show(hbtc.address, 2, true, toBigInt(100),   toBigInt(0.01));
        await show(hbtc.address, 5, true, toBigInt(100),   toBigInt(0.01));
        await show(hbtc.address, 1, false, toBigInt(100),  toBigInt(0.01));
        await show(hbtc.address, 2, false, toBigInt(100),  toBigInt(0.01));
        await show(hbtc.address, 5, false, toBigInt(100),  toBigInt(0.01));
        // await show(hbtc.address, 1, true, toBigInt(100),  toBigInt(0.02));
        // await show(hbtc.address, 2, true, toBigInt(100),  toBigInt(0.02));
        // await show(hbtc.address, 5, true, toBigInt(100),  toBigInt(0.02));
        // await show(hbtc.address, 1, false, toBigInt(100), toBigInt(0.02));
        // await show(hbtc.address, 2, false, toBigInt(100), toBigInt(0.02));
        // await show(hbtc.address, 5, false, toBigInt(100), toBigInt(0.02));

    });
});
