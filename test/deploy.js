const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');

describe('FortEuropeanOption', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { eht, usdt, fort, fortEuropeanOption, fortLever } = await deploy();
    });
});
