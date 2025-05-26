const { ethers, network } = require("hardhat");

async function deployDCAOrder() {
  const [deployer] = await ethers.getSigners();
  if (
    network.name == "bnb" ||
    network.name == "base" ||
    network.name == "polygon" ||
    network.name == "arb" ||
    network.name == "avax" ||
    network.name == "optimism" ||
    network.name == "blast" ||
    network.name == "filecoin" ||
    network.name == "scroll" ||
    network.name == "fantom" ||
    network.name == "celo" ||
    network.name == "imx" ||
    network.name == "linea" ||
    network.name == "mantle"
  ) {
    const KYEXDCAOrderFactory = await ethers.getContractFactory("KYEXDCAOrder");
    const KYEXDCAOrderProxy = await upgrades.deployProxy(KYEXDCAOrderFactory, [
      50,
      "0x1ED8D0cfCd6A6FDeC8BAcc2c5c12532dDb730113",
    ]);
    await KYEXDCAOrderProxy.waitForDeployment();
    const addr = await KYEXDCAOrderProxy.getAddress();
    console.log(addr);
  } else if (network.name == "hardhat") {
    const KYEXDCAOrderFactory = await ethers.getContractFactory("KYEXDCAOrder");
    const KYEXDCAOrder = await KYEXDCAOrderFactory.deploy();
    await KYEXDCAOrder.waitForDeployment();
    await KYEXDCAOrder.initialize(50, deployer.address);

    const MockERC20Factory = await ethers.getContractFactory("MockERC20");
    const MockERC20 = await MockERC20Factory.deploy(
      1000,
      "MockERC20",
      "MOCKERC20"
    );
    await MockERC20.waitForDeployment();
    return { KYEXDCAOrder, MockERC20 };
  }
}
module.exports = { deployDCAOrder };
if (require.main === module) {
  deployDCAOrder().then(() => process.exit(0));
}
