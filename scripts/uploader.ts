import type { WalletClient, PublicClient, GetContractReturnType } from "viem"
import { privateKeyToAccount } from "viem/accounts"
import { somnia } from "./somnia" // or wherever your chain config is
import { BlockType } from "./block-types"
import { processMapDirectory } from "./convert-world"
import pLimit from "p-limit" // Add this for concurrency control
import { ChunkSystemAbi, ChunkSystemAddress } from "../abi"
import { http, createPublicClient, createWalletClient, getContract } from "viem"

/**
 * Partial or full ABI for the Voxel contract.
 * Only needs the functions we're going to call.
 */

interface ContractConfig {
  contractAddress: string
  providerUrl: string
  privateKey: `0x${string}`
  concurrencyLimit: number
  batchSize: number
  waitForConfirmations: boolean
  mapDirectory: string
  originX: number
  originZ: number
  minX: number
  maxX: number
  minY: number
  maxY: number
  minZ: number
  maxZ: number
}

interface Args {
  mapDirectory?: string
}

// Example: parse command-line args
function parseArgs() {
  const args = process.argv.slice(2)
  const result: Record<string, string> = {}
  for (let i = 0; i < args.length; i += 2) {
    if (args[i].startsWith("--")) {
      const key = args[i].slice(2)
      result[key] = args[i + 1]
    }
  }
  return result
}

const args = parseArgs()

// Blockchain / contract config
const contractConfig = {
  // contractAddress: ChunkSystemAddress,
  contractAddress: "",
  providerUrl: args.provider,
  privateKey:
    args.privateKey ||
    process.env.PRIVATE_KEY ||
    "0x0000000000000000000000000000000000000000000000000000000000000000",
  mapDirectory:
    args.mapDirectory || "/Users/mont/voxelworld-contracts/scripts/map", // Add map directory config
  originX: args.originX ? Number(args.originX) : undefined, // X coordinate to use as origin
  originZ: args.originZ ? Number(args.originZ) : undefined, // Z coordinate to use as origin
  minX: args.minX ? Number(args.minX) : undefined, // Minimum X chunk index to process (relative to origin)
  maxX: args.maxX ? Number(args.maxX) : undefined, // Maximum X chunk index to process (relative to origin)
  minY: args.minY ? Number(args.minY) : 0, // Minimum Y chunk index to process (defaults to 0)
  maxY: args.maxY ? Number(args.maxY) : 16, // Maximum Y chunk index to process (defaults to 16)
  minZ: args.minZ ? Number(args.minZ) : undefined, // Minimum Z chunk index to process (relative to origin)
  maxZ: args.maxZ ? Number(args.maxZ) : undefined, // Maximum Z chunk index to process (relative to origin)
  concurrencyLimit: args.concurrency ? Number(args.concurrency) : 10, // Number of concurrent transactions
  batchSize: args.batchSize ? Number(args.batchSize) : 10, // How many chunks to process in a batch before waiting
  waitForConfirmations: args.waitForConfirmations === "true", // Whether to wait for confirmations
}

// This class handles the *uploading* of chunk data to the chain.
// It relies on the vdat file converter to produce the data.
class VoxelUploader {
  private publicClient: PublicClient
  private walletClient: WalletClient
  private account: ReturnType<typeof privateKeyToAccount>
  private currentNonce = 0
  private chunkExistsCache: Map<string, boolean> = new Map() // Cache for chunk existence checks
  private chunkHasDataCache: Map<string, boolean> = new Map() // Cache for chunks that have data
  private limit: ReturnType<typeof pLimit> // Concurrency limiter
  private pendingTxs: Promise<unknown>[] = [] // Track pending transactions
  private txCount = 0 // Counter for transactions
  private config: ContractConfig
  private contract: GetContractReturnType<
    typeof ChunkSystemAbi,
    PublicClient | WalletClient
  >

  constructor(config: ContractConfig) {
    this.config = config
    this.account = privateKeyToAccount(config.privateKey as `0x${string}`)

    const transport = http(config.providerUrl)
    this.publicClient = createPublicClient({ chain: somnia, transport })
    this.walletClient = createWalletClient({
      chain: somnia,
      transport,
      account: this.account,
    })

    this.contract = getContract({
      address: config.contractAddress as `0x${string}`,
      abi: ChunkSystemAbi,
      client: {
        public: this.publicClient,
        wallet: this.walletClient,
      },
    })

    // Initialize concurrency limiter
    this.limit = pLimit(config.concurrencyLimit)
  }

