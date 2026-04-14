const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

const USDC_XLAYER = "0x74b7F16337b8972027F6196A17a631aC6dE26d22";

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const network = await hre.ethers.provider.getNetwork();
  const balance = await hre.ethers.provider.getBalance(deployer.address);

  console.log("\n🔮 GHOST — Deploying to X Layer");
  console.log("================================");
  console.log("Deployer:", deployer.address);
  console.log("Chain ID:", network.chainId.toString());
  console.log("OKB Balance:", hre.ethers.formatEther(balance), "OKB\n");

  if (balance === 0n) {
    console.error("❌ No OKB balance! Add OKB to your wallet first.");
    process.exit(1);
  }

  console.log("📋 Deploying GhostRegistry...");
  const GhostRegistry = await hre.ethers.getContractFactory("GhostRegistry");
  const registry = await GhostRegistry.deploy();
  await registry.waitForDeployment();
  const registryAddr = await registry.getAddress();
  console.log("✅ GhostRegistry:", registryAddr);

  console.log("\n⭐ Deploying GhostReputation...");
  const GhostReputation = await hre.ethers.getContractFactory("GhostReputation");
  const reputation = await GhostReputation.deploy(registryAddr);
  await reputation.waitForDeployment();
  const reputationAddr = await reputation.getAddress();
  console.log("✅ GhostReputation:", reputationAddr);

  console.log("\n💳 Deploying GhostRental...");
  const GhostRental = await hre.ethers.getContractFactory("GhostRental");
  const rental = await GhostRental.deploy(registryAddr, USDC_XLAYER);
  await rental.waitForDeployment();
  const rentalAddr = await rental.getAddress();
  console.log("✅ GhostRental:", rentalAddr);

  const deployment = {
    network: network.chainId.toString() === "196" ? "X Layer Mainnet" : "X Layer Testnet",
    chainId: network.chainId.toString(),
    deployedAt: new Date().toISOString(),
    deployer: deployer.address,
    contracts: {
      GhostRegistry: registryAddr,
      GhostReputation: reputationAddr,
      GhostRental: rentalAddr
    },
    external: { USDC: USDC_XLAYER },
    explorer: {
      GhostRegistry: `https://www.okx.com/explorer/xlayer/address/${registryAddr}`,
      GhostReputation: `https://www.okx.com/explorer/xlayer/address/${reputationAddr}`,
      GhostRental: `https://www.okx.com/explorer/xlayer/address/${rentalAddr}`
    }
  };

  fs.writeFileSync(path.join(__dirname, "../deployments.json"), JSON.stringify(deployment, null, 2));

  console.log("\n🎉 ALL CONTRACTS DEPLOYED!");
  console.log("===========================");
  console.log("GhostRegistry:  ", registryAddr);
  console.log("GhostReputation:", reputationAddr);
  console.log("GhostRental:    ", rentalAddr);
  console.log("\n🔗 Explorer Links:");
  console.log("Registry:   ", deployment.explorer.GhostRegistry);
  console.log("Reputation: ", deployment.explorer.GhostReputation);
  console.log("Rental:     ", deployment.explorer.GhostRental);
  console.log("\n✅ deployments.json saved!");
}

main().catch((e) => { console.error(e); process.exitCode = 1; });
