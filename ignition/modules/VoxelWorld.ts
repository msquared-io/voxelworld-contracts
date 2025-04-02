// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"

const sessionManagerAddress = "0xd820D0c488E13ded9a582aE187a8D7EAbD6FF50F"

// Define system addresses - empty means deploy new
const chunkSystemAddress = "0x3644a0A7f497853B9afbf2B3A4a1165D2ba36989"
const overlaySystemAddress = ""
const playerSystemAddress = ""
const inventorySystemAddress = ""
const craftingSystemAddress = ""
const userStatsSystemAddress = ""

const VoxelModule = buildModule("VoxelModule", (m) => {
  // Deploy or reference ChunkSystem
  const chunkSystem = chunkSystemAddress
    ? m.contractAt("ChunkSystem", chunkSystemAddress)
    : m.contract("ChunkSystem", [sessionManagerAddress])

  // Deploy or reference PlayerSystem
  const playerSystem = playerSystemAddress
    ? m.contractAt("PlayerSystem", playerSystemAddress)
    : m.contract("PlayerSystem", [sessionManagerAddress])

  // Deploy or reference InventorySystem
  const inventorySystem = inventorySystemAddress
    ? m.contractAt("InventorySystem", inventorySystemAddress)
    : m.contract("InventorySystem", [sessionManagerAddress])

  // Deploy or reference OverlaySystem
  const overlaySystem = overlaySystemAddress
    ? m.contractAt("OverlaySystem", overlaySystemAddress)
    : m.contract("OverlaySystem", [sessionManagerAddress, chunkSystem, inventorySystem])

  // Deploy or reference CraftingSystem
  const craftingSystem = craftingSystemAddress
    ? m.contractAt("CraftingSystem", craftingSystemAddress)
    : m.contract("CraftingSystem", [sessionManagerAddress, inventorySystem])

  // Deploy UserStatsSystem
  const userStatsSystem = userStatsSystemAddress
    ? m.contractAt("UserStatsSystem", userStatsSystemAddress)
    : m.contract("UserStatsSystem", [
        sessionManagerAddress,
        overlaySystem,
        playerSystem,
        craftingSystem,
        inventorySystem
      ])

  // Set up system references
  m.call(overlaySystem, "setUserStatsSystem", [userStatsSystem])
  m.call(playerSystem, "setUserStatsSystem", [userStatsSystem])
  m.call(craftingSystem, "setUserStatsSystem", [userStatsSystem])
  m.call(inventorySystem, "setUserStatsSystem", [userStatsSystem])

  // Deploy VoxelWorld
  const voxelWorld = m.contract("VoxelWorld", [
    chunkSystem,
    overlaySystem,
    playerSystem,
    inventorySystem,
    craftingSystem,
    userStatsSystem,
  ])

  return {
    voxelWorld,
    chunkSystem,
    overlaySystem,
    playerSystem,
    inventorySystem,
    craftingSystem,
    userStatsSystem,
  }
})

export default VoxelModule
