const { ethers } = require("hardhat");

async function test() {
  const uniswap = await ethers.getContractAt(
    "IUniswapV2Router02",
    "0x2ca7d64A7EFE2D62A725E2B35Cf7230D6677FfEe"
  );
  const zrc20 = await ethers.getContractAt(
    "IZRC20",
    "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891"
  );
  // const gasLimit = await zrc20.GAS_LIMIT();
  // const fee = await zrc20.withdrawGasFeeWithGasLimit(gasLimit);
  // const fee = await zrc20.withdrawGasFee();
  // console.log(fee);
  await zrc20.approve(
    "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891",
    ethers.parseUnits("79", 13)
  );
  const amount = await uniswap.swapExactTokensForTokens(
    ethers.parseUnits("79", 13),
    0,
    [
      "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891",
      "0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf",
      "0x65a45c57636f9BcCeD4fe193A602008578BcA90b",
    ],
    "0x670f4f034B5e9B01580F888741d129866bBB2cC3",
    Math.floor(Date.now() / 1000) + 60 * 10
  );
  console.log(amount);

  // console.log(amount1);

  // console.log(amount[0]);
  // console.log(amount[1]);
  // console.log(amount[2]);
  // const [deployer] = await ethers.getSigners();

  //   const sas = await ethers.getContractAt(
  //     "KYEXSwapEVM",
  //     "0xC73CEAeF7F31e3b67f5F371AC1AF821Bd15e4EfF"
  //   );
  //   await sas.updateConfig(deployer.address, 600, 0, 0);
}

module.exports = { test };
if (require.main === module) {
  test().then(() => process.exit(0));
}
