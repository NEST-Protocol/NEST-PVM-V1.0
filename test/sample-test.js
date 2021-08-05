const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { fort, fortEuropeanOption } = await deploy();

        await fort.mint(owner.address, '10000000000000000000000000');
        
        console.log('owner: ' + await fort.balanceOf(owner.address) + 'fort');

        await fortEuropeanOption.open(fort.address, '2450000000', true, 1000, '1000000000000000000');

        const FortOptionToken = await ethers.getContractFactory('FortOptionToken');
        const bot = await FortOptionToken.attach(
            await fortEuropeanOption.getBinaryToken(fort.address, '2450000000', true, 1000)
        );
        console.log('bot: ' + bot.address);
        console.log('owner: ' + await fort.balanceOf(owner.address) + 'fort');
        console.log('owner: ' + await bot.balanceOf(owner.address) + 'bot');

        await fortEuropeanOption.exercise(bot.address, '300000000000000000');

        console.log('owner: ' + await fort.balanceOf(owner.address) + 'fort');
        console.log('owner: ' + await bot.balanceOf(owner.address) + 'bot');
        // await greeter.deployed();
        // expect(await greeter.greet()).to.equal("Hello, world!");

        // await greeter.setGreeting("Hola, mundo!");
        // expect(await greeter.greet()).to.equal("Hola, mundo!");
    });
});