  /**
   * Initializes the currentNonce to whatever the chain's next nonce is.
   */
  public async initNonce() {
    this.currentNonce = Number(
      await this.publicClient.getTransactionCount({
        address: this.account.address,
      }),
    )
    console.log(`Starting with nonce: ${this.currentNonce}`)
  }

  /**
   * Get a unique string key for a chunk coordinates
   */
  private getChunkKey(chunkX: number, chunkY: number, chunkZ: number): string {
    return `${chunkX},${chunkY},${chunkZ}`
  }

  /** Check if chunk is already created. If not, create it. */
  private async ensureChunkCreated(
    chunkX: number,
    chunkY: number,
    chunkZ: number,
  ) {
    const chunkKey = this.getChunkKey(chunkX, chunkY, chunkZ)

    // Check cache first
    if (this.chunkExistsCache.has(chunkKey)) {
      if (this.chunkExistsCache.get(chunkKey)) {
        return // Chunk already exists
      }
    } else {
      // Not in cache, check the blockchain
      const exists = await this.contract.read.chunkExists([
        chunkX,
        chunkY,
        chunkZ,
      ])

      // Update cache
      this.chunkExistsCache.set(chunkKey, exists)

      if (exists) {
        return // Chunk already exists
      }
    }

    // Chunk doesn't exist, create it
    console.log(`Creating chunk at (${chunkX}, ${chunkY}, ${chunkZ})`)

    // Create a promise for the transaction
    const txPromise = (async () => {
      try {
        const txHash = await this.contract.write.createChunk(
          [chunkX, chunkY, chunkZ],
          {
            nonce: this.currentNonce++,
            account: this.account,
            chain: somnia,
            gas: 7_920_027n,
          },
        )

        console.log(
          `createChunk tx sent: hash=${txHash}, nonce=${this.currentNonce - 1}`,
        )
        this.txCount++

        // Update cache optimistically
        this.chunkExistsCache.set(chunkKey, true)

        if (this.config.waitForConfirmations) {
          return await this.publicClient.waitForTransactionReceipt({
            hash: txHash,
            timeout: 60_000,
            confirmations: 1,
          })
        }
        return txHash
      } catch (error) {
        console.error(
          `Error creating chunk (${chunkX}, ${chunkY}, ${chunkZ}):`,
          error,
        )
        throw error
      }
    })()

    // Add to pending transactions
    this.pendingTxs.push(txPromise)

    // Wait for transaction batches
    if (this.txCount % this.config.batchSize === 0) {
      await this.waitForPendingTransactions()
    }
  }

  /**
   * Creates RLE data for an empty chunk (all air blocks)
   * @returns RLE data for an empty chunk as a hex string
   */
  private getEmptyChunkRLE(): `0x${string}` {
    // In RLE format, an empty chunk is a single run of 4096 AIR blocks
    // Format: [countHighByte, countLowByte, blockType]
    // 4096 = 0x1000, so [0x10, 0x00, 0x00] for all AIR blocks
    return "0x100000" as `0x${string}`
  }

