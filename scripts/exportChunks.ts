import { createPublicClient, http } from 'viem';
import fs from 'fs';
import path from 'path';
import { somnia } from './somnia';
import { ChunkSystemAbi } from '../abi/ChunkSystemAbi';
import { OverlaySystemAbi } from '../abi/OverlaySystemAbi';

// Contract addresses
const CHUNK_SYSTEM_ADDRESS = '0x9F0A447e8AE082cc9b5dD7CFcD0DC13506827f7e';
const OVERLAY_SYSTEM_ADDRESS = '0x6Ba62e00f5244be330b3629A4fb920e08134A7fa';

// Create Viem client
const client = createPublicClient({
  chain: somnia,
  transport: http()
});

interface ChunkOverlay {
  positions: number[];
  blockTypes: number[];
}

interface ChunkData {
  x: number;
  y: number;
  z: number;
  data: Uint8Array;
}

// Helper function to estimate gas and make contract call
async function estimateAndCall<T>(
  name: string,
  params: {
    address: `0x${string}`,
    abi: any,
    functionName: string,
    args: readonly any[]
  }
): Promise<T> {
  try {
    // First estimate the gas
    const gasEstimate = await client.estimateContractGas({
      ...params,
      account: '0x0000000000000000000000000000000000000000' // Use zero address for read-only calls
    });
    console.log(`Gas estimate for ${name}: ${gasEstimate} gas units`);
    
    // Then make the actual call
    return await client.readContract(params) as T;
  } catch (error) {
    console.error(`Error in ${name}:`, error);
    throw error;
  }
}

// Helper function to decode RLE data into a Uint8Array
function decodeRLE(rleData: Uint8Array): Uint8Array {
  const blocks = new Uint8Array(16 * 16 * 16); // 4096 blocks per chunk
  let currentIndex = 0;
  let dataIndex = 0;

  while (dataIndex < rleData.length) {
    // Read count (2 bytes) and block type (1 byte)
    const count = (rleData[dataIndex] << 8) | rleData[dataIndex + 1];
    const blockType = rleData[dataIndex + 2];

    // Fill the blocks array with this block type
    blocks.fill(blockType, currentIndex, currentIndex + count);
    
    currentIndex += count;
    dataIndex += 3;
  }

  return blocks;
}

// Helper function to apply overlay data to base chunk data
function applyOverlay(baseChunk: Uint8Array, overlay: ChunkOverlay): Uint8Array {
  const result = new Uint8Array(baseChunk);
  
  for (let i = 0; i < overlay.positions.length; i++) {
    const position = overlay.positions[i];
    const blockType = overlay.blockTypes[i];
    result[position] = blockType;
  }

  return result;
}

function getChunkFileName(x: number, y: number, z: number): string {
  return `chunk_${x}_${y}_${z}.bin`;
}

function writeChunkToFile(outputDir: string, chunk: ChunkData): void {
  const fileName = getChunkFileName(chunk.x, chunk.y, chunk.z);
  const filePath = path.join(outputDir, fileName);
  
  // Create a buffer with coordinates and data
  const buffer = Buffer.alloc(12 + 4096); // 12 bytes for coords, 4096 for chunk data
  
  // Write coordinates
  buffer.writeInt32LE(chunk.x, 0);
  buffer.writeInt32LE(chunk.y, 4);
  buffer.writeInt32LE(chunk.z, 8);
  
  // Write chunk data
  Buffer.from(chunk.data).copy(buffer, 12);
  
  // Write to file
  fs.writeFileSync(filePath, buffer);
}

function chunkExistsLocally(outputDir: string, x: number, y: number, z: number): boolean {
  const filePath = path.join(outputDir, getChunkFileName(x, y, z));
  return fs.existsSync(filePath);
}

async function processChunk(x: number, y: number, z: number): Promise<ChunkData | null> {
  try {
    // Check if chunk exists
    const exists = await estimateAndCall<boolean>('chunkExists', {
      address: CHUNK_SYSTEM_ADDRESS,
      abi: ChunkSystemAbi,
      functionName: 'chunkExists',
      args: [x, y, z]
    });

    if (!exists) return null;

    // Get base chunk data
    const rleData = await estimateAndCall<`0x${string}`>('getChunkData', {
      address: CHUNK_SYSTEM_ADDRESS,
      abi: ChunkSystemAbi,
      functionName: 'getChunkData',
      args: [x, y, z]
    });

    // Get overlay data
    const overlay = await estimateAndCall<[bigint[], number[]]>('getChunkOverlay', {
      address: OVERLAY_SYSTEM_ADDRESS,
      abi: OverlaySystemAbi,
      functionName: 'getChunkOverlay',
      args: [x, y, z]
    });

    // Decode RLE data
    const baseChunk = decodeRLE(new Uint8Array(Buffer.from(rleData.slice(2), 'hex')));
    
    // Apply overlay
    const finalChunk = applyOverlay(baseChunk, {
      positions: overlay[0].map((n: bigint) => Number(n)),
      blockTypes: overlay[1].map((n: number) => n)
    });

    return {
      x,
      y,
      z,
      data: finalChunk
    };
  } catch (error) {
    console.error(`Error processing chunk at ${x},${y},${z}:`, error);
    return null;
  }
}

// Main function to fetch and save chunks
async function exportChunks(skipExisting: boolean = false) {
  // Create output directory if it doesn't exist
  const outputDir = path.join(process.cwd(), 'chunk_data');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
  }

  let processedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  // Iterate through chunk coordinates
  for (let x = -32; x <= 32; x++) {
    for (let z = -32; z <= 32; z++) {
      for (let y = 0; y <= 8; y++) {
        // Skip if chunk exists locally and skipExisting is true
        if (skipExisting && chunkExistsLocally(outputDir, x, y, z)) {
          skippedCount++;
          continue;
        }

        const chunk = await processChunk(x, y, z);
        
        if (chunk) {
          writeChunkToFile(outputDir, chunk);
          processedCount++;
          console.log(`Processed chunk at ${x},${y},${z} (${processedCount} processed, ${skippedCount} skipped, ${errorCount} errors)`);
        } else {
          errorCount++;
        }

        // Add a small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }
  }

  console.log(`\nExport complete:`);
  console.log(`- Processed: ${processedCount} chunks`);
  console.log(`- Skipped: ${skippedCount} chunks`);
  console.log(`- Errors: ${errorCount} chunks`);
}

// Parse command line arguments
const skipExisting = process.argv.includes('--skip-existing');

// Run the export
exportChunks(skipExisting).catch(console.error); 