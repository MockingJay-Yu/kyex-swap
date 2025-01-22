const { ethers, network } = require("hardhat");

async function deployKyexSwap() {
  const [deployer] = await ethers.getSigners();

  if (network.name == "zeta" || network.name == "zeta_test") {
    const KYEXSwapZetaFactory = await ethers.getContractFactory("KYEXSwapBTC");
    const KYEXSwapZeta = await KYEXSwapZetaFactory.deploy();
    await KYEXSwapZeta.waitForDeployment();
    console.log(await KYEXSwapZeta.getAddress());
    const tx = await KYEXSwapZeta.initialize();
    await tx.wait(1);
    await KYEXSwapZeta.updateConfig(
      "0x09bd7e006734a022cad1cf49a41026be9a9e1eb8",
      600,
      50,
      50
    );
  } else if (
    network.name == "bsc" ||
    network.name == "base" ||
    network.name == "eth" ||
    network.name == "polygon" ||
    network.name == "bsc_test" ||
    network.name == "sepolia"
  ) {
    const KYEXSwapEVMFactory = await ethers.getContractFactory("KYEXSwapEVM");
    const KYEXSwapEVM = await KYEXSwapEVMFactory.deploy();
    await KYEXSwapEVM.waitForDeployment();
    console.log(await KYEXSwapEVM.getAddress());
    const tx = await KYEXSwapEVM.initialize();
    await tx.wait(1);
    await KYEXSwapEVM.updateConfig(
      "0x09bd7e006734a022cad1cf49a41026be9a9e1eb8",
      600,
      50,
      50
    );
  }
}
module.exports = { deployKyexSwap };
if (require.main === module) {
  deployKyexSwap().then(() => process.exit(0));
}
