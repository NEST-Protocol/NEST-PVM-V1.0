// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');

exports.deploy = async function() {
    const NestPriceFacade = await ethers.getContractFactory('NestPriceFacade');
    const FortToken = await ethers.getContractFactory('FortToken');
    const FortEuropeanOption = await ethers.getContractFactory('FortEuropeanOption');
    const FortLever = await ethers.getContractFactory('FortLever');

    const nestPriceFacade = await NestPriceFacade.deploy();
    const fort = await FortToken.deploy();
    const fortEuropeanOption = await FortEuropeanOption.deploy();
    const fortLever = await FortLever.deploy();

    await fortEuropeanOption.setFortToken(fort.address);
    await fortEuropeanOption.setNestPriceFacade(nestPriceFacade.address);
    await fortLever.setFortToken(fort.address);
    await fortLever.setNestPriceFacade(nestPriceFacade.address);

    const contracts = {
        fort: fort,
        fortEuropeanOption: fortEuropeanOption,
        fortLever: fortLever
    };

    return contracts;
}