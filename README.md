# 👻 GHOST — Your On-Chain AI Agent

> *"Your DeFi Ghost never sleeps."*

**Build X Hackathon Season 2 · X Layer × OKX · April 2026**

## Live Contracts (X Layer Mainnet - Chain ID: 196)

| Contract | Address | Explorer |
|---|---|---|
| GhostRegistry | `0x03C172E5BB8002360376610DB75f0Cb9A01f473b` | [View](https://www.okx.com/explorer/xlayer/address/0x03C172E5BB8002360376610DB75f0Cb9A01f473b) |
| GhostReputation | `0xAF4F076AFE8Fb58FEAC1c7C3C8AfFDD15f479F88` | [View](https://www.okx.com/explorer/xlayer/address/0xAF4F076AFE8Fb58FEAC1c7C3C8AfFDD15f479F88) |
| GhostRental | `0x887832751aA690A2bA15718Ecb965E0A0bbA836A` | [View](https://www.okx.com/explorer/xlayer/address/0x887832751aA690A2bA15718Ecb965E0A0bbA836A) |

## What is GHOST?

GHOST is a personalized on-chain AI agent — your autonomous DeFi doppelganger. It:

1. **Mints your identity** as an ERC-8004 agent NFT on X Layer
2. **Manages DeFi positions 24/7** using OKX Onchain OS Skills
3. **Detects risk before it happens** via the PRECOG engine
4. **Auto-hedges** when risk thresholds exceeded (Uniswap on X Layer)
5. **Builds on-chain reputation** via ERC-8183 (every trade recorded)
6. **Earns passive income** — rent your Ghost via x402 USDC micropayments

## Tech Stack

| Layer | Technology |
|---|---|
| Chain | X Layer Mainnet (EVM, Chain ID: 196) |
| AI Skills | OKX Onchain OS (wallet, market, swap, gateway) |
| DEX | Uniswap V3 on X Layer + OKX DEX (500+ sources) |
| Payments | x402 Protocol — USDC micropayments |
| Identity | ERC-8004 (ERC-721 agent NFT) |
| Reputation | ERC-8183 (on-chain trade recording) |

## Quick Start

```bash
npm install
cp .env.example .env  # add your private key
npx hardhat compile
npx hardhat run scripts/deploy.js --network xlayer
node agent/ghost-agent.js
npx http-server frontend -p 3000
```

## Project Structure
ghost/
├── contracts/
│   ├── GhostRegistry.sol      # ERC-8004 agent identity
│   ├── GhostRental.sol        # x402 rental marketplace
│   └── GhostReputation.sol    # ERC-8183 reputation
├── agent/ghost-agent.js       # OKX Onchain OS AI agent
├── frontend/index.html        # Full dApp
└── scripts/deploy.js          # X Layer deployment

## Built by AQEELERH | github.com/AQEELERRHH
