require("@nomicfoundation/hardhat-toolbox");

const { PRIVATE_KEY } = require("./secret.json");

const { ETHEREUM_RPC_URL } = require("./secret.json");
const { ARBITRUM_RPC_URL } = require("./secret.json");
const { BASE_RPC_URL } = require("./secret.json");

const { API_KEY_ETHERSCAN } = require("./secret.json");
const { API_KEY_ARBISCAN } = require("./secret.json");
const { API_KEY_BASESCAN } = require("./secret.json");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    ethereum:{
      url: ETHEREUM_RPC_URL,
      accounts: [PRIVATE_KEY]
    },
    arb:{
      url: ARBITRUM_RPC_URL,
      accounts: [PRIVATE_KEY]
    },
    base:{
      url: BASE_RPC_URL,
      accounts: [PRIVATE_KEY]
    },
  },
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200 
      },
      viaIR: true
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
    apiKey: {
      eth: API_KEY_ETHERSCAN,
      arb: API_KEY_ARBISCAN,
      base: API_KEY_BASESCAN
    }
  }
};