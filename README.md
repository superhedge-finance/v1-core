# SuperHedge

Principal-protected DeFi Structured Products

## Overview

SuperHedge is a DeFi protocol that offers principal-protected structured products.

## Prerequisites

- Node.js and npm installed
- Access to Ethereum, Arbitrum, and Base networks
- API keys for Etherscan, Arbiscan, and Basescan

## Installation

1. Clone the repository to your local machine:
```bash
git clone [repository-url]
```

2. Install project dependencies:
```bash
npm install
```

3. Create a `secret.json` file in the project root with the following environment variables:
```json
{
    "PRIVATE_KEY": "",
    "ETHEREUM_RPC_URL": "",
    "ARBITRUM_RPC_URL": "",
    "BASE_RPC_URL": "",
    "API_KEY_ETHERSCAN": "",
    "API_KEY_ARBISCAN": "",
    "API_KEY_BASESCAN": ""
}
```

## Deployment Guide

### 1. Deploy SHTokenFactory

```bash
# Deploy the contract
npx hardhat run scripts/deployTokenFactory.js --network XXX

# Verify the contract
npx hardhat verify --network XXX [CONTRACT_ADDRESS]
```

### 2. Deploy SHFactory

```bash
# Deploy the contract
npx hardhat run scripts/deployFactoryContract.js --network XXX

# Verify the contract
npx hardhat verify --network XXX [CONTRACT_ADDRESS]
```

### 3. Initialize SHFactory

1. Call `SHFactory.initialize()` with the address of SHTokenFactory to register the TokenFactory with the SHFactory

### 4. Create Products

1. Call `SHFactory.createProduct()` to deploy SHProduct vaults

## Network Support

- Ethereum
- Arbitrum
- Base