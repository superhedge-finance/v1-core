# SuperHedge

Principal-protected Defi Structured Products


## Contract Deployment

1. Clone repo to localhost

2. Install project packages:
npm install

3. Create secret.json file with environment variables:
{
    "PRIVATE_KEY" : "YOUR_PRIVATE_KEY",
    "API_KEY_ETHERSCAN": "YOUR_ETHERSCAN_API_KEY"
}

4. Deploy using from /scripts in this order

 i)     deployTokenFactory.js
 ii)    deployFactoryContract.js

5. Verify each of the deployed contracts to run them from the block explorer
