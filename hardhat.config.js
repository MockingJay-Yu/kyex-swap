require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */

const user1 =
  "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
const deployer =
  "0x19f669c8276dd9e37a18ea90b97896a02e69e8d063d96a2ef978115f5691c9ba";

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
      forking: {
        url: "https://zetachain-athens.g.allthatnode.com/archive/evm/e6f4078993be427386b109445e004b31",
      },
      accounts: [
        { privateKey: deployer, balance: "1000000000000000000000" }, // 1000 ETH
        { privateKey: user1, balance: "1000000000000000000000" },
      ],
    },
    fork_zeta_test: {
      forking: {
        url: "https://zetachain-athens.g.allthatnode.com/archive/evm/e6f4078993be427386b109445e004b31",
      },
      accounts: [
        { privateKey: deployer, balance: "1000000000000000000000" }, // 1000 ETH
        { privateKey: user1, balance: "1000000000000000000000" },
      ],
    },
    zeta_test: {
      url: "https://zetachain-athens.g.allthatnode.com/archive/evm/e6f4078993be427386b109445e004b31",
      accounts: [deployer],
    },
  },
};
