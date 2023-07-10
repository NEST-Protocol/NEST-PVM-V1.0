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
    compilers: [
      { 
        version: '0.6.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 800,
          },
          metadata: {
            // do not include the metadata hash, since this is machine dependent
            // and we want all generated code to be deterministic
            // https://docs.soliditylang.org/en/v0.7.6/metadata.html
            bytecodeHash: 'none',
          },
        }
      }, { 
        version: '0.5.16',
        settings: {
          optimizer: {
            enabled: true,
            runs: 800,
          }
        }
      }, {
        version: '0.8.19',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
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
    bsc_test: {
      url: 
      'http://localhost:50000/bsc_test_getblock/',
      //'https://bsc.getblock.io/33a5ac19-a33e-40c9-aa06-33e32c18b459/testnet/',
      //'https://bsc-testnet.s.chainbase.online/v1/2IACpoXYkHcgiWwSB4l2VmdWizr',
      chainId: 97,
      gasPrice: 10e9,
      gas: 6000000,
      accounts: [config.account.test.key, config.account.test.userA, config.account.test.userB],
      timeout: 2000000000
    },
    bsc_main: {
      url: 
      'http://localhost:50001/bsc_main_getblock/',
      //"https://bsc-dataseed1.defibit.io/",
      // "https://bsc-mainnet.s.chainbase.online/v1/2IACpoXYkHcgiWwSB4l2VmdWizr",
      //"https://bsc.getblock.io/33a5ac19-a33e-40c9-aa06-33e32c18b459/mainnet/",
      chainId: 56,
      gasPrice: 3e9,
      gas: 6000000,
      accounts: [config.account.bsc_main.key, config.account.bsc_main.userA, config.account.bsc_main.userB],
      timeout: 2000000000
    },
    scrollTest: {
      url: 
      'https://alpha-rpc.scroll.io/l2',
      //'https://bsc.getblock.io/33a5ac19-a33e-40c9-aa06-33e32c18b459/testnet/',
      //'https://bsc-testnet.s.chainbase.online/v1/2IACpoXYkHcgiWwSB4l2VmdWizr',
      chainId: 534353,
      gasPrice: 0.002e9,
      gas: 6000000,
      accounts: [config.account.test.key, config.account.test.userA, config.account.test.userB],
      timeout: 2000000000
    },
    hardhat: {
      gas: 12450000,
      gasPrice: 0
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

