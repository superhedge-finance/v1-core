const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { utils } = ethers;

describe("SHFactory", function () {
    let MockUSDC,mockUSDC,SHFactory,shFactory,SHTokenFactory,shTokenFactory;
    let signer, otherSigner,signers;
    beforeEach(async function () {
        await network.provider.send("hardhat_reset");
        signers = await ethers.getSigners();
        signer = signers[0];
        otherSigner = signers[1];
        SHFactory = await ethers.getContractFactory("SHFactory");
        shFactory = await SHFactory.deploy();
        await shFactory.waitForDeployment();
        SHTokenFactory = await ethers.getContractFactory("SHTokenFactory");
        shTokenFactory = await SHTokenFactory.deploy();
        await shTokenFactory.waitForDeployment();
    });

    describe("SHFactory", async function () {
        it("should initialize SHFactory successfully", async function () {
            await expect(shFactory.initialize(await shTokenFactory.getAddress())).to.emit(shFactory, "Initialized");
        });

        it("should create SHProduct successfully", async function () {
            await shFactory.initialize(await shTokenFactory.getAddress());

        MockUSDC = await ethers.getContractFactory("MockUSDC");
        mockUSDC = await MockUSDC.deploy();
        await mockUSDC.waitForDeployment();
        await mockUSDC.mint(signer.address, 1000000000);
        USDCBalance = await mockUSDC.balanceOf(signer.address);
        publicKeySigner = await signer.getAddress();

        const name = "BTC Bullish Spread 05";
        const underlying = "BTC/USDC";
        const currency = await mockUSDC.getAddress();
        const manager = signer.address;
        const exWallet = signer.address;
        const maxCapacity = 1000;
        const issuanceCycle = {
            coupon: 10,
            strikePrice1: 30000,
            strikePrice2: 32000,
            strikePrice3: 0,
            strikePrice4: 0,
            tr1: 10810,
            tr2: 10040,
            issuanceDate: Math.floor(Date.now() / 1000) + 72000,
            maturityDate: Math.floor(Date.now() / 1000) + 2592000,
            apy: "5%",
            underlyingSpotRef: 1,
            optionMinOrderSize: 1,
            subAccountId: "59358",
            participation: 1
        };
        const router = '0x888888888889758F76e7103c6CbF23ABbF58F946';
        const market = '0x875F154f4eC93255bEAEA9367c3AdF71Cdcb4Cc0';

        const tx = await shFactory.createProduct(
            name,
            underlying,
            currency,
            manager,
            exWallet,
            maxCapacity,
            issuanceCycle,
            router,
            market
        );
        });

        await expect(tx).to.emit(shFactory, "ProductCreated");

    });

});

