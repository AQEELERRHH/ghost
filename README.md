# GHOST: Autonomous AI Agents for On-Chain DeFi Portfolio Management

Rentable AI agents with on-chain identity and reputation that autonomously manage DeFi portfolios.

> *"Your DeFi Ghost never sleeps."*

**Build X Hackathon Season 2 · X Layer × OKX · April 2026**

##  Live Demo

* App: [https://ghost1-cyan.vercel.app](https://ghost1-cyan.vercel.app)

---
## Overview

**GHOST** is an AI-powered DeFi portfolio manager built on X Layer.

It introduces autonomous on-chain agents called **Ghosts** that:

* Trade and hedge portfolios
* Adapt to market risk in real time
* Build verifiable on-chain reputation
* Generate passive income through rentals

Each Ghost isa **persistent on-chain financial entity** with identity, performance history, and economic value.

---

## Key Features

### On-Chain Agent Identity

* Ghosts are minted as NFTs (ERC-8004-inspired)
* Permanent, verifiable, and discoverable
* Store strategy, risk level, and configuration

---

### Autonomous Portfolio Management

* Continuous monitoring of portfolio state
* Executes trades and rebalancing strategies
* Fully on-chain and transparent

---

### PRECOG Risk Engine

* Multi-factor risk analysis:

  * Volatility
  * Momentum
  * Trend direction
* Generates dynamic risk score (0-100)
* Automatically hedges via DEX swaps when risk is high

---

### On-Chain Reputation System

* Tracks:

  * Win rate
  * PnL vs HODL
  * Hedge effectiveness
  * Usage (rentals)
* Stored immutably on-chain
* Enables trustless evaluation of agents

---

### Rental Marketplace (x402)

* Rent high-performing agents by the hour
* USDC micropayments via x402
* Passive income for Ghost owners
* Fully trustless escrow system

---

### Fully On-Chain Execution

All actions are verifiable:

* Minting agents
* Executing trades
* Hedging risk
* Rental payments

---

## Architecture

```
X Layer (Chain ID: 196)
│
├── GhostRegistry    → Agent identity (NFT)
├── GhostReputation  → Performance + trust
└── GhostRental      → Payment + escrow
         │
         ▼
AI Agent Loop
├── Portfolio Monitoring
├── Market Analysis (PRECOG)
├── Trade Execution
└── On-chain Logging
```

---

## Smart Contracts

| Contract        | Description                  | Address                                      |
| --------------- | ---------------------------- | -------------------------------------------- |
| GhostRegistry   | Agent identity (NFT minting) | `0x03C172E5BB8002360376610DB75f0Cb9A01f473b` |
| GhostReputation | Tracks performance + scoring | `0xAF4F076AFE8Fb58FEAC1c7C3C8AfFDD15f479F88` |
| GhostRental     | Rental escrow + payments     | `0x887832751aA690A2bA15718Ecb965E0A0bbA836A` |

---

## OnchainOS Integration

GHOST uses OKX OnchainOS to power agent intelligence:

* **okx-wallet-portfolio**
  → Real-time asset tracking

* **okx-dex-market**
  → Market data (price, volatility, candles)

* **okx-dex-swap**
  → Trade and hedge execution

* **okx-onchain-gateway**
  → Transaction simulation and broadcasting

---

## Agent Lifecycle

1. **Mint Ghost**

   * Define strategy, risk, and rental price
   * NFT identity is created on-chain

2. **Run Agent**

   * Monitor portfolio
   * Analyze market via PRECOG
   * Execute trades

3. **Build Reputation**

   * Every action updates on-chain score

4. **Rent Agent**

   * Other users pay via USDC (x402)
   * Owner earns passive income

---

## Security & Trust

* No custodial control
* Smart contracts manage all funds
* Fully transparent on-chain actions
* Reputation discourages malicious strategies

---

## Tech Stack
Frontend: Vanilla HTML, CSS, JavaScript
Blockchain: X Layer (EVM)
Smart Contracts: Solidity
DEX Execution: Uniswap + OKX DEX Aggregator
Data Layer: OKX OnchainOS
Payments: x402 (USDC micropayments)

---

## What Makes GHOST Unique

* AI agents with **real on-chain identity**
* Transparent, **verifiable performance history**
* **Adaptive risk engine** (not static bots)
* **Rental economy for agents**
* Fully **on-chain + trustless system**

---

## Use Cases

* Passive DeFi portfolio management
* Renting high-performing trading agents
* Monetizing trading strategies
* Trustless evaluation of AI performance

---

## Future Improvements

* More advanced AI/ML-driven strategies
* Multi-chain expansion
* Strategy customization marketplace
* Agent-to-agent interactions

---

## Contributing

Contributions are welcome. Feel free to:

* Open issues
* Suggest features
* Submit pull requests

---

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

## Built by AQEELERH | https://x.com/aqeelerh 

## License

MIT License

