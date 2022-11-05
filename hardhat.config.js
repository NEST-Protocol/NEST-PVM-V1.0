require("@nomiclabs/hardhat-waffle");
require('@openzeppelin/hardhat-upgrades');
require('hardhat-gas-reporter');

const config = require('./.private.json');
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});
// process.env.HTTP_PROXY = 'http://127.0.0.1:8580';
// process.env.HTTPS_PROXY = 'http://127.0.0.1:8580';
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 8888
      }
    }
  },
  networks: {
    mainnet: {
      url: `${config.alchemy.mainnet.url}`,
      accounts: [config.account.mainnet.key, config.account.mainnet.userA, config.account.mainnet.userB],
      gasPrice: 8e9,
      timeout: 2000000000
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${config.infura.key}`,
      accounts: [config.account.test.key, config.account.test.userA, config.account.test.userB],
      gas: 6e6,
      initialBaseFeePerGas: 1e6,
      timeout: 2000000000
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${config.infura.key}`,
      accounts: [config.account.test.key, config.account.test.userA, config.account.test.userB],
      gas: 6e6,
      initialBaseFeePerGas: 1e9,
      timeout: 2000000000
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${config.infura.key}`,
      accounts: [config.account.test.key, config.account.test.userA, config.account.test.userB],
      gas: 5e6,
      gasPrice: 20e9,
      timeout: 2000000000
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${config.infura.key}`,
      accounts: [config.account.test.key, config.account.test.userA, config.account.test.userB],
      gasPrice:1e9,
      timeout: 2000000000
    },
    bsc_test: {
      url: "http://localhost:50000/bsc_test_getblock/",// "https://bsc.getblock.io/testnet/?api_key=57d2baf4-a7a4-4d1b-af95-5c35653e05ea",
      chainId: 97,
      gasPrice: 10e9,
      gas: 6000000,
      accounts: [config.account.test.key, config.account.test.userA, config.account.test.userB],
      timeout: 2000000000
    },
    bsc_main: {
      url: "https://bsc-dataseed1.defibit.io/",
      chainId: 56,
      gasPrice: 5e9,
      gas: 6000000,
      accounts: [config.account.bsc_main.key, config.account.bsc_main.userA, config.account.bsc_main.userB],
      timeout: 2000000000
    },
    hardhat: {
      gas: 12450000,
      gasPrice: 1e9
    }
  },
  mocha: {
    timeout: 200000000
  },
  gasReporter: {
    currency: 'CHF',
    gasPrice: 1
  }
};

