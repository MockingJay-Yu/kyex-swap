const { ethers, network, upgrades } = require("hardhat");

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
  } else {
    //hardhat
    const deployerAddr = await deployer.getAddress();
    console.log(deployerAddr);
    // deploy MockWZETA
    const MockWZETAFactory = await ethers.getContractFactory("WETH9");
    const MockWZETA = await MockWZETAFactory.deploy();
    await MockWZETA.waitForDeployment();
    const MockWZETAddr = await MockWZETA.getAddress();
    console.log("MockWZETA address:", MockWZETAddr);

    // deploy MockUniswapV2Router
    const uniswapV2Factory = await ethers.getContractFactory(
      "UniswapV2Factory"
    );
    const MockUniswapV2Factory = await uniswapV2Factory.deploy(deployerAddr);
    await MockUniswapV2Factory.waitForDeployment();
    const MockUniswapV2FactoryAddr = await MockUniswapV2Factory.getAddress();
    const MockUniswapV2RouterFactory = await ethers.getContractFactory(
      "TestUniswapRouter"
    );
    const MockUniswapV2Router = await MockUniswapV2RouterFactory.deploy(
      MockUniswapV2FactoryAddr,
      MockWZETAddr
    );
    await MockUniswapV2Router.waitForDeployment();
    const MockUniswapV2RouterAddr = await MockUniswapV2Router.getAddress();
    console.log("MockUniswapV2Router address:", MockUniswapV2RouterAddr);

    // deploy MockGatewayZEVM
    const MockGatewayZEVMFactory = await ethers.getContractFactory(
      "GatewayZEVM"
    );
    const MockGatewayZEVM = await MockGatewayZEVMFactory.deploy();
    await MockGatewayZEVM.waitForDeployment();
    const MockGatewayZEVMAddr = await MockGatewayZEVM.getAddress();
    console.log("MockGateway address:", MockGatewayZEVMAddr);

    // deploy KYEXSwapZetaTest proxy
    const KYEXSwapZetaTestFactory = await ethers.getContractFactory(
      "KYEXSwapZetaTest"
    );
    const KYEXSwapZetaTestProxy = await upgrades.deployProxy(
      KYEXSwapZetaTestFactory,
      [MockUniswapV2RouterAddr, MockGatewayZEVMAddr, MockWZETAddr]
    );
    await KYEXSwapZetaTestProxy.waitForDeployment();
    console.log(
      "KYEXSwapZetaProxy address:",
      await KYEXSwapZetaTestProxy.getAddress()
    );
    await KYEXSwapZetaTestProxy.updateConfig(deployerAddr, 600, 50, 50);
    return {
      MockWZETA: MockWZETA,
      MockUniswapV2Router: MockUniswapV2Router,
      MockUniswapV2Factory: MockUniswapV2Factory,
      MockGatewayZEVM: MockGatewayZEVM,
      KYEXSwapZetaTestProxy: KYEXSwapZetaTestProxy,
    };
  }
}
module.exports = { deployKyexSwap };
if (require.main === module) {
  deployKyexSwap().then(() => process.exit(0));
}
