const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('FortOptions', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { eth, usdt, hbtc, dcu, fortOptions, fortFutures, nestPriceFacade, 
            BLOCK_TIME, USDT_DECIMALS, MIU_LONG, MIU_SHORT } = await deploy();
        const USDT_BASE = BigInt(10 ** USDT_DECIMALS);

        await dcu.setMinter(owner.address, 1);
        await dcu.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address) )+ 'dcu');
        console.log('owner: ' + owner.address);

        //await nestPriceFacade.setPrice(hbtc.address, '74000000000000000', 1);
        await nestPriceFacade.setPrice(usdt.address, toBigInt(3510, USDT_DECIMALS), 1);

        const BLOCK = 100000;
        await fortOptions.open(eth.address, toBigInt(2450, USDT_DECIMALS), true, BLOCK, toBigInt(1000), {
            value: toBigInt(0.01)
        });
        
        // let fot = await fortOptions.getOptionInfo(
        //     eth.address,
        //     '2450000000',
        //     true,
        //     BLOCK
        // );
        let fot = { index: 0 };
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address)) + 'dcu');
        console.log('owner: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)) + '(fot)');
        let v;
        {
            let S0 = 3510;
            let K = 2450;
            let sigma = 0.00021368; //Math.sqrt(4168125400/1e18);
            //let miu = 0.000000025367;
            let T = (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME;

            let vc = Vc(S0, K, sigma, MIU_LONG, T);
            let vp = Vp(S0, K, sigma, MIU_SHORT, T);
            console.log('vc=' + vc);
            //console.log('vp=' + vp);
            console.log('FOT=' + 1000 / vc);
            expect(Math.abs(1000 / vc - (await fortOptions.balanceOf(fot.index, owner.address))/1e18)).to.lt(1e-5);
            console.log('gained=' + 1000 / vc * (3510 - 2450));
            v = 1000 / vc * (3510 - 2450) + (await dcu.balanceOf(owner.address)) / 1e18;
        }

        await fortOptions.exercise(fot.index, await fortOptions.balanceOf(fot.index, owner.address), {
            value: toBigInt(0.01)
        });
        console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address)) + 'dcu');
        console.log('owner: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)) + '(fot)');
        expect(Math.abs(v - (await dcu.balanceOf(owner.address)) / 1e18)).to.lt(1e-4);
        console.log();

        // await fortOptions.open(hbtc.address, '47215470000', true, BLOCK, toBigInt(100000), {
        //     value: toBigInt(0.02)
        // });
        // fot = await fortOptions.getOptionInfo(
        //     hbtc.address,
        //     '47215470000',
        //     true,
        //     BLOCK
        // );
        // console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address)) + 'dcu');
        // console.log('owner: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)) + '(fot)');
        // {
        //     let S0 = 47432.432432;
        //     let K = 47215.470000;
        //     let sigma = 0.00021368; //Math.sqrt(4168125400/1e18);
        //     let miu = 0.000000025367;
        //     let T = (BLOCK - await ethers.provider.getBlockNumber()) * BLOCK_TIME;

        //     let vc = Vc(S0, K, sigma, miu, T);
        //     let vp = Vp(S0, K, sigma, miu, T);
        //     console.log('vc=' + vc);
        //     //console.log('vp=' + vp);
        //     console.log('FOT=' + 100000 / vc);
        //     expect(Math.abs(100000 / vc - (await fortOptions.balanceOf(fot.index, owner.address))/1e18)).to.lt(1e-2);
        //     console.log('gained=' + 100000 / vc * (47432.432432 - 47215.470000));
        //     v = 100000 / vc * (47432.432432 - 47215.470000) + (await dcu.balanceOf(owner.address)) / 1e18;
        // }

        // await fortOptions.exercise(fot.index, await fortOptions.balanceOf(fot.index, owner.address), {
        //     value: toBigInt(0.02)
        // });
        // console.log('owner: ' + toDecimal(await dcu.balanceOf(owner.address)) + 'dcu');
        // console.log('owner: ' + toDecimal(await fortOptions.balanceOf(fot.index, owner.address)) + '(fot)');
        // expect(Math.abs(v - (await dcu.balanceOf(owner.address)) / 1e18)).to.lt(1e0);
        // console.log();
    });
});
