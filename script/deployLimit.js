const { ethers, network } = require("hardhat");

async function deployKyexSwapLimit() {
  const [deployer] = await ethers.getSigners();
  if (
    network.name == "bsc" ||
    network.name == "hardhat" ||
    network.name == "sepolia" ||
    network.name == "base" ||
    network.name == "polygon"
  ) {
    const KYEXLimitOrderFactory = await ethers.getContractFactory(
      "KYEXLimitOrder"
    );
    // console.log(11111);
    const KYEXLimitOrder = await KYEXLimitOrderFactory.deploy();
    await KYEXLimitOrder.waitForDeployment();
    await KYEXLimitOrder.initialize(50);
    const addr = await KYEXLimitOrder.getAddress();
    console.log(addr);
  }
}
module.exports = { deployKyexSwapLimit };
if (require.main === module) {
  deployKyexSwapLimit().then(() => process.exit(0));
}
