const { ethers } = require("hardhat");
const { expect } = require("chai");
const { deployKyexSwap } = require("../script/deploy.js");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

///////////////////
// Test swap
///////////////////
describe("Test Swap", function () {
  it("zetaPathLength == 3 && gasZRC20PathLength == 3", async function () {
    const { KYEXSwapZeta, deployer } = await loadFixture(deployKyexSwap);
    const KYEXSwapZetaAddr = await KYEXSwapZeta.getAddress();
    const swapDetail = {
      sourceChainSwapPath: "0x",
      zetaChainSwapPath: [
        "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891", //bnb
        "0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf", //zeta
        "0xcC683A782f4B30c138787CB5576a86AF66fdc31d", //usdc
      ],
      targetChainSwapPath: ethers.solidityPacked(
        ["address"],
        ["0xcC683A782f4B30c138787CB5576a86AF66fdc31d"] //usdc
      ),
      gasZRC20SwapPath: [
        "0xcC683A782f4B30c138787CB5576a86AF66fdc31d", //usdc
        "0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf", //zeta
        "0x05BA149A7bd6dC1F937fA9046A9e05C05f3b18b0", //eth
      ],
      gasFee: ethers.parseUnits("0.1", 18),
      recipient: deployer.address,
      omnichainSwapContract: "0x",
      chainId: 0,
    };
    console.log(swapDetail);
    const uniswap = await ethers.getContractAt(
      "IUniswapV2Router02",
      "0x2ca7d64A7EFE2D62A725E2B35Cf7230D6677FfEe"
    );
    const path = [
      "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891",
      "0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf",
    ];
    const returnData = await uniswap.getAmountsOut(
      ethers.parseUnits("1", 18),
      path
    );
    console.log(returnData);
    const amountIn = ethers.parseUnits("1", 18);
    const bnb = await ethers.getContractAt(
      "IZRC20",
      "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891"
    );
    await bnb.approve(KYEXSwapZetaAddr, amountIn);
    const tx = await KYEXSwapZeta.swap(amountIn, swapDetail);

    expect(tx)
      .to.emit(KYEXSwapZeta, "ReceivedToken")
      .withArgs(
        deployer.address,
        "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891",
        amountIn
      );
  });
});
