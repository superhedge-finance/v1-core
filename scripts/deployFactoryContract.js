async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const SHFactory = await ethers.getContractFactory("SHFactory");
    const shfactory = await SHFactory.deploy();
    await shfactory.waitForDeployment();
    const contractAddress = await shfactory.getAddress();
    console.log("SHFactory address:", contractAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
