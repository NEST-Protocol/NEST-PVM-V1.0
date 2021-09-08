const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, fort, 
            fortEuropeanOption, fortLever, nestPriceFacade, fortGovernance,
            fortVaultForStaking, fortDAO
        } = await deploy();

        await fort.setMinter(owner.address, 1);
        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address) )+ 'fort');
        console.log('owner: ' + owner.address);

        const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
        const FortOptionToken = await ethers.getContractFactory('FortOptionToken');
        const FortLeverToken = await ethers.getContractFactory('FortLeverToken');
        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                fort: toDecimal(await fort.balanceOf(account), 18),
            };
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                fort: await getAccountInfo(fort),
                fortDAO: await getAccountInfo(fortDAO),
            };
        }

        const cfg = async function(tokenAddress) {
            let c = await fortEuropeanOption.getConfig(tokenAddress);
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
            console.log('1. initialize');
            await fort.update(eth.address);
            await fort.initialize(fortGovernance.address);
            await fort.update(fortGovernance.address);
            await fort.update(fortGovernance.address);
            await fort.update(fortGovernance.address);
            await fort.update(fortGovernance.address);
            await fort.update(fortGovernance.address);
            await fort.update(fortGovernance.address);
            await fort.update(fortGovernance.address);
        }

        if (true) {
            console.log('2. migrate');
            console.log(await getStatus());

            await fort.test({ value: toBigInt(57) });
            await usdt.transfer(fort.address, toBigInt(100, 6));
            await fort.transfer(fort.address, toBigInt(200));
            console.log(await getStatus());

            await fort.migrate(usdt.address, toBigInt(50, 6));
            await fort.migrate(fort.address, toBigInt(150));
            await fort.migrate(eth.address, toBigInt(26));
            console.log(await getStatus());

            await fort.migrate(usdt.address, toBigInt(50, 6));
            await fort.migrate(fort.address, toBigInt(50));
            await fort.migrate(eth.address, toBigInt(31));
            console.log(await getStatus());
        }

        if (true) {
            console.log('3. settle');
            console.log('app: ' + await fortDAO.checkApplication(owner.address));
            await fortDAO.setApplication(owner.address, 1);
            console.log('app: ' + await fortDAO.checkApplication(owner.address));
            await fortDAO.settle(eth.address, eth.address, owner.address, toBigInt(0.9527));
            await fortDAO.settle(eth.address, usdt.address, owner.address, toBigInt(17, 6));
            await fortDAO.settle(eth.address, fort.address, owner.address, toBigInt(31));
            console.log(await getStatus());
            console.log('totalETHRewards: ' + await fortDAO.totalETHRewards(eth.address));
        }
    });
});
