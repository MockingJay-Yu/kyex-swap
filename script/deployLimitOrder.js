const { ethers, upgrades, network } = require("hardhat");
async function deployLimitOrder() {
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
    network.name == "mantle" ||
    network.name == "linea"
  ) {
    const KYEXLimitOrderFactory = await ethers.getContractFactory(
      "KYEXLimitOrder"
    );
    const KYEXLimitOrderProxy = await upgrades.deployProxy(
      KYEXLimitOrderFactory,
      [50, "0x1ED8D0cfCd6A6FDeC8BAcc2c5c12532dDb730113"]
    );
    await KYEXLimitOrderProxy.waitForDeployment();
    const addr = await KYEXLimitOrderProxy.getAddress();
    console.log(addr);
  } else if (network.name == "hardhat") {
    const KYEXLimitOrderFactory = await ethers.getContractFactory(
      "KYEXLimitOrder"
    );
    const KYEXLimitOrder = await KYEXLimitOrderFactory.deploy();
    await KYEXLimitOrder.waitForDeployment();
    await KYEXLimitOrder.initialize(50, deployer.address);

    const MockERC20Factory = await ethers.getContractFactory("MockERC20");
    const MockERC20 = await MockERC20Factory.deploy(
      1000,
      "MockERC20",
      "MOCKERC20"
    );
    await MockERC20.waitForDeployment();
    console.log(await MockERC20.getAddress());
    return { KYEXLimitOrder, MockERC20 };
  }
}
module.exports = { deployLimitOrder };
if (require.main === module) {
  deployLimitOrder().then(() => process.exit(0));
}
