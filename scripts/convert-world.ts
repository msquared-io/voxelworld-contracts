import fs from "fs"
import path from "path"
import { BlockType } from "./block-types"

// Interface for the return value
export interface ChunkData {
  positions: number[]
  blockTypes: BlockType[]
}

// Constants for chunk dimensions
const CHUNK_SIZE_X = 16
const CHUNK_SIZE_Y = 16 // Y-chunk height (we'll split the 0-256 range into 16-block chunks)
const CHUNK_SIZE_Z = 16
const MINECRAFT_HEIGHT = 256 // Total height of a Minecraft world
const CHUNKS_PER_COLUMN = Math.ceil(MINECRAFT_HEIGHT / CHUNK_SIZE_Y) // Number of Y-chunks per column

/**
 * Reads a voxel data file and converts it to a 3D array of block types
 * @param filePath Path to the .vdat file
 * @returns 3D array representing the full column of blocks
 */
function readVoxelData(filePath: string): number[][][] {
  try {
    // Read the file bytes
    const bytes = fs.readFileSync(filePath)

    // Create a 3D array to store the voxel data for the entire column
    const voxelData: number[][][] = Array(CHUNK_SIZE_X)
      .fill(0)
      .map(() =>
        Array(MINECRAFT_HEIGHT)
          .fill(0)
          .map(() => Array(CHUNK_SIZE_Z).fill(0)),
      )

    // Parse the bytes into the 3D array
    let byteIndex = 0
    for (let x = 0; x < CHUNK_SIZE_X; ++x) {
      for (let y = 0; y < MINECRAFT_HEIGHT; ++y) {
        for (let z = 0; z < CHUNK_SIZE_Z; ++z) {
          if (byteIndex < bytes.length) {
            voxelData[x][y][z] = bytes[byteIndex]
            ++byteIndex
          }
        }
      }
    }

    return voxelData
  } catch (error) {
    console.error(`Error reading file ${filePath}:`, error)
    // Return an empty voxel data array if there's an error
    return Array(CHUNK_SIZE_X)
      .fill(0)
      .map(() =>
        Array(MINECRAFT_HEIGHT)
          .fill(0)
          .map(() => Array(CHUNK_SIZE_Z).fill(0)),
      )
  }
}

/**
 * Extracts blocks for a specific Y-chunk from the full column data
 * @param voxelData Full column voxel data (16x256x16)
 * @param chunkY Y-chunk index (0-15 for 16-block height chunks)
 * @returns Object containing positions and blockTypes arrays for the Y-chunk
 */
function extractYChunk(voxelData: number[][][], chunkY: number): ChunkData {
  const positions: number[] = []
  const blockTypes: BlockType[] = []

  // Calculate the Y range for this chunk
  const yStart = chunkY * CHUNK_SIZE_Y
  const yEnd = Math.min(yStart + CHUNK_SIZE_Y, MINECRAFT_HEIGHT)

  // Extract blocks within this Y-chunk range
  for (let x = 0; x < CHUNK_SIZE_X; ++x) {
    for (let y = yStart; y < yEnd; ++y) {
      for (let z = 0; z < CHUNK_SIZE_Z; ++z) {
        const blockType = voxelData[x][y][z]
        if (blockType !== 0) {
          // Skip air blocks
          // Calculate the local Y coordinate within this chunk
          const localY = y - yStart

          // Calculate the position index using RLE encoding format
          // Position is (x,y,z) within the chunk, converted to a single number
          const positionIndex = (x << 12) | (localY << 4) | z

          positions.push(positionIndex)
          blockTypes.push(blockType)
        }
      }
    }
  }

  return { positions, blockTypes }
}

/**
 * Reads a voxel data file and splits it into Y-chunks
 * @param filePath Path to the .vdat file
 * @param chunkX X coordinate of the chunk
 * @param chunkZ Z coordinate of the chunk
 * @returns Map of Y-indices to chunk data
 */
export function convertVdatFile(
  filePath: string,
  chunkX: number,
  chunkZ: number,
): Map<number, ChunkData> {
  console.log(`Processing vdat file: ${filePath}`)

  // Read the full column of voxel data
  const voxelData = readVoxelData(filePath)

  // Split the column into Y-chunks
  const yChunks = new Map<number, ChunkData>()

  for (let chunkY = 0; chunkY < CHUNKS_PER_COLUMN; chunkY++) {
    const chunkData = extractYChunk(voxelData, chunkY)

    // Only store non-empty chunks
    if (chunkData.positions.length > 0) {
      yChunks.set(chunkY, chunkData)
      console.log(
        `  Chunk (${chunkX}, ${chunkY}, ${chunkZ}): ${chunkData.positions.length} blocks`,
      )
    }
  }

  return yChunks
}

/**
 * Scans a directory recursively for vdat files
 * @param directoryPath The directory to scan
 * @returns Array of objects with filePath, chunkX, and chunkZ
 */
