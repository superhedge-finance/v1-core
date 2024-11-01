async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    // console.log("Account balance:", (await deployer.getBalance()).toString());

    const Token = await ethers.getContractFactory("Presale");

    // Without agruments, the contract
    // const token = await Token.deploy();
    const productFactory = "0x7F2E965945D6729Cce044ef95E84ED4bA1C5971e"
    const tokenFactory = "0xC3Dd6883cb53641c298aA9641D04153E1335Fd2f"
    const token = await Token.deploy();

    await token.waitForDeployment();
    const contractAddress = await token.getAddress();
    console.log("Token address:", contractAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
