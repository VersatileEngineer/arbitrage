// test/ArbitrageTest.js

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Arbitrage", function () {
  let Arbitrage;
  let arbitrage;
  let owner;
  let user;

  before(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy the Arbitrage contract
    const ArbitrageFactory = await ethers.getContractFactory("Arbitrage");
    arbitrage = await ArbitrageFactory.deploy(owner.address, user.address, user.address, user.address, user.address);
    
  });

  it("should perform arbitrage", async function () {
    const amount = ethers.parseEther("1000000000"); // Replace with the desired amount

    // Transfer some initial USDC and WETH to the contract
    const usdc = await ethers.getContractAt("IERC20", arbitrage.usdc);
    const weth = await ethers.getContractAt("IERC20", arbitrage.weth);

    await usdc.connect(owner).transfer(arbitrage.address, amount);
    await weth.connect(user).transfer(user.address, amount);

    // Perform arbitrage
    await arbitrage.arbitrage(amount);

    // Check if the balance of WETH and USDC has changed
    const wethBalance = await weth.balanceOf(user.address);
    const usdcBalance = await usdc.balanceOf(arbitrage.address);

    expect(wethBalance).to.be.gt(0, "WETH balance should be greater than 0");
    expect(usdcBalance).to.be.gt(0, "USDC balance in the contract should be greater than 0");
  });
});

