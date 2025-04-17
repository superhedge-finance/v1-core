# SuperHedge

Principal-protected Defi Structured Products


## Contract Deployment

1. Clone repo to localhost

2. Install project packages:
npm install

3. Create secret.json file with environment variables:
{
    "PRIVATE_KEY": "",
    "ETHEREUM_RPC_URL": "",
    "ARBITRUM_RPC_URL": "",
    "BASE_RPC_URL": "",
    "API_KEY_ETHERSCAN": "",
    "API_KEY_ARBISCAN": "",
    "API_KEY_BASESCAN": ""
}

4i. Deploy and verify SHTokenFactory:
npx hardhat run scripts/deployTokenFactory.js --network XXX
npx hardhat verify --network XXX 0x...

4ii. Deploy and verify SHFactory:
npx hardhat run scripts/deployFactoryContract.js --network XXX
npx hardhat verify --network XXX 0x...

5. Call SHFactory.initialize() with the address of SHTokenFactory to register the TokenFactory with the SHFactory

6. Call SHFactory.createProduct() to deploy SHProduct vaults