// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');

exports.deploy = async function() {
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const FortToken = await ethers.getContractFactory('FortToken');
    const FortBinary = await ethers.getContractFactory('FortBinary');
    
    const nestPriceFacade = await NestPriceFacade.deploy();
    const fort = await FortToken.deploy();
    const fortBinary = await FortBinary.deploy();

    await fortBinary.setFortToken(fort.address);
    await fortBinary.setNestPriceFacade(nestPriceFacade.address);

    const contracts = {
        fort: fort,
        fortBinary: fortBinary
    };

    return contracts;
}