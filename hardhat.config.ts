import type { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox-viem"

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    localhost: {
      url: "http://localhost:8545",
    },
    somnia: {
      url: "https://dream-rpc.somnia.network/",
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
}

export default config
