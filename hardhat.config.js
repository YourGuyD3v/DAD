const { version } = require('chai');

/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("@nomiclabs/hardhat-solhint");
require("dotenv").config()

/** @type import('hardhat/config').HardhatUserConfig */

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || ""
const PRIVATE_KEY = process.env.PRIVATE_KEY || ""
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""

module.exports = {

  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      blockConfirmations: 1
    },
    localhost: {
      chainId: 31337
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
      blockConfirmations: 6
    },
  },
  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_API_KEY
    }
  },
  namedAccounts: {
    deployer: {
        default: 0,
        1: 0, 
    },
    player: {
      default: 1,
  },
  },
  gasReporter: {
    enabled: false,
    currency: "USD",
    outputFile: "Gas-Reporter.txt",
    noColor: true,
    // coinMarketcap: COINMARKETCAP_API_KEY
  },
  contractSizer: {
    runOnCompile: false,
    only: ["Raffle"],
},
solidity: {
  compilers: [
    {
        version: "0.8.7",
    },
    {
        version: "0.6.6",
    },
    {
        version: "0.4.24",
    },
],
  settings: {
    viaIR: true,
    optimizer: {
      enabled: true,
      details: {
        yulDetails: {
          optimizerSteps: "u",
        },
      },
    },
  },
},
  mocha: {
    timeout: 500000, // 500 seconds max for running tests
  }
};