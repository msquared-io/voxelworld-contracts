import VoxelWorldModule from "../modules/VoxelWorld"
import hre from "hardhat"
import { saveContractInfo, registerWithEtherbase } from "../utils/utils"
import { join } from "node:path"

const etherbaseAddress = "0x693FecBA7186f21A5497718AB88e1BC5A15C4960"
async function main() {
  // Deploy all contracts
  const deployedContracts = await hre.ignition.deploy(VoxelWorldModule)

  // Save all contract ABIs and addresses
  const abiPath = join(__dirname, "..", "..", "abi")
  await saveContractInfo(deployedContracts, abiPath)

  // Register all contracts with Etherbase
  await registerWithEtherbase(deployedContracts, etherbaseAddress)

  console.log("Contracts deployed successfully!")
}

main().catch(console.error)
