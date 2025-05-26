const { ethers } = require("hardhat");
const { expect } = require("chai");
const { deployLimitOrder } = require("../script/deployLimitOrder");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("openOrder", async function () {
  it("Should revert if expiry is earlier than the current block time", async function () {
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
      expiry: Math.floor(Date.now() / 1000) - 60 * 60,
      amountOut: ethers.parseUnits("100", 18),
      gasFee: ethers.parseUnits("0.001", 18),
    };
    await expect(
      KYEXLimitOrder.openOrder(openOrderParam)
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "ExpiryEarlier");
  });

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

describe("cancelOrder", async function () {
  it("Should revert if the order does not exist", async function () {
    const { KYEXLimitOrder } = await loadFixture(deployLimitOrder);
    await expect(KYEXLimitOrder.cancelOrder(1)).to.be.revertedWithCustomError(
      KYEXLimitOrder,
      "OrderNotExist"
    );
  });

  it("Should revert if msg.sender is not owner or sender", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer, user] = await ethers.getSigners();
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

    await KYEXLimitOrder.openOrder(openOrderParam, {
      value: ethers.parseUnits("100.01", 18),
    });

    await expect(
      KYEXLimitOrder.connect(user).cancelOrder(0)
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "OnlySenderOrOwner");
  });

  it("Should emit the corresponding event, refund the user,and delete the order when fromToken is the native token", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer, user] = await ethers.getSigners();
    //Record the initial balance of user
    const initialBalanceOfUser = await ethers.provider.getBalance(user.address);
    //Create an order
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
    const txOfOpenOrder = await KYEXLimitOrder.connect(user).openOrder(
      openOrderParam,
      {
        value: ethers.parseUnits("100.01", 18),
      }
    );
    const openOrderReceipt = await txOfOpenOrder.wait();
    //Record the gas fee of the transaction
    const gasUsedOfUser = openOrderReceipt.gasUsed * txOfOpenOrder.gasPrice;
    //Cancel order by deployer and Verify the event
    await expect(await KYEXLimitOrder.cancelOrder(0))
      .to.emit(KYEXLimitOrder, "CancelOrder")
      .withArgs(0, deployer.address);
    //Verify the refund
    expect(await ethers.provider.getBalance(user.address)).to.equal(
      initialBalanceOfUser - gasUsedOfUser
    );
    //Verify the order has been deleted
    const order = await KYEXLimitOrder.orders(0);
    expect(order.fromToken).to.equal(ethers.ZeroAddress);
    expect(order.fromChainId).to.equal(0);
    expect(order.amountIn).to.equal(0);
    expect(order.toChainId).to.equal(0);
    expect(order.toToken).to.equal(ethers.ZeroAddress);
    expect(order.recipient).to.equal(ethers.ZeroAddress);
    expect(order.expiry).to.equal(0);
    expect(order.amountOut).to.equal(0);
    expect(order.gasFee).to.equal(0);
    expect(order.sender).to.equal(ethers.ZeroAddress);
    expect(await KYEXLimitOrder.getAllTokenId()).to.be.empty;
  });
});

