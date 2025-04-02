import type { ContractDeployment } from "@nomicfoundation/hardhat-ignition/types"
import type { Address, Abi } from "viem"
import { getAddress, parseAbi } from "viem"
import { promises as fs } from "node:fs"
import { join } from "node:path"
import { deflateSync } from "node:zlib"
import hre from "hardhat"
import { etherbaseAbi } from "./etherbaseAbi"

interface ContractInfo {
  name: string
  address: string
  abi: any
}

/**
 * Saves contract ABIs and addresses as TypeScript files with a central index
 * @param contractMap Record of contract name to contract deployment from Ignition
 * @param outputDir The directory where the ABI and address files should be saved
 */
export async function saveContractInfo(
  contractMap: Record<string, ContractDeployment>,
  outputDir: string,
): Promise<void> {
  // Create the output directory if it doesn't exist
  await fs.mkdir(outputDir, { recursive: true })

  const contractInfos: ContractInfo[] = []

  // Process each contract
  for (const [name, contract] of Object.entries(contractMap)) {
    const properName = name.charAt(0).toUpperCase() + name.slice(1)
    const artifact = await hre.artifacts.readArtifact(properName)

    const contractInfo: ContractInfo = {
      name: artifact.contractName,
      address: contract.address as string,
      abi: artifact.abi,
    }
    contractInfos.push(contractInfo)

    // Save individual ABI file
    const abiContent = `// Auto-generated ABI file for ${artifact.contractName}
export const ${artifact.contractName}Abi = ${JSON.stringify(artifact.abi, null, 2)} as const;
`
    await fs.writeFile(
      join(outputDir, `${artifact.contractName}Abi.ts`),
      abiContent,
    )

    // Save individual address file
    const addressContent = `// Auto-generated address file for ${artifact.contractName}
export const ${artifact.contractName}Address = "${contract.address}" as const;
`
    await fs.writeFile(
      join(outputDir, `${artifact.contractName}Address.ts`),
      addressContent,
    )
  }

  // Generate index.ts
  let indexContent =
    "// Auto-generated index file for contract ABIs and addresses\n\n"

  for (const info of contractInfos) {
    indexContent += `export { ${info.name}Abi } from "./${info.name}Abi";\n`
    indexContent += `export { ${info.name}Address } from "./${info.name}Address";\n`
  }

  await fs.writeFile(join(outputDir, "index.ts"), indexContent)
  console.log(`Contract information saved to: ${outputDir}`)
}

/**
 * Registers multiple contracts with the Etherbase contract if they aren't already registered
 * @param contractMap Record of contract name to contract deployment from Ignition
 * @param etherbaseAddress The address of the Etherbase contract
 */
export async function registerWithEtherbase(
  contractMap: Record<string, ContractDeployment>,
  etherbaseAddress: Address,
): Promise<void> {
  const [account] = await hre.viem.getWalletClients()
  const publicClient = await hre.viem.getPublicClient()

  for (const [name, contract] of Object.entries(contractMap)) {
    const properName = name.charAt(0).toUpperCase() + name.slice(1)
    const artifact = await hre.artifacts.readArtifact(properName)
    const abiString = JSON.stringify(artifact.abi)
    // const compressedAbiString = deflateSync(abiString).toString('base64')

    console.log(
      `Checking if contract ${artifact.contractName} is already registered...`,
    )

    try {
      // Try to get the contract - if it exists, this will succeed
      await publicClient.readContract({
        address: getAddress(etherbaseAddress),
        abi: etherbaseAbi,
        functionName: "getCustomContract",
        args: [contract.address as Address],
      })

      console.log(
        `Contract ${artifact.contractName} is already registered, skipping...`,
      )
    } catch (error) {
      // If we get here, the contract doesn't exist and needs to be added
      console.log(
        `Registering contract ${artifact.contractName} with Etherbase at ${etherbaseAddress}...`,
      )

      const hash = await account.writeContract({
        address: getAddress(etherbaseAddress),
        abi: etherbaseAbi,
        functionName: "addCustomContract",
        args: [contract.address as Address, abiString],
      })

      console.log(`Registration transaction sent. Transaction hash: ${hash}`)

      const receipt = await publicClient.waitForTransactionReceipt({ hash })
      console.log(
        `Contract ${artifact.contractName} registered successfully. Transaction confirmed in block ${receipt.blockNumber}.`,
      )
    }
  }
}
