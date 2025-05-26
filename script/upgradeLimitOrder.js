const { ethers, upgrades, network } = require("hardhat");

async function upgradeLimitOrder() {
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
    const KYEXLimitOrderFactory = await ethers.getContractFactory(
      "KYEXLimitOrder"
    );
    const upgraded = await upgrades.upgradeProxy(
      "0xd9E142079932c33fBf29C070658930cA59f5d642",
      KYEXLimitOrderFactory
    );
    console.log("upgraded to:", upgraded.address);
  }
}

module.exports = { upgradeLimitOrder };
if (require.main === module) {
  upgradeLimitOrder().then(() => process.exit(0));
}
