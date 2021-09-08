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
            console.log('1. getBuiltinAddress');
            let r = await fortGovernance.getBuiltinAddress();
            console.log(r);
            // fortToken: '0x0165878A594ca255338adfa4d48449f69242Eb8F',
            // fortDAO: '0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6',
            // fortEuropeanOption: '0x610178dA211FEF7D417bC0e6FeD39F05609AD788',
            // fortLever: '0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0',
            // fortVaultForStaking: '0x9A676e781A523b5d0C0e43731313A708CB607508',
            // nestPriceFacade: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0'
            expect(r.fortToken).to.eq(fort.address);
            expect(r.fortDAO).to.eq(fortDAO.address);
            expect(r.fortEuropeanOption).to.eq(fortEuropeanOption.address);
            expect(r.fortLever).to.eq(fortLever.address);
            expect(r.fortVaultForStaking).to.eq(fortVaultForStaking.address);
            expect(r.nestPriceFacade).to.eq(nestPriceFacade.address);

            expect(await fortGovernance.getFortTokenAddress()).to.eq(fort.address);
            expect(await fortGovernance.getFortDAOAddress()).to.eq(fortDAO.address);
            expect(await fortGovernance.getFortEuropeanOptionAddress()).to.eq(fortEuropeanOption.address);
            expect(await fortGovernance.getFortLeverAddress()).to.eq(fortLever.address);
            expect(await fortGovernance.getFortVaultForStakingAddress()).to.eq(fortVaultForStaking.address);
            expect(await fortGovernance.getNestPriceFacade()).to.eq(nestPriceFacade.address);
        }

        if (true) {
            console.log('2. setUsdtTokenAddress');
            await fortGovernance.setBuiltinAddress(
                '0x0000000000000000000000000000000000000001', //address fortToken,
                '0x0000000000000000000000000000000000000002', //address fortDAO,
                '0x0000000000000000000000000000000000000003', //address fortEuropeanOption,
                '0x0000000000000000000000000000000000000004', //address fortLever,
                '0x0000000000000000000000000000000000000005', //address fortVaultForStaking,
                '0x0000000000000000000000000000000000000006', //address nestPriceFacade
            )
            let r = await fortGovernance.getBuiltinAddress();
            console.log(r);

            expect(await fortGovernance.getFortTokenAddress()).to.eq('0x0000000000000000000000000000000000000001');
            expect(await fortGovernance.getFortDAOAddress()).to.eq('0x0000000000000000000000000000000000000002');
            expect(await fortGovernance.getFortEuropeanOptionAddress()).to.eq('0x0000000000000000000000000000000000000003');
            expect(await fortGovernance.getFortLeverAddress()).to.eq('0x0000000000000000000000000000000000000004');
            expect(await fortGovernance.getFortVaultForStakingAddress()).to.eq('0x0000000000000000000000000000000000000005');
            expect(await fortGovernance.getNestPriceFacade()).to.eq('0x0000000000000000000000000000000000000006');
        }

        if (true) {
            console.log('3. registerAddress');
            console.log(await fortGovernance.checkAddress('fort.app1'));
            await fortGovernance.registerAddress('fort.app1', '0x0000000000000000000000000000000000000006');
            console.log(await fortGovernance.checkAddress('fort.app1'));
        }
    });
});
