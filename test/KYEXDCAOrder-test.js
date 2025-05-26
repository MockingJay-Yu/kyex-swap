const { ethers } = require("hardhat");
const { expect } = require("chai");
const { deployDCAOrder } = require("../script/deployDCAOrder");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("openOrder", async function () {
  it("Should revert if amountIn equals zero", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();

    await MockERC20.approve(
      await KYEXLimitOrder.getAddress(),
      ethers.parseUnits("100", 18)
    );
    const openOrderParam = {
      fromToken: await MockERC20.getAddress(),
      fromChainId: 31337,
      amountIn: 0,
      toChainId: 21,
      toToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
      recipient: deployer.address,
      expiry: Math.floor(Date.now() / 1000) + 60 * 60,
      amountOut: ethers.parseUnits("100", 18),
      gasFee: ethers.parseUnits("0.001", 18),
    };
    await expect(
      KYEXLimitOrder.openOrder(openOrderParam)
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "InvalidParameter");
  });
  it("Should revert if gasFee does not match msg.value when fromToken is not the native token", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();

    await MockERC20.approve(
      await KYEXLimitOrder.getAddress(),
      ethers.parseUnits("100", 18)
    );
    const openOrderParam = {
      fromToken: await MockERC20.getAddress(),
      fromChainId: 31337,
      amountIn: ethers.parseUnits("100", 18),
      toChainId: 21,
      toToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
      recipient: deployer.address,
      expiry: Math.floor(Date.now() / 1000) + 60 * 60,
      amountOut: ethers.parseUnits("100", 18),
      gasFee: ethers.parseUnits("0.001", 18),
    };
    await expect(
      KYEXLimitOrder.openOrder(openOrderParam, {
        value: ethers.parseUnits("0.002", 18),
      })
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "GasFeeMismatch");
  });
  it("Should revert if msg.value is zero when fromToken is not the native token", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();

    await MockERC20.approve(
      await KYEXLimitOrder.getAddress(),
      ethers.parseUnits("100", 18)
    );
    const openOrderParam = {
      fromToken: await MockERC20.getAddress(),
      fromChainId: 31337,
      amountIn: ethers.parseUnits("100", 18),
      toChainId: 21,
      toToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
      recipient: deployer.address,
      expiry: Math.floor(Date.now() / 1000) + 60 * 60,
      amountOut: ethers.parseUnits("100", 18),
      gasFee: ethers.parseUnits("0.001", 18),
    };
    await expect(
      KYEXLimitOrder.openOrder(openOrderParam)
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "GasFeeMismatch");
  });

  it("Should revert if allowance is less than amountIn when fromToken is not the native token", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();

    await MockERC20.approve(
      await KYEXLimitOrder.getAddress(),
      ethers.parseUnits("99", 18)
    );
    const openOrderParam = {
      fromToken: await MockERC20.getAddress(),
      fromChainId: 31337,
      amountIn: ethers.parseUnits("100", 18),
      toChainId: 21,
      toToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
      recipient: deployer.address,
      expiry: Math.floor(Date.now() / 1000) + 60 * 60,
      amountOut: ethers.parseUnits("100", 18),
      gasFee: ethers.parseUnits("0.001", 18),
    };
    await expect(
      KYEXLimitOrder.openOrder(openOrderParam, {
        value: ethers.parseUnits("0.001", 18),
      })
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "InsufficientAllowance");
  });

  it("Should revert if amountIn plus gasFee is less than msg.value when fromToken is the native token", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();

    const openOrderParam = {
      fromToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
      fromChainId: 31337,
      amountIn: ethers.parseUnits("100", 18),
      toChainId: 21,
      toToken: await MockERC20.getAddress(),
      recipient: deployer.address,
      expiry: Math.floor(Date.now() / 1000) + 60 * 60,
      amountOut: ethers.parseUnits("100", 18),
      gasFee: ethers.parseUnits("0.001", 18),
    };
    await expect(
      KYEXLimitOrder.openOrder(openOrderParam, {
        value: ethers.parseUnits("100", 18),
      })
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "InsufficientFunds");
  });

  it("Should emit the corresponding event and allow correct retrieval of order details when fromToken is not the native token", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();
    const expiry = Math.floor(Date.now() / 1000) + 60 * 60;

    await MockERC20.approve(
      await KYEXLimitOrder.getAddress(),
      ethers.parseUnits("100", 18)
    );
    const openOrderParam = {
      fromToken: await MockERC20.getAddress(),
      fromChainId: 31337,
      amountIn: ethers.parseUnits("100", 18),
      toChainId: 21,
      toToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
      recipient: deployer.address,
      expiry: expiry,
      amountOut: ethers.parseUnits("100", 18),
      gasFee: ethers.parseUnits("0.01", 18),
    };
    const tx = await KYEXLimitOrder.openOrder(openOrderParam, {
      value: ethers.parseUnits("0.01", 18),
    });
    await expect(tx)
      .to.emit(KYEXLimitOrder, "ReceivedToken")
      .withArgs(
        deployer.address,
        await MockERC20.getAddress(),
        ethers.parseUnits("100", 18),
        ethers.parseUnits("0.01", 18)
      );

    await expect(tx)
      .to.emit(KYEXLimitOrder, "OpenOrder")
      .withArgs(0, deployer.address);

    const order = await KYEXLimitOrder.orders(0);
    expect(order.fromToken).to.equal(await MockERC20.getAddress());
    expect(order.fromChainId).to.equal(31337);
    expect(order.amountIn).to.equal(ethers.parseUnits("100", 18));
    expect(order.toChainId).to.equal(21);
    expect(order.toToken).to.equal(
      "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
    );
    expect(order.recipient).to.equal(deployer.address);
    expect(order.expiry).to.equal(expiry);
    expect(order.amountOut).to.equal(ethers.parseUnits("100", 18));
    expect(order.gasFee).to.equal(ethers.parseUnits("0.01", 18));
    expect(order.sender).to.equal(deployer.address);
  });
  it("Should emit the corresponding event and allow correct retrieval of order details when fromToken is the native token", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();

    const openOrderParam = {
      fromToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
      fromChainId: 31337,
      amountIn: ethers.parseUnits("100", 18),
      toChainId: 21,
      toToken: await MockERC20.getAddress(),
      recipient: deployer.address,
      expiry: Math.floor(Date.now() / 1000) + 60 * 60,
      amountOut: ethers.parseUnits("100", 18),
      gasFee: ethers.parseUnits("0.01", 18),
    };
    const tx = await KYEXLimitOrder.openOrder(openOrderParam, {
      value: ethers.parseUnits("100.01", 18),
    });
    await expect(tx)
      .to.emit(KYEXLimitOrder, "ReceivedToken")
      .withArgs(
        deployer.address,
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        ethers.parseUnits("100", 18),
        ethers.parseUnits("0.01", 18)
      );

    await expect(tx)
      .to.emit(KYEXLimitOrder, "OpenOrder")
      .withArgs(0, deployer.address);

    const order = await KYEXLimitOrder.orders(0);
    expect(order.fromToken).to.equal(
      "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
    );
    expect(order.fromChainId).to.equal(31337);
    expect(order.amountIn).to.equal(ethers.parseUnits("100", 18));
    expect(order.toChainId).to.equal(21);
    expect(order.toToken).to.equal(await MockERC20.getAddress());
    expect(order.recipient).to.equal(deployer.address);
    expect(order.expiry).to.equal(Math.floor(Date.now() / 1000) + 60 * 60);
    expect(order.amountOut).to.equal(ethers.parseUnits("100", 18));
    expect(order.gasFee).to.equal(ethers.parseUnits("0.01", 18));
    expect(order.sender).to.equal(deployer.address);
  });
});
