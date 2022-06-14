const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('27.listoptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, fortOptions, fortFutures, nestPriceFacade, USDT_DECIMALS } = await deploy();

        const BLOCK = 100000;
        
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
                addr1: await getAccountInfo(addr1),
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

        if (true) {
           console.log('1. list options');

           const optionCount = await fortOptions.getOptionCount();
           console.log('optionCount: ' + optionCount);
           const options = await fortOptions.list(0, optionCount, 1);

           for(var i = 0; i < options.length; ++i) {
               const o = options[i];
               const option = {
                   index: o.index.toString(),
                   tokenAddress: o.tokenAddress.toString(),
                   strikePrice: o.strikePrice.toString(),
                   orientation: o.orientation.toString(),
                   exerciseBlock: o.exerciseBlock.toString(),
                   balance: o.balance.toString()
               }
               console.log(option);
           }
        }
    });
});
