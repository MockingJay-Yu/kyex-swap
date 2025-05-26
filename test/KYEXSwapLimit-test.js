const { ethers } = require("hardhat");

async function test() {
  const [deployer] = await ethers.getSigners();
  const limit = await ethers.getContractAt(
    "KYEXLimitOrder",
    "0xd9E142079932c33fBf29C070658930cA59f5d642"
  );
  console.log(await limit.platformFee());
  console.log(await limit.orders(2));
  // const erc20 = await ethers.getContractAt(
  //   "ERC20",
  //   "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"
  // );
  // const tx1 = await erc20.approve(
  //   "0x7FD9eA43437203381DBce5732dA2fBD430976782",
  //   ethers.parseUnits("0.5", 6)
  // );
  // await tx1.wait();
  // const gasFee = ethers.parseUnits("0.00007", 18);

  // const order = {
  //   fromToken: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  //   fromChainId: 8453,
  //   amountIn: ethers.parseUnits("0.01", 6),
  //   toChainId: 137,
  //   toToken: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
  //   recipient: "0xC189CFc2710E620abd5768A7D8E178ccCDE7E3D2",
  //   expiry: 1844195597,
  //   amountOut: ethers.parseUnits("0.05", 18),
  //   gasFee: gasFee,
  // };

  // for (let i = 0; i < 21; i++) {
  //   const tx = await limit.openOrder(order, {
  //     value: gasFee,
  //   });
  //   console.log(i);
  // }
  // const receipt = await tx.wait();
  // const event = receipt.events.find((e) => e.event === "OpenOrder");
  // console.log("orderId:", event.args.orderId);
  // const tx = await limit.cancelOrder(11);
  // console.log(tx);
}

module.exports = { test };
if (require.main === module) {
  test().then(() => process.exit(0));
}