  /**
   * Takes chunk data (positions & blockTypes) and RLE-encodes it,
   * then calls setChunkData on the contract.
   */
  private async setChunkData(
    chunkX: number,
    chunkY: number,
    chunkZ: number,
    positions: number[],
    blockTypes: number[],
  ) {
    let hexString: `0x${string}`

    // If positions array is empty, this is an empty chunk
    if (positions.length === 0) {
      console.log(`Setting chunk (${chunkX}, ${chunkY}, ${chunkZ}) to empty.`)
      hexString = this.getEmptyChunkRLE()
    } else {
      // Reconstruct 16x16x16 grid to ensure consistent RLE
      const blockGrid: number[][][] = []
      for (let y = 0; y < 16; y++) {
        blockGrid[y] = []
        for (let z = 0; z < 16; z++) {
          blockGrid[y][z] = new Array(16).fill(BlockType.AIR)
        }
      }

      for (let i = 0; i < positions.length; i++) {
        const posHash = positions[i]
        const btype = blockTypes[i]
        // Fix the position decoding to match the encoding in extractYChunk
        // Original encoding: (x << 12) | (localY << 4) | z
        const x = (posHash >> 12) & 0xf // Extract the x component (bits 12-15)
        const y = (posHash >> 4) & 0xff // Extract the y component (bits 4-11)
        const z = posHash & 0xf // Extract the z component (bits 0-3)
        blockGrid[y][z][x] = btype
      }

      // Flatten into a single array in YZx order
      const flatBlocks: number[] = []
      for (let y = 0; y < 16; y++) {
        for (let z = 0; z < 16; z++) {
          for (let x = 0; x < 16; x++) {
            flatBlocks.push(blockGrid[y][z][x])
          }
        }
      }

      // RLE encode: [countHighByte, countLowByte, blockType, ...]
      const rleData: number[] = []
      let runBlock = flatBlocks[0]
      let runCount = 1

      for (let i = 1; i < flatBlocks.length; i++) {
        const currentBlock = flatBlocks[i]
        if (currentBlock === runBlock && runCount < 65535) {
          runCount++
        } else {
          // push run
          rleData.push((runCount >> 8) & 0xff)
          rleData.push(runCount & 0xff)
          rleData.push(runBlock)
          runBlock = currentBlock
          runCount = 1
        }
      }
      // final run
      rleData.push((runCount >> 8) & 0xff)
      rleData.push(runCount & 0xff)
      rleData.push(runBlock)

      hexString = `0x${rleData.map((b) => b.toString(16).padStart(2, "0")).join("")}`

      console.log(
        `Setting chunk data (${chunkX},${chunkY},${chunkZ}) with RLE length ${rleData.length}...`,
      )
    }

    // Create a promise for the transaction
    const txPromise = (async () => {
      try {
        const txHash = await this.contract.write.setChunkData(
          [chunkX, chunkY, chunkZ, hexString as `0x${string}`],
          {
            nonce: this.currentNonce++,
            account: this.account,
            chain: somnia,
            gas: 7_920_027n,
          },
        )

        console.log(
          `setChunkData tx sent: hash=${txHash}, nonce=${this.currentNonce - 1}`,
        )
        this.txCount++

        if (this.config.waitForConfirmations) {
          const receipt = await this.publicClient.waitForTransactionReceipt({
            hash: txHash,
            timeout: 60_000,
            confirmations: 1,
          })

          if (receipt.status === "reverted") {
            console.error(`Transaction reverted! Hash: ${txHash}`)
            throw new Error(`Transaction reverted: ${txHash}`)
          }

          return receipt
        }
        return txHash
      } catch (error) {
        console.error(
          `Error setting chunk data (${chunkX}, ${chunkY}, ${chunkZ}):`,
          error,
        )
        throw error
      }
    })()

    // Add to pending transactions
    this.pendingTxs.push(txPromise)

    // Wait for transaction batches
    if (this.txCount % this.config.batchSize === 0) {
      await this.waitForPendingTransactions()
    }
  }

  /**
   * Wait for pending transactions to complete
   */
  private async waitForPendingTransactions() {
    if (this.pendingTxs.length === 0) return

    console.log(
      `Waiting for ${this.pendingTxs.length} pending transactions to complete...`,
    )
    const startTime = Date.now()

    try {
      await Promise.all(this.pendingTxs)
      console.log(
        `All transactions completed in ${(Date.now() - startTime) / 1000} seconds`,
      )
    } catch (error) {
      console.error("Error in transaction batch:", error)
    }

    // Clear the pending transactions
    this.pendingTxs = []
  }

  /**
   * Check if a chunk has data (non-empty RLE data)
   */
  private async chunkHasData(chunkX: number, chunkY: number, chunkZ: number): Promise<boolean> {
    const chunkKey = this.getChunkKey(chunkX, chunkY, chunkZ)

    // Check cache first
    if (this.chunkHasDataCache.has(chunkKey)) {
      return this.chunkHasDataCache.get(chunkKey)!
    }

    try {
      // Check if chunk exists first
      const exists = await this.contract.read.chunkExists([chunkX, chunkY, chunkZ])
      if (!exists) {
        this.chunkHasDataCache.set(chunkKey, false)
        return false
      }

      // Get the chunk data
      const data = await this.contract.read.getChunkData([chunkX, chunkY, chunkZ])
      
      // Empty chunk has RLE data of [0x10, 0x00, 0x00] (4096 air blocks)
      const hasData = data !== "0x100000"
      
      // Update cache
      this.chunkHasDataCache.set(chunkKey, hasData)
      return hasData
    } catch (error) {
      console.error(`Error checking chunk data (${chunkX}, ${chunkY}, ${chunkZ}):`, error)
      return false
    }
  }

