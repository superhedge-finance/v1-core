# SuperHedge

Principal-protected Defi Structured Products

## Contract Deployment

1. Clone repo to localhost

2. Install Packages:
npm install

3. Create secret.json file with environment variables:
{
    "PRIVATE_KEY" : "YOUR_PRIVATE_KEY",
    "API_KEY_ARBISCAN": "YOUR_ARBISCAN_API_KEY"
}

4. Deploy contracts below:
Edit the file scripts/deploy.js, and run
npx hardhat run scripts/deploy.js --network arb 

 i)     SHTokenFactory
 ii)    SHFactory

5. Verify each of the deployed contracts by running:
npx hardhat verify --contract "contracts/[CONTRACT.sol]:CONTRACT" --network arbitrum 0x_CONTRACT_ADDRESS
