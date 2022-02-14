const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, hedgeOptions, hedgeFutures, nestPriceFacade, hedgeGovernance, BLOCK_TIME, USDT_DECIMALS } = await deploy();
        const FortSwap = await ethers.getContractFactory('FortSwap');
        const TestERC20 = await ethers.getContractFactory('TestERC20');
        
        const fortSwap = await upgrades.deployProxy(FortSwap, [hedgeGovernance.address], { initializer: 'initialize' }); 
        await fortSwap.update(hedgeGovernance.address);
        const busd = await TestERC20.deploy('BUSD', "BUSD", 18);
        console.log('busd: ' + busd.address);

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                busd: toDecimal(await busd.balanceOf(account), 18),
                dcu: toDecimal(await dcu.balanceOf(account), 18),
            };
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                fortSwap: await getAccountInfo(fortSwap),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
            };
        }

        const cfg = async function(tokenAddress) {
            let c = await hedgeOptions.getConfig(tokenAddress);
            return {
                sigmaSQ: c.sigmaSQ.toString(),
                miu: c.miu.toString(),
                minPeriod: c.minPeriod.toString()
            }
        }
        
        const align = function(price) {
            // let decimals = 0;
            // while (price >= 10000000) {
            //     price = Math.floor(price / 10);
            //     ++decimals;
            // }
            // return price * 10 ** decimals;
            return price;
        }

        if (true) {
            console.log('1. Depose dcu and busd');

            await dcu.mint(fortSwap.address, toBigInt(2600000));
            await busd.transfer(fortSwap.address, toBigInt(800000));

            console.log(await getStatus());
        }

        await dcu.approve(fortSwap.address, toBigInt(1000000000));
        await busd.approve(fortSwap.address, toBigInt(1000000000));
        if (true) {
            console.log('2. Swap 1');
            let receipt = await fortSwap.swapForToken(toBigInt(1));
            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if (true) {
            console.log('3. Swap 2');
            let receipt = await fortSwap.swapForDCU(307692189349157943n);
            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if (true) {
            console.log('4. Swap 3');
            let receipt = await fortSwap.swapExactToken(toBigInt(1));
            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if (true) {
            console.log('5. Swap 4');
            let receipt = await fortSwap.swapExactDCU(3250004062429070000n);
            await showReceipt(receipt);
            console.log(await getStatus());
        }
    });
});
