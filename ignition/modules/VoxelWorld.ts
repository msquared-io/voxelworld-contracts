// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules"

const sessionManagerAddress = "0xd820D0c488E13ded9a582aE187a8D7EAbD6FF50F"

// Define system addresses - empty means deploy new
// const chunkSystemAddress = "0x9F0A447e8AE082cc9b5dD7CFcD0DC13506827f7e"
// const overlaySystemAddress = "0x6Ba62e00f5244be330b3629A4fb920e08134A7fa"
// const playerSystemAddress = "0xD87CC0EA6dA87366D481dceA38EAD41FC250e4AE"
// const inventorySystemAddress = "0x962E6044A850Cd7F35cB11Ae3185ef02de1aE7DA"
const chunkSystemAddress = "0x3644a0A7f497853B9afbf2B3A4a1165D2ba36989"
const overlaySystemAddress = "0x4D5b572E9554EF3D71a745f74688790eA3C860C0"
const playerSystemAddress = "0x8b7110b2c317C05Ce0b2A13A8c003DF1eC94a75A"
const inventorySystemAddress = "0x42ee6f3Ef643524d3184BB6BF68763C8F966E84F"
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
        craftingSystem,
        inventorySystem,
        playerSystem
      ])

  // Set up system references
  // m.call(overlaySystem, "setUserStatsSystem", [userStatsSystem])
  // m.call(playerSystem, "setUserStatsSystem", [userStatsSystem])
  m.call(craftingSystem, "setUserStatsSystem", [userStatsSystem])
  // m.call(inventorySystem, "setUserStatsSystem", [userStatsSystem])
  m.call(inventorySystem, "setSystemAddresses", [craftingSystem, overlaySystem])

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
