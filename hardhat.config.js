require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  paths: {
    sources: "./contracts",
    artifacts: "./artifacts",
  },
  networks: {
    ethereum: {
      url: `https://eth.llamarpc.com`,
      accounts: [process.env.PRIVATE_KEY]
    },
    polygon: {
      url: "https://polygon-rpc.com",
      accounts: [process.env.PRIVATE_KEY]
    },
    bsc: {
      url: "https://rpc-bsc.48.club",
      accounts: [process.env.PRIVATE_KEY]
    },
    arbitrum: {
      url: "https://arb1.arbitrum.io/rpc",
      accounts: [process.env.PRIVATE_KEY]
    },
    optimism: {
      url: "https://mainnet.optimism.io",
      accounts: [process.env.PRIVATE_KEY]
    },
    base: {
      url: "https://mainnet.base.org",
      accounts: [process.env.PRIVATE_KEY]
    },
    avalanche: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY]
    },
  }
};
