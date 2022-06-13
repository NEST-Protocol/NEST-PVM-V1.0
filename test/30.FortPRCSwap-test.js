const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');
const { ethers, upgrades } = require('hardhat');

describe('FortOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, dcu, fortOptions, fortFutures, fortLPGuarantee, fortPRC, fortPRCSwap, fortSwap,
            nestPriceFacade, fortGovernance, BLOCK_TIME, USDT_DECIMALS 
        } = await deploy();

        const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');
        const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [fortGovernance.address], { initializer: 'initialize' });
        console.log('cofixRouter: ' + cofixRouter.address);

        await fortSwap.setTokenAddress(usdt.address);
        await fortPRCSwap.setAddress(cofixRouter.address, fortPRC.address);
        await cofixRouter.registerPair(dcu.address, usdt.address, fortSwap.address);
        await cofixRouter.registerPair(dcu.address, fortPRC.address, fortPRCSwap.address);

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 18),
                dcu: toDecimal(await dcu.balanceOf(account), 18),
                fortPRC: toDecimal(await fortPRC.balanceOf(account))
            };
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                fortSwap: await getAccountInfo(fortSwap),
                fortPRCSwap: await getAccountInfo(fortPRCSwap)
            };
        }

        const cfg = async function(tokenAddress) {
            let c = await fortOptions.getConfig(tokenAddress);
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

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, toBigInt(10000000));
        await fortPRC.setMinter(owner.address, 1);
        await fortPRC.mint(owner.address, toBigInt(10000));

        // uint constant K = 200000000000000000000000 * 868616188258191063223411;
        await fortPRC.mint(fortPRCSwap.address, toBigInt(20000000));
        await dcu.mint(fortSwap.address, 868616188258191063223411n);
        await usdt.transfer(fortSwap.address, 200000000000000000000000n);
        await usdt.transfer(owner.address, toBigInt(1000));

        console.log(await getStatus());

        if (true) {
            console.log('1. buy PRC with DCU');
            await dcu.approve(cofixRouter.address, toBigInt(100000000));
            await usdt.approve(cofixRouter.address, toBigInt(100000000));
            await fortPRC.approve(cofixRouter.address, toBigInt(100000000));
            await cofixRouter.swapExactTokensForTokens(
                [dcu.address, fortPRC.address],
                toBigInt(1),
                toBigInt(0),
                owner.address,
                owner.address,
                9999999999
            );
            console.log(await getStatus());            
        }
        if (false) {
            console.log('2. buy DCU with PRC');
            await cofixRouter.swapExactTokensForTokens(
                [fortPRC.address, dcu.address],
                toBigInt(0.5),
                toBigInt(0),
                owner.address,
                owner.address,
                9999999999
            );
            console.log(await getStatus());            
        }
        if (true) {
            console.log('3. buy PRC with USDT');
            await cofixRouter.swapExactTokensForTokens(
                [usdt.address, dcu.address, fortPRC.address],
                toBigInt(1),
                toBigInt(0),
                owner.address,
                owner.address,
                9999999999
            );
            console.log(await getStatus());            
        }
        if (false) {
            console.log('4. buy USDT with PRC');
            await cofixRouter.swapExactTokensForTokens(
                [fortPRC.address, dcu.address, usdt.address],
                toBigInt(2.171529),
                toBigInt(0),
                owner.address,
                owner.address,
                9999999999
            );
            console.log(await getStatus());            
        }
    });
});
