const axios = require("axios");

// async function batchSwap(counts, privatekey) {
//   const signer = new ethers.Wallet(privatekey, ethers.provider);
//   for (let i = 0; i < counts; i++) {
//     const amountIn = ethers.parseUnits("0.08", 18);
//     const nativeTokenVolume = ethers.parseUnits("0.08", 18);

//     const swapDetail = {
//       sourceChainSwapPath: ethers.solidityPacked(
//         ["address"],
//         ["0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"]
//       ),
//       zetaChainSwapPath: [
//         "0x48f80608B672DC30DC7e3dbBd0343c5F02C738Eb",
//         "0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf",
//         "0xADF73ebA3Ebaa7254E859549A44c74eF7cff7501",
//       ],
//       targetChainSwapPath: ethers.solidityPacked(
//         ["address"],
//         ["0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"]
//       ),
//       gasZRC20SwapPath: ["0xADF73ebA3Ebaa7254E859549A44c74eF7cff7501"],
//       recipient: ethers.solidityPacked(
//         ["address"],
//         ["0xC189CFc2710E620abd5768A7D8E178ccCDE7E3D2"]
//       ),
//       sender: ethers.solidityPacked(
//         ["address"],
//         ["0xC189CFc2710E620abd5768A7D8E178ccCDE7E3D2"]
//       ),
//       omnichainSwapContract: "0x",
//       chainId: 56,
//       minAmountOut: 0,
//     };
//     const SwapContract = await ethers.getContractAt(
//       "KYEXSwapEVM",
//       "0x8B006b1AEd06a93430022F45408FD5D238ca60ac",
//       signer
//     );
//     try {
//       const tx = await SwapContract.swap(
//         amountIn,
//         nativeTokenVolume,
//         swapDetail,
//         { value: amountIn }
//       );
//       await tx.wait();
//       console.log(i);
//       console.log(tx.hash);
//       const url = "https://kyex.io/kyex/chain/order/swap";
//       const body = {
//         sender: swapDetail.sender,
//         txHash: tx.hash,
//         fromCoinCode: "BNB",
//         fromChainId: "56",
//         toCoinCode: "POL",
//         toChainId: "137",
//         recipient: swapDetail.recipient,
//         omnichainSwapContract: swapDetail.omnichainSwapContract,
//         minAmountOut: swapDetail.minAmountOut,
//         nativeTokenVolume: "0.08",
//         amountIn: "0.08",
//       };
//       const response = await axios.post(url, body);
//     } catch (error) {
//       console.error("Error during transfer:", error);
//     }
//   }
// }

async function batchSwap(counts, privatekey) {
  const signer = new ethers.Wallet(privatekey, ethers.provider);
  for (let i = 0; i < counts; i++) {
    const amountIn = ethers.parseUnits("150", 18);
    const nativeTokenVolume = ethers.parseUnits("150", 18);

    const swapDetail = {
      sourceChainSwapPath: ethers.solidityPacked(
        ["address"],
        ["0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"]
      ),
      zetaChainSwapPath: [
        "0xADF73ebA3Ebaa7254E859549A44c74eF7cff7501",
        "0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf",
        "0x48f80608B672DC30DC7e3dbBd0343c5F02C738Eb",
      ],
      targetChainSwapPath: ethers.solidityPacked(
        ["address"],
        ["0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"]
      ),
      gasZRC20SwapPath: ["0x48f80608B672DC30DC7e3dbBd0343c5F02C738Eb"],
      recipient: ethers.solidityPacked(
        ["address"],
        ["0xC189CFc2710E620abd5768A7D8E178ccCDE7E3D2"]
      ),
      sender: ethers.solidityPacked(
        ["address"],
        ["0xC189CFc2710E620abd5768A7D8E178ccCDE7E3D2"]
      ),
      omnichainSwapContract: "0x",
      chainId: 56,
      minAmountOut: 0,
    };
    const SwapContract = await ethers.getContractAt(
      "KYEXSwapEVM",
      "0x2bbE7be62888049fc0355F27BDa0FB7aE71263F1",
      signer
    );
    try {
      const tx = await SwapContract.swap(
        amountIn,
        nativeTokenVolume,
        swapDetail,
        { value: amountIn }
      );
      await tx.wait();
      console.log(i);
      console.log(tx.hash);
      const url = "https://kyex.io/kyex/chain/order/swap";
      const body = {
        sender: swapDetail.sender,
        txHash: tx.hash,
        fromCoinCode: "POL",
        fromChainId: "137",
        toCoinCode: "BNB",
        toChainId: "56",
        recipient: swapDetail.recipient,
        omnichainSwapContract: swapDetail.omnichainSwapContract,
        minAmountOut: swapDetail.minAmountOut,
        nativeTokenVolume: "150",
        amountIn: "150",
      };
      const response = await axios.post(url, body);
    } catch (error) {
      console.error("Error during transfer:", error);
    }
  }
}
task("batchSwap", "Runs the batchSwap function")
  .addParam("counts", "The number of transfer")
  .addParam("privatekey", "The private of wallet using this task")
  .setAction(async ({ counts, privatekey }) => {
    await batchSwap(counts, privatekey);
    console.log("batchswap successful!");
  });

module.exports = {};
