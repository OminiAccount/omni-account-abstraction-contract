require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require('dotenv').config();
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    sepolia: {
      url: process.env.SepoliaAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    vizing_sepolia: {
      url: process.env.VizingTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    arb_sepolia: {
      url: process.env.ArbitrumTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    op_sepolia: {
      url: process.env.OptimsimTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    base_sepolia: {
      url: process.env.BaseTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    blast_sepolia: {
      url: process.env.BlastTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    zksync_sepolia: {
      url: process.env.ZkSyncTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    taiko_sepolia: {
      url: process.env.TaikoTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    scoll_sepolia: {
      url: process.env.ScrollTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    linea_sepolia: {
      url: process.env.LineaTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    polygon_zkevm_sepolia: {
      url: process.env.PolygonzkEVMTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    bob_sepolia: {
      url: process.env.BobTestnetAPIKEY,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },

    mainnet: {
      url: process.env.Ethereum,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    vizing: {
      url: process.env.Vizing,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    arbitrum: {
      url: process.env.Arbitrum,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    op: {
      url: process.env.Optimsim,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    base: {
      url: process.env.Base,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    blast: {
      url: process.env.Blast,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    zksync: {
      url: process.env.ZkSync,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    taiko: {
      url: process.env.Taiko,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    scoll: {
      url: process.env.Scroll,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    linea: {
      url: process.env.Linea,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    polygon_zkevm: {
      url: process.env.PolygonzkEVM,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
    },
    bob: {
      url: process.env.Bob,
      accounts: [process.env.Deploy_Testnet_Private_Key, process.env.TestNet_Private_key, process.env.PRIVATE_KEY]
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