describe("executeOrder", async function () {
  it("Should revert if the order does not exist", async function () {
    const { KYEXLimitOrder } = await loadFixture(deployLimitOrder);
    await expect(
      KYEXLimitOrder.executeOrder(0, ethers.ZeroAddress, 0, 0, "0x")
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "OrderNotExist");
  });
  it("Should revert if the expiry is later than the current block time", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();
    // Create an order
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
    await KYEXLimitOrder.openOrder(openOrderParam, {
      value: ethers.parseUnits("100.01", 18),
    });
    // Increase the block time by 1 hour
    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine");
    await expect(
      KYEXLimitOrder.executeOrder(0, ethers.ZeroAddress, 0, 0, "0x")
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "ExpiryEarlier");
  });

  it("Should revert if the squidRouter failed", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();
    // Create an order
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
    await KYEXLimitOrder.openOrder(openOrderParam, {
      value: ethers.parseUnits("100.01", 18),
    });
    const mockTargetFactory = await ethers.getContractFactory("MockTarget");
    const mockTarget = await mockTargetFactory.deploy();
    await mockTarget.waitForDeployment();

    const mockTargetInterface = new ethers.Interface([
      "function fail() external payable",
    ]);
    const data = mockTargetInterface.encodeFunctionData("fail");

    await expect(
      KYEXLimitOrder.executeOrder(
        0,
        await mockTarget.getAddress(),
        2100,
        ethers.parseUnits("100", 18),
        data
      )
    ).to.be.revertedWithCustomError(KYEXLimitOrder, "CallSquidRouterFail");
  });

  it("Should emit the corresponding event,and delete the order when fromToken is the nativeToken", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();
    // Create an order
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
    await KYEXLimitOrder.openOrder(openOrderParam, {
      value: ethers.parseUnits("100.01", 18),
    });
    const mockTargetFactory = await ethers.getContractFactory("MockTarget");
    const mockTarget = await mockTargetFactory.deploy();
    await mockTarget.waitForDeployment();

    const mockTargetInterface = new ethers.Interface([
      "function call() external payable",
    ]);
    const data = mockTargetInterface.encodeFunctionData("call");
    const tx = await KYEXLimitOrder.executeOrder(
      0,
      await mockTarget.getAddress(),
      30000,
      ethers.parseUnits("100", 18),
      data
    );

    const sendAmount =
      (ethers.parseUnits("100", 18) * BigInt(9950)) / BigInt(10000);
    await expect(tx)
      .to.emit(KYEXLimitOrder, "ExcutedOrder")
      .withArgs(
        0,
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        sendAmount,
        ethers.parseUnits("100", 18)
      );
    await expect(tx)
      .to.emit(KYEXLimitOrder, "ReceivePlatformFee")
      .withArgs(
        "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
        deployer.address,
        deployer.address,
        (ethers.parseUnits("100", 18) * BigInt(50)) / BigInt(10000)
      );

    const order = await KYEXLimitOrder.orders(0);
    expect(order.fromToken).to.equal(ethers.ZeroAddress);
    expect(order.fromChainId).to.equal(0);
    expect(order.amountIn).to.equal(0);
    expect(order.toChainId).to.equal(0);
    expect(order.toToken).to.equal(ethers.ZeroAddress);
    expect(order.recipient).to.equal(ethers.ZeroAddress);
    expect(order.expiry).to.equal(0);
    expect(order.amountOut).to.equal(0);
    expect(order.gasFee).to.equal(0);
    expect(order.sender).to.equal(ethers.ZeroAddress);
    expect(await KYEXLimitOrder.getAllTokenId()).to.be.empty;
  });

  it("Should emit the corresponding event,and delete the order when fromToken is not zero address", async function () {
    const { KYEXLimitOrder, MockERC20 } = await loadFixture(deployLimitOrder);
    const [deployer] = await ethers.getSigners();
    // Create an order
    const openOrderParam = {
      fromToken: await MockERC20.getAddress(),
      fromChainId: 31337,
      amountIn: ethers.parseUnits("100", 18),
      toChainId: 21,
      toToken: await MockERC20.getAddress(),
      recipient: deployer.address,
      expiry: Math.floor(Date.now() / 1000) + 60 * 60,
      amountOut: ethers.parseUnits("100", 18),
      gasFee: ethers.parseUnits("0.01", 18),
    };
    await MockERC20.approve(
      await KYEXLimitOrder.getAddress(),
      ethers.parseUnits("100", 18)
    );
    await KYEXLimitOrder.openOrder(openOrderParam, {
      value: ethers.parseUnits("0.01", 18),
    });
    const mockTargetFactory = await ethers.getContractFactory("MockTarget");
    const mockTarget = await mockTargetFactory.deploy();
    await mockTarget.waitForDeployment();

    const mockTargetInterface = new ethers.Interface([
      "function call() external payable",
    ]);
    const data = mockTargetInterface.encodeFunctionData("call");
    const tx = await KYEXLimitOrder.executeOrder(
      0,
      await mockTarget.getAddress(),
      30000,
      ethers.parseUnits("100", 18),
      data
    );

    const sendAmount =
      (ethers.parseUnits("100", 18) * BigInt(9950)) / BigInt(10000);
    await expect(tx)
      .to.emit(KYEXLimitOrder, "ExcutedOrder")
      .withArgs(
        0,
        await MockERC20.getAddress(),
        sendAmount,
        ethers.parseUnits("100", 18)
      );
    await expect(tx)
      .to.emit(KYEXLimitOrder, "ReceivePlatformFee")
      .withArgs(
        await MockERC20.getAddress(),
        deployer.address,
        deployer.address,
        (ethers.parseUnits("100", 18) * BigInt(50)) / BigInt(10000)
      );

    const order = await KYEXLimitOrder.orders(0);
    expect(order.fromToken).to.equal(ethers.ZeroAddress);
    expect(order.fromChainId).to.equal(0);
    expect(order.amountIn).to.equal(0);
    expect(order.toChainId).to.equal(0);
    expect(order.toToken).to.equal(ethers.ZeroAddress);
    expect(order.recipient).to.equal(ethers.ZeroAddress);
    expect(order.expiry).to.equal(0);
    expect(order.amountOut).to.equal(0);
    expect(order.gasFee).to.equal(0);
    expect(order.sender).to.equal(ethers.ZeroAddress);
    expect(await KYEXLimitOrder.getAllTokenId()).to.be.empty;
  });
});
