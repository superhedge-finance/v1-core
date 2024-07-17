require("@nomicfoundation/hardhat-toolbox");
const { PRIVATE_KEY, API_KEY_ARBISCAN } = require('./secret.json');

// Arbiscan API key
const apiKey = API_KEY_ARBISCAN;

// From wallet used to deploy
const privateKey = PRIVATE_KEY;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "arbitrum",
  networks: {
    arbitrum:{
      url:'https://arb1.arbitrum.io/rpc',
      accounts: [privateKey]
    },
  },
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 20000
  },
  etherscan: {
    apiKey: apiKey
  }
};