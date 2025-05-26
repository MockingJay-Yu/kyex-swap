require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("./task/batchSwap");

/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
  solidity: {
    compilers: [
      { version: "0.6.6" /** For uniswap v2 */ },
      { version: "0.8.7" },
      { version: "0.5.10" /** For create2 factory */ },
      { version: "0.5.16" /** For uniswap v2 core*/ },
      { version: "0.4.19" /** For weth*/ },
      { version: "0.8.18" /** For IKYEXSpotFactoryV1*/ },
      { version: "0.8.20" /** For KYEXSwap01*/ },
      { version: "0.8.26" /** For zetaV2*/ },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
      viaIR: true,
    },
  },

  networks: {
    hardhat: {
      chainId: 31337,
    },
    sepolia: {
      url: process.env.RPC_SEPOLIA,
      accounts: [process.env.PRIVATE_KEY_TESTNET],
    },
    zeta: {
      url: process.env.RPC_ZETA_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    bnb: {
      url: process.env.RPC_BNB_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    bnb_test: {
      url: process.env.RPC_BNB_MAINNET,
      accounts: [process.env.PRIVATE_KEY_TESTNET],
    },
    base: {
      url: process.env.RPC_BASE_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    eth: {
      url: process.env.RPC_ETH_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    polygon: {
      url: process.env.RPC_POLYGON_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    arb: {
      url: process.env.RPC_ARB_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    avax: {
      url: process.env.RPC_AVAX_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    optimism: {
      url: process.env.RPC_OPTIMISM_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    blast: {
      url: process.env.RPC_BLAST_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    filecoin: {
      url: process.env.RPC_FILECOIN_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    scroll: {
      url: process.env.RPC_SCROLL_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    fantom: {
      url: process.env.RPC_FANTOM_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    celo: {
      url: process.env.RPC_CELO_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    imx: {
      url: process.env.RPC_IMX_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    linea: {
      url: process.env.RPC_LINEA_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
    mantle: {
      url: process.env.RPC_MANTLE_MAINNET,
      accounts: [process.env.PRIVATE_KEY_MAINNET],
    },
  },
  etherscan: {
    apiKey: {
      bnb: process.env.SCAN_APIKEY_BNB,
      base: process.env.SCAN_APIKEY_BASE,
    },
  },
};
