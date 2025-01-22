const { ethers, upgrades, network } = require("hardhat");

async function deployKyexSwapProxy() {
  const [deployer] = await ethers.getSigners();

  if (network.name == "zeta") {
    const KYEXSwapZetaFactory = await ethers.getContractFactory("KYEXSwapZeta");
    const KYEXSwapZetaProxy = await upgrades.deployProxy(
      KYEXSwapZetaFactory,
      [],
      { initializer: "initialize" }
    );
    await KYEXSwapZetaProxy.waitForDeployment();
    console.log(await KYEXSwapZetaProxy.getAddress());
    await KYEXSwapZetaProxy.updateConfig(
      "0x09bd7e006734a022cad1cf49a41026be9a9e1eb8",
      600,
      50,
      50
    );
  }
}
module.exports = { deployKyexSwapProxy };
if (require.main === module) {
  deployKyexSwapProxy().then(() => process.exit(0));
}
