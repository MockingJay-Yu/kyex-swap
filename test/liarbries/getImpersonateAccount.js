const { ethers } = require("hardhat");

async function getImpersonateAccount(impersonateAddr) {
  // 1. 启用冒充模式
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [impersonateAddr],
  });

  const [deployer] = await ethers.getSigners();
  await deployer.sendTransaction({
    to: impersonateAddr,
    value: ethers.parseEther("10"), // 发送 10 ETH
  });

  // 3. 获取冒充的 Signer
  const impersonatedSigner = await ethers.getSigner(impersonateAddr);

  return impersonatedSigner;
}
module.exports = { getImpersonateAccount };
