const { ethers } = require("hardhat");

async function test() {
  const [deployer] = await ethers.getSigners();

  const limit = await ethers.getContractAt(
    "KYEXLimitOrder",
    "0x272B108F19C1Bb19aC4FAe3799803496cE01809B"
  );
  // await limit.initialize();
  // const tx = await limit.updateNativeToken(
  //   8453,
  //   "0x4200000000000000000000000000000000000006"
  // );
  // tx.wait(1);
  // console.log(await limit.nativeTokens(8453));

  // const weth = await ethers.getContractAt(
  //   "WETH9",
  //   "0x4200000000000000000000000000000000000006"
  // );
  const amountIn = ethers.parseUnits("0.0005", 18);
  const gasFee = ethers.parseUnits("0.0001", 18);

  // const tx = await weth.approve(
  //   "0x276182707b21f9D78B33097f9B4Da36950c0126B",
  //   amountIn
  // );
  // tx.wait(1);

  const order = {
    fromToken: ethers.ZeroAddress,
    fromChainId: 8453,
    amountIn: amountIn,
    toChainId: 56,
    toToken: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
    recipient: "0x4e8A3Ff8daD9Fa3BCaCF9f282E4bd1BD3ef865dD",
    amountOut: amountIn,
    amountOutMin: amountIn,
    expiry: amountIn,
    sender: "0x4e8A3Ff8daD9Fa3BCaCF9f282E4bd1BD3ef865dD",
    gasFee: gasFee,
  };
  const tx = await limit.openOrder(order, { value: amountIn + gasFee });
  console.log(tx);
}

module.exports = { test };
if (require.main === module) {
  test().then(() => process.exit(0));
}