export function findVdatFiles(
  directoryPath: string,
): { filePath: string; chunkX: number; chunkZ: number }[] {
  const results: { filePath: string; chunkX: number; chunkZ: number }[] = []

  // Check if directory exists
  if (!fs.existsSync(directoryPath)) {
    console.error(`Directory not found: ${directoryPath}`)
    return results
  }

  // Get all items in the directory
  const items = fs.readdirSync(directoryPath)

  for (const item of items) {
    const itemPath = path.join(directoryPath, item)
    const stat = fs.statSync(itemPath)

    if (stat.isDirectory()) {
      // Check if this is a region directory (r.X.Z)
      const regionMatch = item.match(/^r\.(\-?\d+)\.(\-?\d+)$/)
      if (regionMatch) {
        const regionX = parseInt(regionMatch[1], 10)
        const regionZ = parseInt(regionMatch[2], 10)

        // Look for vdat files in this region directory
        const regionItems = fs.readdirSync(itemPath)
        for (const regionItem of regionItems) {
          const regionItemPath = path.join(itemPath, regionItem)
          const regionItemStat = fs.statSync(regionItemPath)

          if (
            regionItemStat.isFile() &&
            regionItem.match(/^c\.\-?\d+\.\-?\d+\.vdat$/)
          ) {
            // Extract local chunk coordinates from filename (c.X.Z.vdat)
            const chunkMatch = regionItem.match(/^c\.(\-?\d+)\.(\-?\d+)\.vdat$/)
            if (chunkMatch) {
              const localChunkX = parseInt(chunkMatch[1], 10)
              const localChunkZ = parseInt(chunkMatch[2], 10)

              // Calculate global chunk coordinates based on region
              // Each region is 32x32 chunks
              const globalChunkX = regionX * 32 + localChunkX
              const globalChunkZ = regionZ * 32 + localChunkZ

              results.push({
                filePath: regionItemPath,
                chunkX: globalChunkX,
                chunkZ: globalChunkZ,
              })
            }
          }
        }
      } else {
        // Recursively search other subdirectories
        results.push(...findVdatFiles(itemPath))
      }
    } else if (stat.isFile() && item.match(/^c\.\-?\d+\.\-?\d+\.vdat$/)) {
      // For vdat files at the root level (no region folder)
      const match = item.match(/^c\.(\-?\d+)\.(\-?\d+)\.vdat$/)
      if (match) {
        const chunkX = parseInt(match[1], 10)
        const chunkZ = parseInt(match[2], 10)
        results.push({ filePath: itemPath, chunkX, chunkZ })
      }
    }
  }

  return results
}

/**
 * Processes all vdat files in a map directory
 * @param mapDirectory Path to the map directory
 * @returns Map of chunk coordinates to chunk data
 */
export function processMapDirectory(
  mapDirectory: string,
): Map<string, Map<number, ChunkData>> {
  const chunkDataMap = new Map<string, Map<number, ChunkData>>()

  // Find all vdat files
  const vdatFiles = findVdatFiles(mapDirectory)
  console.log(`Found ${vdatFiles.length} vdat files in ${mapDirectory}`)

  // Process each vdat file
  for (const { filePath, chunkX, chunkZ } of vdatFiles) {
    // Convert the vdat file into multiple Y-chunks
    const yChunks = convertVdatFile(filePath, chunkX, chunkZ)

    // Store Y-chunks with key "x,z"
    chunkDataMap.set(`${chunkX},${chunkZ}`, yChunks)
  }

  return chunkDataMap
}

/**
 * Gets chunk data for a specific chunk position
 * @param chunkDataMap Map of chunk data
 * @param chunkX X coordinate of the chunk
 * @param chunkY Y coordinate of the chunk
 * @param chunkZ Z coordinate of the chunk
 * @returns Chunk data or null if not found
 */
export function getChunkData(
  chunkDataMap: Map<string, Map<number, ChunkData>>,
  chunkX: number,
  chunkY: number,
  chunkZ: number,
): ChunkData | null {
  // Look up column data with key "x,z"
  const key = `${chunkX},${chunkZ}`
  if (!chunkDataMap.has(key)) {
    return null
  }

  // Get the column's Y-chunks
  const yChunks = chunkDataMap.get(key)!

  // Return the specific Y-chunk if it exists
  return yChunks.has(chunkY) ? yChunks.get(chunkY)! : null
}

// Example usage (uncomment to use as standalone script)
if (require.main === module) {
  const mapDir = process.argv[2] || "./map"
  console.log(`Processing map directory: ${mapDir}`)

  const chunkDataMap = processMapDirectory(mapDir)
  console.log(`Processed ${chunkDataMap.size} chunk columns from map directory`)

  // Example: Output statistics about blocks found
  let totalBlocks = 0
  let totalChunks = 0
  const blockTypeCounts: Record<number, number> = {}

  for (const [columnKey, yChunks] of chunkDataMap.entries()) {
    const [chunkX, chunkZ] = columnKey.split(",").map(Number)

    for (const [chunkY, data] of yChunks.entries()) {
      totalChunks++
      totalBlocks += data.positions.length

      console.log(
        `Chunk (${chunkX}, ${chunkY}, ${chunkZ}): ${data.positions.length} blocks`,
      )

      // Count block types
      for (const blockType of data.blockTypes) {
        blockTypeCounts[blockType] = (blockTypeCounts[blockType] || 0) + 1
      }
    }
  }

  console.log(`Total 3D chunks: ${totalChunks}`)
  console.log(`Total blocks: ${totalBlocks}`)
  console.log("Block type distribution:")
  for (const [type, count] of Object.entries(blockTypeCounts)) {
    console.log(
      `  ${BlockType[Number(type)] || type}: ${count} (${((count / totalBlocks) * 100).toFixed(2)}%)`,
    )
  }
}
