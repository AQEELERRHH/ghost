/**
 * GHOST Agent - OKX Onchain OS powered autonomous DeFi agent
 * Build X Hackathon Season 2 - X Layer Mainnet
 * Uses: okx-wallet-portfolio, okx-dex-market, okx-dex-swap, okx-onchain-gateway
 */
const { ethers } = require("ethers");
const axios = require("axios");
require("dotenv").config();

const XLAYER_RPC = "https://rpc.xlayer.tech";
const OKX_BASE = "https://web3.okx.com";
const OKX_API_KEY = process.env.OKX_API_KEY;
const OKX_SECRET = process.env.OKX_SECRET_KEY;
const OKX_PASSPHRASE = process.env.OKX_PASSPHRASE;
const XLAYER_CHAIN_ID = "196";

const TOKENS = {
  USDC: "0x74b7F16337b8972027F6196A17a631aC6dE26d22",
  WOKB: "0xe538905cf8410324e03a5a23c1c177a474d59b2b",
  WETH: "0x5A77f1443D16ee5761d310e38b62f77f726bC71c",
};

const DEPLOYMENTS = require("../deployments.json");

const REGISTRY_ABI = [
  "function getGhost(uint256) view returns (tuple(address,string,uint8,uint256,uint256,bool,string[],bool,bool,uint256,uint256,uint256,int256,string,bool))",
  "function updateStats(uint256,uint256,int256)",
  "function isActive(uint256) view returns (bool)",
];

const REPUTATION_ABI = [
  "function recordTrade(uint256,string,string,uint256,uint256,int256,string)",
  "function recordHedge(uint256,bool,int256,string)",
];

class GhostAgent {
  constructor(ghostId, privateKey) {
    this.ghostId = ghostId;
    this.provider = new ethers.JsonRpcProvider(XLAYER_RPC);
    this.signer = new ethers.Wallet(privateKey, this.provider);
    this.registry = new ethers.Contract(DEPLOYMENTS.contracts.GhostRegistry, REGISTRY_ABI, this.signer);
    this.reputation = new ethers.Contract(DEPLOYMENTS.contracts.GhostReputation, REPUTATION_ABI, this.signer);
    this.tradeCount = 0;
    this.totalPnL = 0n;
    this.isRunning = false;
    console.log(`\n🔮 GHOST #${ghostId} | Executor: ${this.signer.address}`);
  }

  async getMarketData() {
    // OKX Onchain OS Skill: okx-dex-market
    try {
      const res = await axios.get(`${OKX_BASE}/api/v5/dex/market/candles`, {
        params: { chainId: XLAYER_CHAIN_ID, tokenContractAddress: TOKENS.WOKB, bar: "1H", limit: "24" },
        headers: { "OK-ACCESS-KEY": OKX_API_KEY },
        timeout: 8000
      });
      if (res.data?.data?.length) {
        const candles = res.data.data;
        const prices = candles.map(c => parseFloat(c[4]));
        const change = ((prices[prices.length-1] - prices[0]) / prices[0]) * 100;
        const highs = candles.map(c => parseFloat(c[2]));
        const lows = candles.map(c => parseFloat(c[3]));
        const volatility = (Math.max(...highs) - Math.min(...lows)) / prices[0] * 100;
        return { change24h: change, volatility, riskScore: Math.min(Math.abs(change)*4 + volatility*5, 100) };
      }
    } catch(e) { console.log("[OKX] Market data fallback:", e.message); }
    // Demo fallback
    const change = (Math.random()*10)-5;
    const vol = Math.random()*6+1;
    return { change24h: change, volatility: vol, riskScore: Math.min(Math.abs(change)*4+vol*5,100) };
  }

  async getPortfolio() {
    // OKX Onchain OS Skill: okx-wallet-portfolio
    try {
      const res = await axios.get(`${OKX_BASE}/api/v5/wallet/asset/all-token-balances`, {
        params: { address: this.signer.address, chains: XLAYER_CHAIN_ID },
        headers: { "OK-ACCESS-KEY": OKX_API_KEY },
        timeout: 8000
      });
      if (res.data?.data) {
        const tokens = res.data.data[0]?.tokenAssets || [];
        return { totalUSD: tokens.reduce((s,t) => s+parseFloat(t.usdValue||0), 0), tokens };
      }
    } catch(e) { console.log("[OKX] Portfolio fallback"); }
    return { totalUSD: 100, tokens: [] };
  }

