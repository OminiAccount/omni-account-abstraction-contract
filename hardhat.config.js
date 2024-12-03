require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require('dotenv').config();
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    sepolia: {
      url: process.env.SepoliaAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    vizing_sepolia: {
      url: process.env.VizingTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    arb_sepolia: {
      url: process.env.ArbitrumTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    op_sepolia: {
      url: process.env.OptimsimTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    base_sepolia: {
      url: process.env.BaseTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    blast_sepolia: {
      url: process.env.BlastTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    zksync_sepolia: {
      url: process.env.ZkSyncTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    taiko_sepolia: {
      url: process.env.TaikoTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    scoll_sepolia: {
      url: process.env.ScrollTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    linea_sepolia: {
      url: process.env.LineaTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    polygon_zkevm_sepolia: {
      url: process.env.PolygonzkEVMTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    bob_sepolia: {
      url: process.env.BobTestnetAPIKEY,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },

    mainnet: {
      url: process.env.Ethereum,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    vizing: {
      url: process.env.Vizing,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    arbitrum: {
      url: process.env.Arbitrum,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    op: {
      url: process.env.Optimsim,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    base: {
      url: process.env.Base,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    blast: {
      url: process.env.Blast,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    zksync: {
      url: process.env.ZkSync,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    taiko: {
      url: process.env.Taiko,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    scoll: {
      url: process.env.Scroll,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    linea: {
      url: process.env.Linea,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    polygon_zkevm: {
      url: process.env.PolygonzkEVM,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
    bob: {
      url: process.env.Bob,
      accounts: [process.env.PRIVATE_KEY, process.env.TestNet_Private_key]
    },
  },
  solidity: {
    compilers:[
      {version: "0.8.24"},
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  gasReporter: {
    enabled: true,  
    currency: 'ETH',  
    // coinmarketcap: 'YOUR_API_KEY',
    outputFile: 'gas-report.txt', 
    noColors: true 
  },
  // etherscan: {
  //   apiKey: 
  // },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 10000
  }
};
