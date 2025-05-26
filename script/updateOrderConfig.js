const { ethers, network } = require("hardhat");
async function updateDCAOrderConfig() {
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
    const KYEXLimitOrder = await ethers.getContractAt(
      "KYEXLimitOrder",
      "0x65aE6A04993aebc5d292C89a177484359C9eE225"
    );
    const re = await KYEXLimitOrder.orders(1);
    // const tx = await KYEXDCAOrder.updateTreasury(
    //   "0x1ED8D0cfCd6A6FDeC8BAcc2c5c12532dDb730113"
    // );
    console.log(re);
  }
}

module.exports = { updateDCAOrderConfig };
if (require.main === module) {
  updateDCAOrderConfig().then(() => process.exit(0));
}
