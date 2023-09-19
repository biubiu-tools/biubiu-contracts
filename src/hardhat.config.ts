import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    mainnet: { url: "https://cloudflare-eth.com" },
    bsc: { url: "https://bscrpc.com" },
  },
  etherscan: {
    apiKey: "",
  },
};

export default config;
