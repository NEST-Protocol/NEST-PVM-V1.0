const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, dcu, 
            hedgeOptions, hedgeFutures, nestPriceFacade, hedgeGovernance,
            hedgeVaultForStaking, BLOCK_TIME
        } = await deploy();

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                dcu: toDecimal(await dcu.balanceOf(account), 18),
            };
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                hedgeVaultForStaking: await getAccountInfo(hedgeVaultForStaking),
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
            let decimals = 0;
            while (price >= 10000000) {
                price = Math.floor(price / 10);
                ++decimals;
            }
            return price * 10 ** decimals;
        }

        if (true) {
            console.log('1. getConfig');
            let config = await hedgeVaultForStaking.getConfig();
            console.log(config.toString());

            await hedgeVaultForStaking.setConfig(toBigInt(0.7), 10, 9527);
            config = await hedgeVaultForStaking.getConfig();
            console.log(config.toString());

            await hedgeVaultForStaking.setConfig(toBigInt(0.1), 10, 71);
            config = await hedgeVaultForStaking.getConfig();
            console.log(config.toString());
        }

        let tokens = [
            { name: 'usdt', address: usdt.address }, 
            { name: 'hbtc', address: hbtc.address }, 
            { name: 'eth' , address:  eth.address }, 
            { name: 'dcu', address: dcu.address },

            { name: 'usdt', address: usdt.address }, 
            { name: 'hbtc', address: hbtc.address }, 
            { name: 'eth' , address:  eth.address }, 
            { name: 'dcu', address: dcu.address },

            { name: 'usdt', address: usdt.address }, 
            { name: 'hbtc', address: hbtc.address }, 
            { name: 'eth' , address:  eth.address }, 
            { name: 'dcu', address: dcu.address },
        ];
        let cycles = [
            10, 10, 10, 10,
            100, 100, 100, 100,
            1000, 1000, 1000, 1000
        ];
        let weights = [
            1, 2, 3, 4,
            10, 20, 30, 40,
            100, 200, 300, 400
        ];
        if (true) {
            console.log('2. batchSetPoolWeight');
            console.log(tokens.map(e=>e.address));
            await hedgeVaultForStaking.batchSetPoolWeight(
                tokens.map(e=>e.address), 
                cycles,
                weights
            );

            for (var i = 0; i < tokens.length; ++i) {
                let token = tokens[i];
                let cycle = cycles[i];
                let ti = await hedgeVaultForStaking.getChannelInfo(token.address, cycle);
                let ts = {
                    name: token.name,
                    address: token.address,
                    totalStaked: toDecimal(ti.totalStaked.toString(), token.address == usdt.address ? 6 : 18),
                    totalRewards: toDecimal(ti.totalRewards.toString()),
                    unlockBlock: ti.unlockBlock.toString()
                }
                //console.log(ts);
            }
        }

        if (true) {
            console.log('3. stake');
            console.log('blockNumber:' + await ethers.provider.getBlockNumber());

            await usdt.transfer(addr1.address, toBigInt(10000000, 6));
            await usdt.transfer(owner.address, toBigInt(10000000, 6));
            await usdt.approve(hedgeVaultForStaking.address, toBigInt(100, 6));
            await usdt.connect(addr1).approve(hedgeVaultForStaking.address, toBigInt(50, 6));
            for (var i = 0; i < 2; ++i) {
                await usdt.transfer(owner.address, toBigInt(10000000, 6));
            }
            await hedgeVaultForStaking.stake(usdt.address, 10, toBigInt(100, 6));
            await hedgeVaultForStaking.connect(addr1).stake(usdt.address, 10, toBigInt(50, 6));
            console.log(await getStatus());
        }
        
        if (true) {
            console.log('4. getReward');
            for (var i = 0; i < 7; ++i) {
                await usdt.transfer(owner.address, toBigInt(0, 6));
            }

            console.log('owner earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, owner.address));
            console.log('addr1 earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, addr1.address));
            console.log('owner balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, owner.address));
            console.log('addr1 balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, addr1.address));

            for (var i = 0; i < 1; ++i) {
                console.log('getReward ' + i);
                await hedgeVaultForStaking.getReward(usdt.address, 10);
                await hedgeVaultForStaking.connect(addr1).getReward(usdt.address, 10);
                console.log(await getStatus());
                console.log('owner earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, owner.address));
                console.log('addr1 earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, addr1.address));
                console.log('owner balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, owner.address));
                console.log('addr1 balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, addr1.address));
            }
        }

        if (true) {
            console.log('5. withdraw');
            for (var i = 0; i < 7; ++i) {
                await usdt.transfer(owner.address, toBigInt(0, 6));
            }

            console.log('owner earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, owner.address));
            console.log('addr1 earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, addr1.address));
            console.log('owner balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, owner.address));
            console.log('addr1 balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, addr1.address));
            await hedgeVaultForStaking.withdraw(usdt.address, 10);
            await hedgeVaultForStaking.connect(addr1).withdraw(usdt.address, 10);
            console.log(await getStatus());
            console.log('owner earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, owner.address));
            console.log('addr1 earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, addr1.address));
            console.log('owner balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, owner.address));
            console.log('addr1 balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, addr1.address));
        }

        if (false) {
            console.log('5. getKey');

            const test = async function(xtoken, cycle) {
                console.log('xtoken=' + xtoken);
                let s = await hedgeVaultForStaking._getKey(xtoken, cycle);
                console.log('s=' + s.toHexString());
                console.log();
            };

            await test(eth.address, 10);
            await test(usdt.address, 10);
            await test(hbtc.address, 10);
            await test(dcu.address, 10);
        }

        if (true) {
            console.log('6. Second');
            
            await hedgeVaultForStaking.setConfig(toBigInt(0.1), 81, 91);
            config = await hedgeVaultForStaking.getConfig();
            console.log(config.toString());

            if (true) {
                console.log('2. batchSetPoolWeight');
                console.log(tokens.map(e=>e.address));
                await hedgeVaultForStaking.batchSetPoolWeight(
                    tokens.map(e=>e.address), 
                    cycles,
                    weights
                );
    
                for (var i = 0; i < tokens.length; ++i) {
                    let token = tokens[i];
                    let cycle = cycles[i];
                    let ti = await hedgeVaultForStaking.getChannelInfo(token.address, cycle);
                    let ts = {
                        name: token.name,
                        address: token.address,
                        totalStaked: toDecimal(ti.totalStaked.toString(), token.address == usdt.address ? 6 : 18),
                        totalRewards: toDecimal(ti.totalRewards.toString()),
                        unlockBlock: ti.unlockBlock.toString()
                    }
                    //console.log(ts);
                }
            }
    
            if (true) {
                console.log('3. stake');
    
                //await usdt.transfer(addr1.address, toBigInt(10000000, 6));
                //await usdt.transfer(owner.address, toBigInt(10000000, 6));
                await usdt.approve(hedgeVaultForStaking.address, toBigInt(100, 6));
                await usdt.connect(addr1).approve(hedgeVaultForStaking.address, toBigInt(100, 6));
                for (var i = 0; i < 2; ++i) {
                //    await usdt.transfer(owner.address, toBigInt(10000000, 6));
                }
                await hedgeVaultForStaking.stake(usdt.address, 10, toBigInt(50, 6));
                await hedgeVaultForStaking.connect(addr1).stake(usdt.address, 10, toBigInt(100, 6));
                console.log(await getStatus());
            }
            
            if (true) {
                console.log('4. getReward');
                for (var i = 0; i < 7; ++i) {
                    await usdt.transfer(owner.address, toBigInt(0, 6));
                }
    
                console.log('owner earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, owner.address));
                console.log('addr1 earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, addr1.address));
                console.log('owner balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, owner.address));
                console.log('addr1 balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, addr1.address));
    
                for (var i = 0; i < 1; ++i) {
                    console.log('getReward ' + i);
                    await hedgeVaultForStaking.getReward(usdt.address, 10);
                    await hedgeVaultForStaking.connect(addr1).getReward(usdt.address, 10);
                    console.log(await getStatus());
                    console.log('owner earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, owner.address));
                    console.log('addr1 earned:' + await hedgeVaultForStaking.earned(usdt.address, 10, addr1.address));
                    console.log('owner balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, owner.address));
                    console.log('addr1 balance:' + await hedgeVaultForStaking.balanceOf(usdt.address, 10, addr1.address));
                }
            }
        }
    });
});
