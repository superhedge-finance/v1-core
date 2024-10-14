require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-etherscan");
const apiKey = ""
const privateKey = ""
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "arb",
  networks: {
    arb:{
      // url: "https://rpc.ankr.com/arbitrum",
      // url: "https://endpoints.omniatech.io/v1/arbitrum/one/public",
      url:'https://arbitrum-mainnet.infura.io/v3/de2c1ced559c453e86d2cf05b4c5e35b',
      // chainId: 42161,
      // gasPrice: 200000,
      accounts: [privateKey]
    },
  },
  solidity: {
    version: "0.8.23",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200 
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