  /**
   * Process chunk data for a specific position concurrently
   */
  private async processChunk(
    chunkX: number,
    chunkY: number,
    chunkZ: number,
    dataChunkX: number,
    dataChunkZ: number,
    chunkDataMap: Map<
      string,
      Map<number, { positions: number[]; blockTypes: number[] }>
    >,
  ) {
    return this.limit(async () => {
      // Check if chunk already has data
      const hasData = await this.chunkHasData(chunkX, chunkY, chunkZ)
      if (hasData) {
        console.log(`Skipping chunk (${chunkX}, ${chunkY}, ${chunkZ}) - already has data`)
        return { uploaded: false, empty: false }
      }

      // Get the column key (using data coordinates for lookup)
      const columnKey = `${dataChunkX},${dataChunkZ}`

      // Skip if this column doesn't exist in our data
      if (!chunkDataMap.has(columnKey)) {
        // Create empty chunk
        await this.ensureChunkCreated(chunkX, chunkY, chunkZ)
        return { uploaded: true, empty: true }
      }

      // Get all Y-chunks for this column
      const yChunks = chunkDataMap.get(columnKey) as Map<
        number,
        { positions: number[]; blockTypes: number[] }
      >

      // Check if this specific Y value exists in the data
      if (!yChunks.has(chunkY)) {
        // Create empty chunk
        await this.ensureChunkCreated(chunkX, chunkY, chunkZ)
        return { uploaded: true, empty: true }
      }

      // Get the chunk data for this Y level
      const chunkData = yChunks.get(chunkY) as {
        positions: number[]
        blockTypes: number[]
      }
      const { positions, blockTypes } = chunkData

      // Skip empty chunks (still need to create them)
      if (positions.length === 0) {
        await this.ensureChunkCreated(chunkX, chunkY, chunkZ)
        return { uploaded: true, empty: true }
      }

      // Check if chunk exists before deciding to upload or skip
      await this.ensureChunkCreated(chunkX, chunkY, chunkZ)

      // Set chunk data
      console.log(
        `Uploading chunk (${dataChunkX}, ${chunkY}, ${dataChunkZ}) as (${chunkX}, ${chunkY}, ${chunkZ}) with ${positions.length} blocks...`,
      )
      await this.setChunkData(chunkX, chunkY, chunkZ, positions, blockTypes)

      return { uploaded: true, empty: false }
    })
  }

