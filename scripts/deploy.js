async function main() { 
    const [deployer] = await ethers.getSigners(); 
 
    console.log("Deploying contracts with the account:", deployer.address); 
 
    // const Token = await ethers.getContractFactory("NAME OF CONTRACT TO DEPLOY HERE"); 
    const Token = await ethers.getContractFactory("SHTokenFactory");
 
    const token = await Token.deploy();
    // await token.waitForDeployment();
    
    const contractAddress = await token.getAddress(); 
    console.log("Token address:", contractAddress); 
} 
 
main() 
    .then(() => process.exit(0)) 
    .catch((error) => { 
        console.error(error); 
        process.exit(1); 
    });