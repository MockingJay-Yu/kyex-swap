const { ethers, upgrades, network } = require("hardhat");

async function deployKyexSwap() {
  const [deployer] = await ethers.getSigners();

  if (network.name == "zeta_test") {
    const KYEXSwapZetaFactory = await ethers.getContractFactory("KYEXSwapZeta");
    const KYEXSwapZeta = await KYEXSwapZetaFactory.deploy();
    await KYEXSwapZeta.waitForDeployment();
    console.log(await KYEXSwapZeta.getAddress());
    const tx = await KYEXSwapZeta.initialize();
    await tx.wait(1);
    await KYEXSwapZeta.updateConfig(deployer.address, 600, 0, 0);
  } else if (network.name == "sepolia") {
    const KYEXSwapEVMFactory = await ethers.getContractFactory("KYEXSwapEVM");
    const KYEXSwapEVM = await KYEXSwapEVMFactory.deploy();
    await KYEXSwapEVM.waitForDeployment();
    console.log(await KYEXSwapEVM.getAddress());
    const tx = await KYEXSwapEVM.initialize();
    await tx.wait(1);
    await KYEXSwapEVM.updateConfig(deployer.address, 600, 0, 0);
    console.log(await KYEXSwapEVM.getAddress());
  } else if (network.name == "fork_zeta_test") {
    const KYEXSwapZetaFactory = await ethers.getContractFactory("KYEXSwapZeta");
    const KYEXSwapZeta = await KYEXSwapZetaFactory.deploy();
    await KYEXSwapZeta.waitForDeployment();
    console.log(await KYEXSwapZeta.getAddress());
    const tx = await KYEXSwapZeta.initialize();
    await tx.wait(1);
    await KYEXSwapZeta.updateConfig(deployer.address, 600, 0, 0);
    return {
      KYEXSwapZeta: KYEXSwapZeta,
      deployer: deployer,
    };
  }
}
module.exports = { deployKyexSwap };
if (require.main === module) {
  deployKyexSwap().then(() => process.exit(0));
}
