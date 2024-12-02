const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SHToken", function () {
  let SHToken, shtoken, signers, addr1, addr2;

  beforeEach(async function () {
    SHToken = await ethers.getContractFactory("SHToken");
    signers = await ethers.getSigners();
    addr1 = signers[0];
    addr2 = signers[1];
    shtoken = await SHToken.deploy("Sample Token", "STK", addr1.address);
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await shtoken.hasRole(shtoken.MINTER_ROLE(), addr1.address)).to.be.true;
      expect(await shtoken.hasRole(shtoken.BURNER_ROLE(), addr1.address)).to.be.true;
    });

    it("Should have the correct name and symbol", async function () {
      expect(await shtoken.name()).to.equal("Sample Token");
      expect(await shtoken.symbol()).to.equal("STK");
    });

    it("Should have 6 decimals", async function () {
      expect(await shtoken.decimals()).to.equal(6);
    });
  });

  describe("Minting", function () {
    it("Should mint tokens to an address", async function () {
      await shtoken.mint(addr1.address, 1000);
      expect(await shtoken.balanceOf(addr1.address)).to.equal(1000);
    });

    it("Should not allow non-minters to mint", async function () {
      const minterRole = await shtoken.MINTER_ROLE();
      await expect(shtoken.connect(addr2).mint(addr2.address, 1000)).to.be.revertedWith(
        "AccessControl: account " + addr2.address.toLowerCase() + " is missing role " + minterRole
      );
    });
  });

  describe("Burning", function () {
    beforeEach(async function () {
      await shtoken.mint(addr1.address, 1000);
    });

    it("Should burn tokens from an address", async function () {
      await shtoken.connect(addr1).burn(addr1.address, 500);
      expect(await shtoken.balanceOf(addr1.address)).to.equal(500);
    });

    it("Should not allow non-burners to burn", async function () {
      const burnerRole = await shtoken.BURNER_ROLE();
      await expect(shtoken.connect(addr2).burn(addr1.address, 500)).to.be.revertedWith(
        "AccessControl: account " + addr2.address.toLowerCase() + " is missing role " + burnerRole
      );
    });
  });

  describe("Transfers", function () {
    beforeEach(async function () {
      await shtoken.mint(addr1.address, 1000);
    });

    it("Should transfer tokens between accounts", async function () {
      await shtoken.connect(addr1).transfer(addr2.address, 500);
      expect(await shtoken.balanceOf(addr1.address)).to.equal(500);
      expect(await shtoken.balanceOf(addr2.address)).to.equal(500);
    });

    it("Should not allow transfers of more than balance", async function () {
      await expect(shtoken.connect(addr1).transfer(addr2.address, 1500)).to.be.revertedWith(
        "Insufficient balance"
      );
    });
  });
});