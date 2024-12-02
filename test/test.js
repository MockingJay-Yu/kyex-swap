const { ethers } = require("hardhat");
const { AbiCoder } = ethers;
const abiCoder = new AbiCoder();

async function test() {
  const [deployer] = await ethers.getSigners();

  const KYEXSwapEVM = await ethers.getContractAt(
    "KYEXSwapEVM",
    "0xC3fE5e9d6A73945cA31bf8B3573B3076a36bFfE2"
  );
  console.log(await KYEXSwapEVM.getAddress());
  const amountIn = ethers.parseUnits("0.1", 18);
  const swapDetail = {
    sourceChainSwapPath: abiCoder.encode(
      ["address"],
      ["0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9"]
    ),
    zetaChainSwapPath: [
      "0xd97B1de3619ed2c6BEb3860147E30cA8A7dC9891", //bnb
      "0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf", //zeta
      "0xcC683A782f4B30c138787CB5576a86AF66fdc31d", //usdc
    ],
    targetChainSwapPath: abiCoder.encode(
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
  const tx = await KYEXSwapEVM.swap(amountIn, swapDetail, { value: amountIn });
  console.log(tx);
}

module.exports = { test };
if (require.main === module) {
  test().then(() => process.exit(0));
}
