async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const SHTokenFactory = await ethers.getContractFactory("SHTokenFactory");
    const shtokenfactory = await SHTokenFactory.deploy();
    await shtokenfactory.waitForDeployment();
    const contractAddress = await shtokenfactory.getAddress();
    console.log("SHTokenFactory address:", contractAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
