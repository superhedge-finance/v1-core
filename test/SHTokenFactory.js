const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SHTokenFactory", function () {
  let SHTokenFactory, shtokenFactory, owner, addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    const SHToken = await ethers.getContractFactory("SHToken");
    SHTokenFactory = await ethers.getContractFactory("SHTokenFactory");
    shtokenFactory = await SHTokenFactory.deploy();
    await shtokenFactory.waitForDeployment();
  });

  it("should create a new token and emit TokenCreated event", async function () {
    const name = "TestToken";
    const symbol = "TTK";
    const tx = await shtokenFactory.createToken(name, symbol, addr1.address);

    await expect(tx).to.emit(shtokenFactory, "TokenCreated");
  });
});