  /**
   * Handles generating (via WorldGenerator) and uploading
   * the entire 3D region of chunks.
   */
  public async generateAndUploadWorld() {
    console.log(`Processing map directory: ${this.config.mapDirectory}`)

    // Process the map directory to get all chunk data
    const chunkDataMap = processMapDirectory(this.config.mapDirectory)
    console.log(
      `Processed ${chunkDataMap.size} chunk columns from map directory`,
    )

    // Calculate chunk coordinates range from available chunks
    let dataMinX = Number.POSITIVE_INFINITY
    let dataMaxX = Number.NEGATIVE_INFINITY
    let dataMinZ = Number.POSITIVE_INFINITY
    let dataMaxZ = Number.NEGATIVE_INFINITY

    for (const key of chunkDataMap.keys()) {
      const [x, z] = key.split(",").map(Number)
      dataMinX = Math.min(dataMinX, x)
      dataMaxX = Math.max(dataMaxX, x)
      dataMinZ = Math.min(dataMinZ, z)
      dataMaxZ = Math.max(dataMaxZ, z)
    }

    console.log(
      `Available data bounds: X(${dataMinX}..${dataMaxX}), Z(${dataMinZ}..${dataMaxZ})`,
    )

    // Calculate origin chunk coordinates (floor of world coordinates)
    let originChunkX = 0
    let originChunkZ = 0

    if (
      this.config.originX !== undefined &&
      this.config.originZ !== undefined
    ) {
      // Convert world coordinates to chunk coordinates by flooring
      originChunkX = Math.floor(this.config.originX / 16)
      originChunkZ = Math.floor(this.config.originZ / 16)
      console.log(
        `Using origin point (${this.config.originX}, ${this.config.originZ}) => chunk (${originChunkX}, ${originChunkZ}) as (0,0)`,
      )
    }

    // Determine the chunk range to process - either from minX/maxX parameters or from data bounds
    const minX =
      this.config.minX !== undefined
        ? this.config.minX
        : dataMinX - originChunkX
    const maxX =
      this.config.maxX !== undefined
        ? this.config.maxX
        : dataMaxX - originChunkX
    const minY = this.config.minY // Already defaults to 0 in config
    const maxY = this.config.maxY // Already defaults to 16 in config
    const minZ =
      this.config.minZ !== undefined
        ? this.config.minZ
        : dataMinZ - originChunkZ
    const maxZ =
      this.config.maxZ !== undefined
        ? this.config.maxZ
        : dataMaxZ - originChunkZ

    console.log(
      `Processing chunks in range: X(${minX}..${maxX}), Y(${minY}..${maxY}), Z(${minZ}..${maxZ}) relative to origin`,
    )

    // Track statistics
    let chunksUploaded = 0
    let chunksSkipped = 0 // Changed from const to let
    const startTime = Date.now()
    const chunkPromises: Promise<{ uploaded: boolean; empty: boolean }>[] = []

    // Create a queue of chunks to process
    const chunkQueue: [number, number, number, number, number][] = []

    // Fill the queue with all chunks to process
    for (let relativeX = minX; relativeX <= maxX; relativeX++) {
      for (let relativeZ = minZ; relativeZ <= maxZ; relativeZ++) {
        // Get the actual data coordinates by applying the origin offset
        const dataChunkX = relativeX + originChunkX
        const dataChunkZ = relativeZ + originChunkZ

        for (let relativeY = minY; relativeY <= maxY; relativeY++) {
          chunkQueue.push([
            relativeX,
            relativeY,
            relativeZ,
            dataChunkX,
            dataChunkZ,
          ])
        }
      }
    }

    console.log(`Added ${chunkQueue.length} chunks to processing queue`)

    // Process chunks in chunks to avoid memory issues
    const chunkBatchSize = 100 // Process 100 chunks at a time
    let processedChunks = 0

    while (processedChunks < chunkQueue.length) {
      const batch = chunkQueue.slice(
        processedChunks,
        processedChunks + chunkBatchSize,
      )
      const batchPromises = batch.map(
        ([relativeX, relativeY, relativeZ, dataChunkX, dataChunkZ]) =>
          this.processChunk(
            relativeX,
            relativeY,
            relativeZ,
            dataChunkX,
            dataChunkZ,
            chunkDataMap,
          ),
      )

      console.log(
        `Processing batch ${processedChunks} to ${processedChunks + batch.length} of ${chunkQueue.length}`,
      )

      // Wait for this batch to complete
      const results = await Promise.all(batchPromises)

      // Update statistics
      for (const result of results) {
        if (result.uploaded) {
          chunksUploaded++
        } else {
          chunksSkipped++
        }
      }

      // Display progress
      processedChunks += batch.length
      const elapsedTime = (Date.now() - startTime) / 1000
      const chunksPerSecond = processedChunks / elapsedTime
      const estimatedTotalTime = chunkQueue.length / chunksPerSecond
      const remainingTime = estimatedTotalTime - elapsedTime

      console.log(
        `Progress: ${processedChunks}/${chunkQueue.length} (${((processedChunks / chunkQueue.length) * 100).toFixed(2)}%)`,
      )
      console.log(`Speed: ${chunksPerSecond.toFixed(2)} chunks/second`)
      console.log(
        `Estimated time remaining: ${(remainingTime / 60).toFixed(2)} minutes`,
      )

      // Make sure all pending transactions are processed
      await this.waitForPendingTransactions()
    }

    // Final wait for any remaining transactions
    await this.waitForPendingTransactions()

    const totalTime = (Date.now() - startTime) / 1000
    console.log(`World upload completed in ${totalTime.toFixed(2)} seconds!`)
    console.log(`Uploaded: ${chunksUploaded}, Skipped: ${chunksSkipped}`)
    console.log(
      `Average speed: ${(chunkQueue.length / totalTime).toFixed(2)} chunks/second`,
    )
  }
}

// Main entry
async function main() {
  console.log("Starting Voxel World Uploader...")

  if (!args.mapDirectory) {
    console.log("Warning: No map directory specified, using default './map'")
  }

  const uploader = new VoxelUploader(
    contractConfig as unknown as ContractConfig,
  )
  await uploader.initNonce()
  await uploader.generateAndUploadWorld()
}

main().catch(console.error)
