const { ethers, upgrades, network } = require("hardhat");
async function deployInterraVault() {
  const [deployer] = await ethers.getSigners();

  if (network.name == "base") {
    const InterraVaultFactory = await ethers.getContractFactory("InterraVault");
    const InterraVaultProxy = await upgrades.deployProxy(InterraVaultFactory);
    await InterraVaultProxy.waitForDeployment();
    const addr = await InterraVaultProxy.getAddress();
    console.log(addr);
  } else if (network.name == "hardhat") {
  }
}

module.exports = { deployInterraVault };
if (require.main === module) {
  deployInterraVault().then(() => process.exit(0));
}
