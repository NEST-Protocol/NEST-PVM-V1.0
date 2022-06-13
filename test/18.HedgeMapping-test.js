const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, dcu, 
            fortOptions, fortFutures, nestPriceFacade, fortGovernance,
            fortVaultForStaking, fortDAO, USDT_DECIMALS
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
                usdt: toDecimal(await usdt.balanceOf(account), USDT_DECIMALS),
                dcu: toDecimal(await dcu.balanceOf(account), 18),
            };
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                dcu: await getAccountInfo(dcu),
                fortDAO: await getAccountInfo(fortDAO),
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
            // dcuToken: '0x0165878A594ca255338adfa4d48449f69242Eb8F',
            // fortDAO: '0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6',
            // fortOptions: '0x610178dA211FEF7D417bC0e6FeD39F05609AD788',
            // fortFutures: '0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0',
            // fortVaultForStaking: '0x9A676e781A523b5d0C0e43731313A708CB607508',
            // nestPriceFacade: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0'
            expect(r.dcuToken).to.eq(dcu.address);
            expect(r.fortDAO).to.eq(fortDAO.address);
            expect(r.fortOptions).to.eq(fortOptions.address);
            expect(r.fortFutures).to.eq(fortFutures.address);
            expect(r.fortVaultForStaking).to.eq(fortVaultForStaking.address);
            expect(r.nestPriceFacade).to.eq(nestPriceFacade.address);

            expect(await fortGovernance.getDCUTokenAddress()).to.eq(dcu.address);
            expect(await fortGovernance.getHedgeDAOAddress()).to.eq(fortDAO.address);
            expect(await fortGovernance.getHedgeOptionsAddress()).to.eq(fortOptions.address);
            expect(await fortGovernance.getHedgeFuturesAddress()).to.eq(fortFutures.address);
            expect(await fortGovernance.getHedgeVaultForStakingAddress()).to.eq(fortVaultForStaking.address);
            expect(await fortGovernance.getNestPriceFacade()).to.eq(nestPriceFacade.address);
        }

        if (true) {
            console.log('2. setUsdtTokenAddress');
            await fortGovernance.setBuiltinAddress(
                '0x0000000000000000000000000000000000000001', //address dcuToken,
                '0x0000000000000000000000000000000000000002', //address fortDAO,
                '0x0000000000000000000000000000000000000003', //address fortOptions,
                '0x0000000000000000000000000000000000000004', //address fortFutures,
                '0x0000000000000000000000000000000000000005', //address fortVaultForStaking,
                '0x0000000000000000000000000000000000000006', //address nestPriceFacade
            )
            let r = await fortGovernance.getBuiltinAddress();
            console.log(r);

            expect(await fortGovernance.getDCUTokenAddress()).to.eq('0x0000000000000000000000000000000000000001');
            expect(await fortGovernance.getHedgeDAOAddress()).to.eq('0x0000000000000000000000000000000000000002');
            expect(await fortGovernance.getHedgeOptionsAddress()).to.eq('0x0000000000000000000000000000000000000003');
            expect(await fortGovernance.getHedgeFuturesAddress()).to.eq('0x0000000000000000000000000000000000000004');
            expect(await fortGovernance.getHedgeVaultForStakingAddress()).to.eq('0x0000000000000000000000000000000000000005');
            expect(await fortGovernance.getNestPriceFacade()).to.eq('0x0000000000000000000000000000000000000006');
        }

        if (true) {
            console.log('3. registerAddress');
            console.log(await fortGovernance.checkAddress('dcu.app1'));
            await fortGovernance.registerAddress('dcu.app1', '0x0000000000000000000000000000000000000006');
            console.log(await fortGovernance.checkAddress('dcu.app1'));
        }
    });
});
