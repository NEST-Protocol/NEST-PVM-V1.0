const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, fort, fortEuropeanOption, fortLever, nestPriceFacade } = await deploy();

        await fort.setMinter(owner.address, 1);
        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address) )+ 'fort');
        console.log('owner: ' + owner.address);

        await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, '3510000000', 1);

        const BLOCK = 100000;
        await fortEuropeanOption.open(eth.address, '2450123456', true, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        let fot = await fortEuropeanOption.getOptionInfo(
            eth.address,
            '2450123456',
            true,
            BLOCK
        );

        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fortEuropeanOption.balanceOf(fot.index, owner.address)) + '(fot)');
        //expect(await fot.name()).to.equal('C2.450123+3ETH100000');
        let v;
        {
            let S0 = 3510;
            let K = 2450.123456;
            let sigma = 0.00021368; //Math.sqrt(4168125400/1e18);
            let miu = 0.000000025367; //9.5129375951011E-09;
            let T = (BLOCK - await ethers.provider.getBlockNumber()) * 14;

            let vc = Vc(S0, K, sigma, miu, T);
            let vp = Vp(S0, K, sigma, miu, T);
            console.log('vc=' + vc);
            //console.log('vp=' + vp);
            console.log('FOT=' + 1000 / vc);
            expect(Math.abs(1000 / vc - (await fortEuropeanOption.balanceOf(fot.index, owner.address))/1e18)).to.lt(1e-5);
            console.log('gained=' + 1000 / vc * (3510 - 2450.123456));
            v = 1000 / vc * (3510 - 2450.123456) + (await fort.balanceOf(owner.address)) / 1e18;
        }

        await fortEuropeanOption.exercise(fot.index, await fortEuropeanOption.balanceOf(fot.index, owner.address), {
            value: toBigInt(0.01)
        });
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fortEuropeanOption.balanceOf(fot.index, owner.address)) + '(fot)');
        expect(Math.abs(v - (await fort.balanceOf(owner.address)) / 1e18)).to.lt(1e-4);
        console.log();

        await fortEuropeanOption.open(hbtc.address, '47215471234', true, BLOCK, toBigInt(100000), {
            value: toBigInt(0.02)
        });
        fot = await fortEuropeanOption.getOptionInfo(
            hbtc.address,
            '47215471234',
            true,
            BLOCK
        );
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fortEuropeanOption.balanceOf(fot.index, owner.address)) + '(fot)');
        //expect(await fot.name()).to.equal('C4.721547+4HBTC100000');
        {
            let S0 = 47432.432432;
            let K = 47215.471234;
            let sigma = 0.00021368; //Math.sqrt(4168125400/1e18);
            let miu = 0.000000025367; //9.5129375951011E-09;
            let T = (BLOCK - await ethers.provider.getBlockNumber()) * 14;

            let vc = Vc(S0, K, sigma, miu, T);
            let vp = Vp(S0, K, sigma, miu, T);
            console.log('vc=' + vc);
            //console.log('vp=' + vp);
            console.log('FOT=' + 100000 / vc);
            expect(Math.abs(100000 / vc - (await fortEuropeanOption.balanceOf(fot.index, owner.address))/1e18)).to.lt(1e-2);
            console.log('gained=' + 100000 / vc * (47432.432432 - 47215.471234));
            v = 100000 / vc * (47432.432432 - 47215.471234) + (await fort.balanceOf(owner.address)) / 1e18;
        }

        await fortEuropeanOption.exercise(fot.index, await fortEuropeanOption.balanceOf(fot.index, owner.address), {
            value: toBigInt(0.02)
        });
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fortEuropeanOption.balanceOf(fot.index, owner.address)) + '(fot)');
        expect(Math.abs(v - (await fort.balanceOf(owner.address)) / 1e18)).to.lt(1e0);
        console.log();

        await fortEuropeanOption.open(hbtc.address, '47215471234', true, BLOCK, toBigInt(100000), {
            value: toBigInt(0.02)
        });
        fot = await fortEuropeanOption.getOptionInfo(
            hbtc.address,
            '47215471234',
            true,
            BLOCK
        );
        console.log('owner: ' + toDecimal(await fort.balanceOf(owner.address)) + 'fort');
        console.log('owner: ' + toDecimal(await fortEuropeanOption.balanceOf(fot.index, owner.address)) + '(fot)');
    });
});
