async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    // console.log("Account balance:", (await deployer.getBalance()).toString());

    const Token = await ethers.getContractFactory("SHToken");

    // Without agruments, the contract
    // const token = await Token.deploy();
    const name = "SHToken"
    const symbol = "SHT"
    const productAddress = "0xbcc8E071e300b7Ae67aeb6E271E15DC5123B4c8D"
    const token = await Token.deploy(name,symbol,productAddress);

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