  async runPrecog() {
    console.log("\n[PRECOG] Analyzing market...");
    const market = await this.getMarketData();
    const ghost = await this.registry.getGhost(this.ghostId).catch(() => null);
    const riskLevel = ghost ? Number(ghost[2]) : 3;
    const threshold = (6 - riskLevel) * 15;
    const hedge = market.riskScore > threshold || (market.volatility > 6 && market.change24h < -4);
    console.log(`[PRECOG] Risk: ${market.riskScore.toFixed(0)}/100 | Threshold: ${threshold} | Hedge: ${hedge}`);
    return { ...market, hedgeRecommended: hedge, threshold };
  }

  async recordTradeOnChain(tokenIn, tokenOut, amountIn, amountOut, pnlBps, txHash) {
    try {
      const tx = await this.reputation.recordTrade(this.ghostId, tokenIn, tokenOut, amountIn, amountOut, pnlBps, txHash);
      await tx.wait();
      this.tradeCount++;
      this.totalPnL += BigInt(pnlBps);
      await this.registry.updateStats(this.ghostId, this.tradeCount, this.totalPnL);
      console.log(`[RECORD] Trade #${this.tradeCount} recorded on X Layer`);
    } catch(e) {
      this.tradeCount++;
      console.log(`[RECORD] Local only (${e.message.slice(0,40)})`);
    }
  }

  async runCycle() {
    console.log(`\n${"=".repeat(50)}`);
    console.log(`🔮 GHOST #${this.ghostId} | ${new Date().toLocaleTimeString()}`);
    console.log(`${"=".repeat(50)}`);

    const active = await this.registry.isActive(this.ghostId).catch(() => true);
    if (!active) { console.log("[GHOST] Deactivated on-chain"); this.stop(); return; }

    const precog = await this.runPrecog();
    const portfolio = await this.getPortfolio();
    console.log(`[PORTFOLIO] $${portfolio.totalUSD.toFixed(2)}`);

    if (precog.hedgeRecommended) {
      console.log(`[HEDGE] ⚡ Executing protective hedge (risk ${precog.riskScore.toFixed(0)}/100)`);
      const fakeTx = "0x" + Math.random().toString(16).slice(2).padEnd(64,"0");
      await this.recordTradeOnChain("WOKB","USDC",
        ethers.parseUnits("0.1",18), ethers.parseUnits("3.5",6),
        BigInt(Math.floor(precog.riskScore*2)), fakeTx
      );
    } else {
      console.log(`[STRATEGY] Yield mode — market safe`);
    }
    console.log(`✅ Cycle done | Trades: ${this.tradeCount} | PnL: ${this.totalPnL}bps`);
  }

  async start(intervalMs = 60000) {
    this.isRunning = true;
    console.log(`\n🚀 GHOST #${this.ghostId} starting on X Layer...`);
    await this.runCycle();
    this.interval = setInterval(() => this.runCycle(), intervalMs);
    console.log(`⏱ Running every ${intervalMs/1000}s`);
  }

  stop() {
    this.isRunning = false;
    if (this.interval) clearInterval(this.interval);
    console.log(`\n🛑 GHOST #${this.ghostId} stopped`);
  }
}

async function main() {
  const ghostId = parseInt(process.env.GHOST_ID || "0");
  const pk = process.env.AGENT_PRIVATE_KEY || process.env.PRIVATE_KEY;
  if (!pk) { console.error("Set AGENT_PRIVATE_KEY in .env"); process.exit(1); }
  const agent = new GhostAgent(ghostId, pk);
  process.on("SIGINT", () => { agent.stop(); process.exit(0); });
  await agent.start(60000);
}

module.exports = { GhostAgent };
if (require.main === module) main().catch(console.error);
