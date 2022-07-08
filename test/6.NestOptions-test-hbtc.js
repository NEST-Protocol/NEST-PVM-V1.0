const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, listBalances, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('6.NestOptions-test-hbtc', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, nest, nestOptions, nestFutures, nestPriceFacade, USDT_DECIMALS } = await deploy();

        await nest.transfer(owner.address, 10000000000000000000000000n);
        
        const tokens = [eth, usdt, hbtc, nest];
        const listAccounts = async function() {
            let accounts = {
                height: await ethers.provider.getBlockNumber(),
                owner: await listBalances(owner, tokens),
                addr1: await listBalances(addr1, tokens),
            };
            console.log(accounts);
            return accounts;
        }

        await listAccounts();

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, toBigInt(3510, USDT_DECIMALS), 1);

        const BLOCK = 100000;
        
        const cfg = async function(tokenAddress) {
            let c = await nestOptions.getConfig(tokenAddress);
            return {
                sigmaSQ: c.sigmaSQ.toString(),
                miu: c.miu.toString(),
                minPeriod: c.minPeriod.toString()
            }
        }

        // if (true) {
        //     console.log('1. Read config');
        //     console.log(await cfg(usdt.address));
        //     console.log(await cfg(eth.address));
        //     console.log(await cfg(hbtc.address));
        // }

        // if (true) {
        //     console.log('2. Read config');
        //     await nestOptions.setConfig(hbtc.address, {
        //         sigmaSQ: '99999999',
        //         miu: '88888',
        //         minPeriod: '77777'
        //     });

        //     await nestOptions.setConfig(hbtc.address, {
        //         sigmaSQ: '333333',
        //         miu: '22222',
        //         minPeriod: '1111'
        //     });

        //     console.log(await cfg(usdt.address));
        //     console.log(await cfg(hbtc.address));
        //     console.log(await cfg(hbtc.address));
        // }

        if (true) {
            console.log('3. list1');
            console.log('tokenCount=' + await nestOptions.getOptionCount());
            let options = await nestOptions.list(0, 5, 0);
            console.log(options);

            options = await nestOptions.list(0, 5, 1);
            console.log(options);
        }

        if (true) {
            console.log('4. list2');

            console.log('tokenCount=' + await nestOptions.getOptionCount());
            await nestOptions.open(hbtc.address, toBigInt(2450000000000, USDT_DECIMALS), true, 100000, toBigInt(1000), {
                value: toBigInt(0.01)
            });
            // /// @dev Open option
            // /// @param tokenAddress Target token address, 0 means eth
            // /// @param strikePrice The exercise price set by the user. During settlement, the system will compare the 
            // /// current price of the subject matter with the exercise price to calculate the user's profit and loss
            // /// @param orientation true: call, false: put
            // /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
            // /// recorded in the system using the block number
            // /// @param dcuAmount Amount of paid DCU
            // function open(
            //     address tokenAddress,
            //     uint strikePrice,
            //     bool orientation,
            //     uint exerciseBlock,
            //     uint dcuAmount
            // )

            // await nestOptions.open(hbtc.address, 52450000000, false, 100000, toBigInt(100000), {
            //     value: toBigInt(0.02)
            // });
            console.log('tokenCount=' + await nestOptions.getOptionCount());
            let options = await nestOptions.list(0, 5, 0);
            console.log(options);

            options = await nestOptions.list(0, 5, 1);
            console.log(options);

            //let fot1 = await nestOptions.getOptionInfo(hbtc.address, 2450000000, true, 100000);
            //let fot2 = await nestOptions.getOptionInfo(hbtc.address, 52450000000, false, 100000);

            //console.log('fot1: ' + fot1.index);
            //console.log('fot2: ' + fot2.index);

            //console.log('fot1-name: ' + fot1);
            //console.log('fot2-name: ' + fot2);
        }
    });
});
