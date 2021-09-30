const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('HedgeOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            eth, usdt, hbtc, dcu, 
            hedgeOptions, hedgeFutures, nestPriceFacade, hedgeGovernance,
            hedgeVaultForStaking, hedgeDAO
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
                dcu: await getAccountInfo(dcu),
                hedgeDAO: await getAccountInfo(hedgeDAO),
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
            console.log('1. getBuiltinAddress');
            let r = await hedgeGovernance.getBuiltinAddress();
            console.log(r);
            // dcuToken: '0x0165878A594ca255338adfa4d48449f69242Eb8F',
            // hedgeDAO: '0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6',
            // hedgeOptions: '0x610178dA211FEF7D417bC0e6FeD39F05609AD788',
            // hedgeFutures: '0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0',
            // hedgeVaultForStaking: '0x9A676e781A523b5d0C0e43731313A708CB607508',
            // nestPriceFacade: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0'
            expect(r.dcuToken).to.eq(dcu.address);
            expect(r.hedgeDAO).to.eq(hedgeDAO.address);
            expect(r.hedgeOptions).to.eq(hedgeOptions.address);
            expect(r.hedgeFutures).to.eq(hedgeFutures.address);
            expect(r.hedgeVaultForStaking).to.eq(hedgeVaultForStaking.address);
            expect(r.nestPriceFacade).to.eq(nestPriceFacade.address);

            expect(await hedgeGovernance.getDCUTokenAddress()).to.eq(dcu.address);
            expect(await hedgeGovernance.getHedgeDAOAddress()).to.eq(hedgeDAO.address);
            expect(await hedgeGovernance.getHedgeOptionsAddress()).to.eq(hedgeOptions.address);
            expect(await hedgeGovernance.getHedgeFuturesAddress()).to.eq(hedgeFutures.address);
            expect(await hedgeGovernance.getHedgeVaultForStakingAddress()).to.eq(hedgeVaultForStaking.address);
            expect(await hedgeGovernance.getNestPriceFacade()).to.eq(nestPriceFacade.address);
        }

        if (true) {
            console.log('2. setUsdtTokenAddress');
            await hedgeGovernance.setBuiltinAddress(
                '0x0000000000000000000000000000000000000001', //address dcuToken,
                '0x0000000000000000000000000000000000000002', //address hedgeDAO,
                '0x0000000000000000000000000000000000000003', //address hedgeOptions,
                '0x0000000000000000000000000000000000000004', //address hedgeFutures,
                '0x0000000000000000000000000000000000000005', //address hedgeVaultForStaking,
                '0x0000000000000000000000000000000000000006', //address nestPriceFacade
            )
            let r = await hedgeGovernance.getBuiltinAddress();
            console.log(r);

            expect(await hedgeGovernance.getDCUTokenAddress()).to.eq('0x0000000000000000000000000000000000000001');
            expect(await hedgeGovernance.getHedgeDAOAddress()).to.eq('0x0000000000000000000000000000000000000002');
            expect(await hedgeGovernance.getHedgeOptionsAddress()).to.eq('0x0000000000000000000000000000000000000003');
            expect(await hedgeGovernance.getHedgeFuturesAddress()).to.eq('0x0000000000000000000000000000000000000004');
            expect(await hedgeGovernance.getHedgeVaultForStakingAddress()).to.eq('0x0000000000000000000000000000000000000005');
            expect(await hedgeGovernance.getNestPriceFacade()).to.eq('0x0000000000000000000000000000000000000006');
        }

        if (true) {
            console.log('3. registerAddress');
            console.log(await hedgeGovernance.checkAddress('dcu.app1'));
            await hedgeGovernance.registerAddress('dcu.app1', '0x0000000000000000000000000000000000000006');
            console.log(await hedgeGovernance.checkAddress('dcu.app1'));
        }
    });
});
