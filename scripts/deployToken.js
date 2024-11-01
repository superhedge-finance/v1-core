async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    // console.log("Account balance:", (await deployer.getBalance()).toString());

    const Token = await ethers.getContractFactory("USDC");

   
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
