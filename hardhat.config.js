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
      chainId: 1337,
      accounts: [
        {
          privateKey: deployer,
          balance: "1000000000000000000000",
        },
        {
          privateKey: user,
          balance: "1000000000000000000000",
        },
      ],
    },
    zeta_test: {
      url: "https://zetachain-athens.g.allthatnode.com/archive/evm/e6f4078993be427386b109445e004b31",
      accounts: [deployer],
    },
    sepolia: {
      url: "https://ethereum-sepolia.g.allthatnode.com/full/evm/e6f4078993be427386b109445e004b31",
      accounts: [deployer],
    },
    zeta: {
      url: "https://zetachain-mainnet.g.allthatnode.com/full/evm/e6f4078993be427386b109445e004b31",
      accounts: [deployer],
    },
    bsc: {
      url: "https://bsc-mainnet.g.allthatnode.com/full/evm/e6f4078993be427386b109445e004b31",
      accounts: [deployer],
    },
    bsc_test: {
      url: "https://bsc-testnet.g.allthatnode.com/full/evm/e6f4078993be427386b109445e004b31",
      accounts: [deployer],
    },
    base: {
      url: "https://base-mainnet.g.allthatnode.com/full/evm/e6f4078993be427386b109445e004b31",
      accounts: [deployer],
    },
    eth: {
      url: "https://eth-mainnet.nodereal.io/v1/1659dfb40aa24bbb8153a677b98064d7",
      accounts: [deployer],
    },
    polygon: {
      url: "https://polygon-mainnet.g.allthatnode.com/full/evm/e6f4078993be427386b109445e004b31",
      accounts: [deployer],
    },
    sol_test: {
      url: "https://solana-mainnet.g.allthatnode.com/full/json_rpc/e6f4078993be427386b109445e004b31",
      accounts: [deployer],
    },
  },
  etherscan: {
    apiKey: {
      bsc: "BG8P7926NRRPDQ8ZZ47RNTGZRMHZ76TW3A", // 将你的 API 密钥放在这里
    },
  },
};
