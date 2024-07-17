async function main() { 
    const [deployer] = await ethers.getSigners(); 
 
    console.log("Deploying contracts with the account:", deployer.address); 
 
    // const Token = await ethers.getContractFactory("NAME OF CONTRACT TO DEPLOY HERE"); 
    const SHTokenFactory = await ethers.getContractFactory("SHTokenFactory");
    const contract = await SHTokenFactory.deploy();
    // await token.waitForDeployment();
    
    const contractAddress = await contract.getAddress(); 
    console.log("Contract address:", contractAddress); 
} 
 
main() 
    .then(() => process.exit(0)) 
    .catch((error) => { 
        console.error(error); 
        process.exit(1); 
    });