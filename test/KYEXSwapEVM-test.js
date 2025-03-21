const { ethers } = require("hardhat");
const { expect } = require("chai");
const { deployKyexSwap } = require("../script/deploy.js");
const { createUniswapV2Pair } = require("./libraries/createUniswapV2Pair.js");
const {
  getImpersonateAccount,
} = require("./liarbries/getImpersonateAccount.js");

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const [deployer, user] = await ethers.getSigners();

///////////////////
// Test swap
///////////////////
describe("Test onCall", function () {
  it("zetaPathLength == 0", async function () {
    const {
      MockWZETA,
      MockUniswapV2Router,
      MockUniswapV2Factory,
      MockGatewayZEVM,
      KYEXSwapZetaTestProxy,
    } = await loadFixture(deployKyexSwap);

    const MockZRC20Factory = await ethers.getContractFactory("MockZRC20");
    const MockZRC20USDC = await MockZRC20Factory.deploy(500, "USDC", "USDC");
    const MockZRC20ETH = await MockZRC20Factory.deploy(400, "ETH", "ETH");
    createUniswapV2Pair(
      deployer,
      MockUniswapV2Router,
      MockUniswapV2Factory,
      MockZRC20USDC,
      MockZRC20ETH
    );
    const protocolAddr = await MockGatewayZEVM.PROTOCOL_ADDRESS();
    const protocolAccount = await getImpersonateAccount(protocolAddr);

    const swapDetail = {
      sourceChainSwapPath: ethers.solidityPacked(
        ["address", "uint24", "address"],
        [
          "0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9",
          10000,
          "0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238",
        ]
      ),
      zetaChainSwapPath: [],
      targetChainSwapPath: "0x",
      gasZRC20SwapPath: [],
      gasFee: 0,
      recipient: deployer.address,
      omnichainSwapContract: "0x",
      chainId: 0,
    };
    console.log(swapDetail);
    const amountIn = ethers.parseUnits("0.1", 18);
    const tx = await KYEXSwapEVM.swap(amountIn, swapDetail, {
      value: amountIn,
    });

    expect(tx)
      .to.emit(KYEXSwapZeta, "ReceivedToken")
      .withArgs(
        deployer.address,
        "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891",
        amountIn
      );
  });
});
