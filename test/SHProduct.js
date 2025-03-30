const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { utils } = ethers;

describe("SHProduct", function () {
    let MockUSDC,mockUSDC,SHFactory,shFactory,SHTokenFactory,shTokenFactory;
    let signer, otherSigner,USDCBalance,shProduct, productAddress,signers;
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
        // console.log("SHTokenFactory Address:", await shTokenFactory.getAddress());
        // console.log("SHFactory Address:", await shFactory.getAddress());
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
            issuanceDate: 1732758775,
            maturityDate: 1735350775,
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

        const receipt = await tx.wait();
        // console.log("event", receipt.logs[4].args);
        // const [productAddress, , , , tokenAddress] = receipt.logs[4].args;

        productAddress = receipt.logs[4]?.args[0];

        // console.log("SHProductAddress", productAddress);
        // console.log("tokenAddress", tokenAddress);

        const SHProductABI = require("./SHProduct.json");
        shProduct = new ethers.Contract(productAddress, SHProductABI, signer);
        // const maxcapacity = await shProduct.maxCapacity();
        // console.log("maxCapacity", maxcapacity);
        // console.log("Signer", publicKeySigner);
        // console.log("Signer USDC Balance:", USDCBalance.toString());
    });

    describe("SHFactory", function () {
        it("should initialize SHFactory successfully", async function () {
            expect(shFactory.initialize(shTokenFactory.getAddress())).to.emit(shFactory, "Initialized");
        });
    });

    describe("Whitelist", function () {

        beforeEach(async function () {
            await shProduct.whitelist(signer.address);
            expect(await shProduct.whitelisted(signer.address)).to.emit(shProduct, "Whitelisted");
        });

        it("check whitelist", async function () {
            const isWhitelisted = await shProduct.whitelisted(signer.address);
            expect(isWhitelisted).to.be.true;
        });
        it("check not whitelist", async function () {
            const isWhitelisted = await shProduct.whitelisted(otherSigner.address);
            expect(isWhitelisted).to.be.false;
        });
    });

    describe("Status", function () {
        beforeEach(async function () {
            await shProduct.whitelist(signer.address);
        });
        it("check status ", async function () {
            const status = await shProduct.status();
            expect(status).to.be.equal(0);
        });
        it("FundAccept FundLock Issuance Matured", async function () {
            await shProduct.fundAccept();
            expect(await shProduct.status()).to.be.equal(1);
    
            await shProduct.fundLock();
            expect(await shProduct.status()).to.be.equal(2);

            await shProduct.issuance();
            expect(await shProduct.status()).to.be.equal(3);

            await shProduct.mature();
            expect(await shProduct.status()).to.be.equal(4);
        });

        it("can not change status from FundAccept to Issuance", async function () {
            await shProduct.fundAccept();
            expect(await shProduct.status()).to.be.equal(1);

            await expect(shProduct.issuance()).to.be.revertedWith("Not locked");
        });

        it("can not change status from FundAccept to Matured", async function () {
            await shProduct.fundAccept();
            expect(await shProduct.status()).to.be.equal(1);
            await expect(shProduct.mature()).to.be.revertedWith("Not issued");
        });
    });
    describe("Coupon", function () {
        beforeEach(async function () {
            await shProduct.whitelist(signer.address);
        });

        it("can not change coupon when status is not Issuance", async function () {
            const userList = [signer.address];
            const amountList = [100];
            await expect(shProduct.coupon(userList, amountList)).to.be.revertedWith("Not issued");
        });

        it("can add coupon when status is Issuance", async function () {
            await shProduct.fundAccept();
            await shProduct.fundLock();
            await shProduct.issuance();
            const userList = [signer.address];
            const amountList = [100];
            expect(await shProduct.coupon(userList, amountList)).to.emit(shProduct, "Coupon");
        });

        it("check coupon balance after add coupon", async function () {
            await shProduct.fundAccept();
            await shProduct.fundLock();
            await shProduct.issuance();
            const userList = [signer.address];
            const amountList = [100];
            await shProduct.coupon(userList, amountList);
            const userInfo = await shProduct.userInfo(signer.address);
            const couponBalance = userInfo.coupon;
            expect(couponBalance).to.be.equal(100);
        });

        it("update coupon when status is fundLock with manager", async function () {
            await shProduct.fundAccept();
            await shProduct.fundLock();
            await shProduct.updateCoupon(20);
            const issuanceCycle = await shProduct.issuanceCycle();
            expect(await issuanceCycle[0]).to.be.equal(20);
        });

        it("update coupon when status is fundLock with not manager", async function () {
            await shProduct.fundAccept();
            await shProduct.fundLock();
            const shProductWithOtherSigner = shProduct.connect(otherSigner);
            await expect(shProductWithOtherSigner.updateCoupon(20)).to.be.revertedWith("Not a manager");
        });

        it("update coupon when status is Matured with manager", async function () {
            await shProduct.fundAccept();
            await shProduct.fundLock();
            await shProduct.issuance();
            await shProduct.mature();
            await shProduct.updateCoupon(20);
            const issuanceCycle = await shProduct.issuanceCycle();
            expect(await issuanceCycle[0]).to.be.equal(20);
        });

        it("can not update coupon when status is not Issuance", async function () {
            await expect(shProduct.updateCoupon(20)).to.be.revertedWith("Neither Locked nor Mature");
        });

        it("can not update coupon when coupon is greater than 100", async function () {
            await shProduct.fundAccept();
            await shProduct.fundLock();
            await expect(shProduct.updateCoupon(101)).to.be.revertedWith("Less than 0 or greater than 100");
        });
    });

    describe("Option", function () {
        beforeEach(async function () {
            await shProduct.whitelist(signer.address);
            await shProduct.fundAccept();
            await shProduct.fundLock();
            await shProduct.issuance();
            await shProduct.mature();
        });

        it("can add option profit list when status is Accepted", async function () {
            await mockUSDC.approve(productAddress,10000);
            await shProduct.redeemOptionPayout(10000);
            await shProduct.fundAccept();
            const userList = [signer.address];
            const amountList = [200];
            await shProduct.addOptionProfitList(userList, amountList);
            const userInfo = await shProduct.userInfo(signer.address);
            const optionPayout = userInfo.optionPayout;
            expect(optionPayout).to.be.equal(200);
        });

        it("can add option profit list when status is Accepted", async function () {
            await mockUSDC.approve(productAddress,10000);
            await shProduct.redeemOptionPayout(10000);
            const userList = [signer.address];
            const amountList = [200];
            await expect(shProduct.addOptionProfitList(userList, amountList)).to.be.revertedWith("Not accepted");
        });
        
    });

    describe("deposit", function () {
        beforeEach(async function () {
            await shProduct.whitelist(signer.address);
        });

        it("can deposit with fundAccept status", async function () {
            await shProduct.fundAccept();
            await mockUSDC.approve(productAddress,10000);
            await expect(shProduct.deposit(1000,false)).to.emit(shProduct, "Deposit");
        });

        it("can deposit without fundAccept status", async function () {
            await shProduct.fundAccept();
            await shProduct.fundLock();
            await mockUSDC.approve(productAddress,10000);
            await expect(shProduct.deposit(10000,false)).to.be.revertedWith("Not accepted");
        });

        it("can deposit with fundAccept status and check balance", async function () {
            await shProduct.fundAccept();
            await mockUSDC.approve(productAddress,10000);
            await shProduct.deposit(10000,false);
            const tokenBalance = await shProduct.principalBalance(signer.address);
            expect(tokenBalance).to.be.equal(10000);
        });
    });

    describe("withdraw", function () {
        beforeEach(async function () {
            await shProduct.whitelist(signer.address);
            await shProduct.fundAccept();
            await mockUSDC.approve(productAddress,10000);
            await shProduct.deposit(10000,false);
        });
        it("can withdrawPrincipal with fundAccept status", async function () {
            await expect(shProduct.withdrawPrincipal()).to.emit(shProduct, "WithdrawPrincipal");
        });

        it("can not withdrawPrincipal without fundAccept status", async function () {
            await shProduct.fundLock();
            await expect(shProduct.withdrawPrincipal()).to.be.revertedWith("Not accepted");
        });

        it("can not withdrawPrincipal when balance is 0", async function () {
            const shProductWithOtherSigner = shProduct.connect(otherSigner);
            await expect(shProductWithOtherSigner.withdrawPrincipal()).to.be.revertedWith("Amount must be greater than zero");
        });

        it("can withdrawCoupon", async function () {
            await shProduct.fundLock();
            await shProduct.issuance();
            const userList = [signer.address];
            const amountList = [100];
            await shProduct.coupon(userList, amountList);
            await expect(shProduct.withdrawCoupon()).to.emit(shProduct, "WithdrawCoupon");
        });

        it("can withdrawCoupon and balance is 0", async function () {
            await shProduct.fundLock();
            await shProduct.issuance();
            const userList = [signer.address];
            const amountList = [100];
            await shProduct.coupon(userList, amountList);
            await shProduct.withdrawCoupon();
            const userInfo = await shProduct.userInfo(signer.address);
            const couponBalance = userInfo.coupon;
            expect(couponBalance).to.be.equal(0);
        });

        it("can not withdrawCoupon when balance is greater than totalBalance", async function () {
            await shProduct.fundLock();
            await shProduct.issuance();
            const userList = [signer.address];
            const amountList = [100000];
            await shProduct.coupon(userList, amountList);
            await expect(shProduct.withdrawCoupon()).to.be.revertedWith("Insufficient contract balance");
        });


        it("can withdrawOption", async function () {
            await mockUSDC.approve(productAddress,10000);
            await shProduct.fundLock();
            await shProduct.issuance();
            await shProduct.mature();
            await shProduct.redeemOptionPayout(10000);
            await shProduct.fundAccept();
            const userList = [signer.address];
            const amountList = [100];
            await shProduct.addOptionProfitList(userList, amountList);
            await expect(shProduct.withdrawOption()).to.emit(shProduct, "WithdrawOption");
        });

        it("can not withdrawOption when balance is 0", async function () {
            const shProductWithOtherSigner = shProduct.connect(otherSigner);
            await expect(shProductWithOtherSigner.withdrawOption()).to.be.revertedWith("No option payout available");
        });

        it("can not withdrawOption when balance is greater than totalBalance", async function () {
            await mockUSDC.approve(productAddress,100000);
            await shProduct.fundLock();
            await shProduct.issuance();
            await shProduct.mature();
            await shProduct.redeemOptionPayout(100000);
            await shProduct.fundAccept();
            const userList = [signer.address];
            const amountList = [200000];
            await shProduct.addOptionProfitList(userList, amountList);
            await expect(shProduct.withdrawOption()).to.be.revertedWith("Insufficient contract balance");
        });
    });

});

