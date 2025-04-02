// just the etherbase deploy step

import hre from "hardhat"
import { registerWithEtherbase } from "../utils/utils"
import {
  VoxelWorldAddress,
  ChunkSystemAddress,
  OverlaySystemAddress,
  PlayerSystemAddress,
  InventorySystemAddress,
  CraftingSystemAddress,
} from "../../abi"

const etherbaseAddress = "0x693FecBA7186f21A5497718AB88e1BC5A15C4960"

async function main() {
  // Create a map of contract names to their deployments
  const contractMap = {
    voxelWorld: {
      address: VoxelWorldAddress,
      artifact: "VoxelWorld"
    },
    chunkSystem: {
      address: ChunkSystemAddress,
      artifact: "ChunkSystem"
    },
    overlaySystem: {
      address: OverlaySystemAddress,
      artifact: "OverlaySystem"
    },
    playerSystem: {
      address: PlayerSystemAddress,
      artifact: "PlayerSystem"
    },
    inventorySystem: {
      address: InventorySystemAddress,
      artifact: "InventorySystem"
    },
    craftingSystem: {
      address: CraftingSystemAddress,
      artifact: "CraftingSystem"
    }
  }

  // Convert to format expected by registerWithEtherbase
  const deployedContracts = Object.entries(contractMap).reduce((acc, [name, info]) => {
    acc[name] = {
      address: info.address,
      artifactName: info.artifact
    }
    return acc
  }, {} as Record<string, { address: string, artifactName: string }>)

  // Register all contracts with Etherbase
  await registerWithEtherbase(deployedContracts, etherbaseAddress)

  console.log("Contracts registered with Etherbase successfully!")
}

main().catch(console.error)

