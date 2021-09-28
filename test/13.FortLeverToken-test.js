const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, fort, fortEuropeanOption, fortLever, nestPriceFacade, fortGovernance } = await deploy();
        const TestERC20 = await ethers.getContractFactory('TestERC20');

        await fort.setMinter(owner.address, 1);
        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address) )+ 'fort');
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
                fort: toDecimal(await fort.balanceOf(account), 18),
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
            console.log('1. list');
            let l = await fortLever.list(0, 20, 0);
            console.log(l);
            l = await fortLever.list(0, 20, 1);
            console.log(l);
        }

        const queryPrice = async function(tokenAddress) {
            let tokenAmount = 1e18;
            let usdtAmount = (await nestPriceFacade.latestPriceView(usdt.address)).price;
            let decimals = 18;
            if (tokenAddress != eth.address) {
                decimals = await (await TestERC20.attach(tokenAddress)).decimals();
                tokenAmount = (await nestPriceFacade.latestPriceView(tokenAddress)).price;
            }
            
            return Math.floor(usdtAmount * 10 ** decimals / tokenAmount);
        };

        let addrs = [eth.address, hbtc.address];
        let levers = [1, 2, 5];
        let oriens = [true, false];
        if (true) {
            console.log('2. getLeverCount');
            let tokenCount = await fortLever.getLeverCount();
            console.log('tokenCount=' + tokenCount);
            let l = await fortLever.list(0, tokenCount, 0);
            for (var i = 0; i < l.length; ++i) {
                let li = l[i];
                console.log({
                    index: li.index.toString(),
                    tokenAddress: li.tokenAddress,
                    lever: li.lever.toString(),
                    orientation: li.orientation
                });
            }

            for (var addr = 0; addr < addrs.length; ++addr) {
                for (var lever = 0; lever < levers.length; ++lever) {
                    for (var orien = 0; orien < oriens.length; ++orien) {
                        let li = await fortLever.getLeverInfo(addrs[addr], levers[lever], oriens[orien]);
                        console.log({
                            index: li.index.toString(),
                            tokenAddress: li.tokenAddress,
                            lever: li.lever.toString(),
                            orientation: li.orientation
                        });
                    }
                }
            }
        }

        if (true) {
            console.log('3. create');
            let receipt = await fortLever.create(hbtc.address, 3, false);
            await showReceipt(receipt);
            let tokenCount = await fortLever.getLeverCount();
            console.log('tokenCount=' + tokenCount);
            let l = await fortLever.list(0, tokenCount, 0);
            for (var i = 0; i < l.length; ++i) {
                let li = l[i];
                console.log({
                    index: li.index.toString(),
                    tokenAddress: li.tokenAddress,
                    lever: li.lever.toString(),
                    orientation: li.orientation
                });
            }
        }

        if (false) {
            console.log('4. setNestPriceFacade');
            let lotAddress = await fortLever.getLeverToken(hbtc.address, 2, true);
            let lot = await FortLeverToken.attach(lotAddress);
            let receipt = await fortLever.buyDirect(lot.address, toBigInt(100), { value: toBigInt(0.02) });
            await showReceipt(receipt);
            await fortLever.updateLeverInfo([lot.address], owner.address, { value: toBigInt(0.02) });
            console.log({
                name: await lot.name(),
                price: toDecimal((await lot.getLeverInfo()).price, 6),
                balance: toDecimal(await lot.balanceOf(owner.address))
            });

            let newNP = await NestPriceFacade.deploy();
            await fortGovernance.setBuiltinAddress(
                eth.address,
                eth.address,
                eth.address,
                eth.address,
                eth.address,
                newNP.address
            );
            await fortLever.update(fortGovernance.address);
            await fortLever.updateLeverInfo([lot.address], owner.address, { value: toBigInt(0.02) });
            console.log({
                name: await lot.name(),
                price: toDecimal((await lot.getLeverInfo()).price, 6),
                balance: toDecimal(await lot.balanceOf(owner.address))
            });
            await fortLever.sync([lot.address]);
            await fortLever.updateLeverInfo([lot.address], owner.address, { value: toBigInt(0.02) });
            console.log({
                name: await lot.name(),
                price: toDecimal((await lot.getLeverInfo()).price, 6),
                balance: toDecimal(await lot.balanceOf(owner.address))
            });
        }

        if (false) {
            console.log('5. update');
            let lotAddress = await fortLever.getLeverToken(hbtc.address, 2, true);
            let lot = await FortLeverToken.attach(lotAddress);
            let receipt = await fortLever.buyDirect(lot.address, toBigInt(100), { value: toBigInt(0.02) });
            await showReceipt(receipt);
            await lot.update(owner.address, { value: toBigInt(0.02) });
            console.log({
                name: await lot.name(),
                price: toDecimal((await lot.getLeverInfo()).price, 6),
                balance: toDecimal(await lot.balanceOf(owner.address))
            });

            let newNP = await NestPriceFacade.deploy();
            await fortGovernance.setBuiltinAddress(
                eth.address,
                eth.address,
                eth.address,
                eth.address,
                eth.address,
                newNP.address
            );
            await fortLever.update(fortGovernance.address);
            await lot.update(owner.address, { value: toBigInt(0.02) });
            console.log({
                name: await lot.name(),
                price: toDecimal((await lot.getLeverInfo()).price, 6),
                balance: toDecimal(await lot.balanceOf(owner.address))
            });
            await fortLever.sync([lot.address]);
            await lot.update(owner.address, { value: toBigInt(0.02) });
            console.log({
                name: await lot.name(),
                price: toDecimal((await lot.getLeverInfo()).price, 6),
                balance: toDecimal(await lot.balanceOf(owner.address))
            });
        }

        if (true) {
            console.log('6. transfer');
            let lot = await fortLever.getLeverInfo(hbtc.address, 1, true);
            // let lot = await FortLeverToken.attach(lotAddress);
            let receipt = await fortLever.buyDirect(lot.index, toBigInt(100), { value: toBigInt(0.02) });
            await showReceipt(receipt);
            
            let oraclePrice = await queryPrice(hbtc.address);
            console.log({
                name: '[' + lot.index + ']',
                price: toDecimal(oraclePrice, 6),
                balance: toDecimal(await fortLever.balanceOf(lot.index, oraclePrice, owner.address)),
                balance2: toDecimal(await fortLever.balanceOf(lot.index, oraclePrice, addr1.address))
            });

            for (var i = 0; i < 100; ++i) {
                await fort.transfer(owner.address, 0);
            }
            // await lot.transfer(addr1.address, toBigInt(30), { value: toBigInt(0.02)});
            
            // console.log({
            //     name: await lot.name(),
            //     price: toDecimal((await lot.getLeverInfo()).price, 6),
            //     balance: toDecimal(await lot.balanceOf(owner.address)),
            //     balance2: toDecimal(await lot.balanceOf(addr1.address))
            // });

            // console.log({
            //     name: await lot.name(),
            //     price: toDecimal((await lot.getLeverInfo()).price, 6),
            //     balanceE: toDecimal(await lot.estimateBalance(owner.address, '40540540540')),
            //     balance2E: toDecimal(await lot.estimateBalance(addr1.address, '40540540540'))
            // });

            // await nestPriceFacade.setPrice(usdt.address, '3000000000', 1);
            // await lot.update(owner.address, { value: toBigInt(0.02)});
            // console.log({
            //     name: await lot.name(),
            //     price: toDecimal((await lot.getLeverInfo()).price, 6),
            //     balance: toDecimal(await lot.balanceOf(owner.address)),
            //     balance2: toDecimal(await lot.balanceOf(addr1.address))
            // });
        }

        if (false) {
            console.log('6. _toUInt128');
            let lotAddress = await fortLever.getLeverToken(hbtc.address, 1, true);
            let lot = await FortLeverToken.attach(lotAddress);
            const test = async function(v) {
                let s1 = v;
                let s2 = await lot._toUInt128(v);

                console.log({ s1: s1.toString(), s2: s2.toString() });
            };

            await test(0);
            await test(1);
            await test(2);
            await test(3);
            await test(4);
            await test(5);
            await test(6);
            await test(7);
            await test(8);
            await test(9);
            await test(10);
            await test(11);

            for (var bi = BigInt(3); bi < BigInt('0x100000000000000000000000000000000'); bi *= BigInt(37)) {
                await test(bi);
            }

            await test(BigInt('0x100000000000000000000000000000000') - BigInt(1));
        }

        if (false) {
            console.log('7. _encodeFloat');
            let lotAddress = await fortLever.getLeverToken(hbtc.address, 1, true);
            let lot = await FortLeverToken.attach(lotAddress);
            const test = async function(v) {
                let s1 = BigInt(v);
                let s2 = BigInt(await lot._decodeFloat(await lot._encodeFloat(v)));

                console.log({ s1: s1.toString(), s2: s2.toString() });
                let x = (s1 - s2) * BigInt(1e18) / s1;
                if (x < BigInt(0)) {
                    x = -x;
                }
                x = parseFloat(toDecimal(x));
                expect(x).to.lt(0.0000000000000001);
            };

            await test(1);
            await test(2);
            await test(3);
            await test(4);
            await test(5);
            await test(6);
            await test(7);
            await test(8);
            await test(9);
            await test(10);
            await test(11);

            for (var bi = BigInt(3); bi < BigInt('0x10000000000000000000000000000000000000000000000000000000000000000'); bi *= BigInt(37)) {
                await test(bi);
            }

            await test(BigInt('0x10000000000000000000000000000000000000000000000000000000000000000') - BigInt(1));
        }
    });
});
