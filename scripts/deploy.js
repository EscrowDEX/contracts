// npx hardhat run scripts/deploy.js --network avalanche

const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    const network = hre.network.name;

    console.log(`Deploying on ${network} with account: ${deployer.address}`);
    console.log(`Balance: ${hre.ethers.utils.formatEther(await deployer.getBalance())} ETH`);

    const Escrow = await hre.ethers.getContractFactory("Escrow");
    const escrow = await Escrow.deploy();
    await escrow.deployed();

    console.log(`Escrow deployed at: ${escrow.address}`);
    const deploymentsPath = path.resolve(__dirname, "..", "deployments.json");

    let deployments = {};
    if (fs.existsSync(deploymentsPath)) {
        deployments = JSON.parse(fs.readFileSync(deploymentsPath));
    }

    deployments[network] = {
        address: escrow.address,
        deployedAt: new Date().toISOString()
    };

    fs.writeFileSync(deploymentsPath, JSON.stringify(deployments, null, 2));
    console.log(`Saved to deployments.json under '${network}'`);
}

main().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
});
