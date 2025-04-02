// ABI for the Voxel contract
export const VOXEL_ABI = [
  {
    inputs: [],
    name: "ChunkAlreadyExists",
    type: "error",
  },
  {
    inputs: [],
    name: "ChunkDoesNotExist",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidRLEData",
    type: "error",
  },
  {
    inputs: [],
    name: "NotOwner",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "int256",
        name: "x",
        type: "int256",
      },
      {
        indexed: false,
        internalType: "int256",
        name: "y",
        type: "int256",
      },
      {
        indexed: false,
        internalType: "int256",
        name: "z",
        type: "int256",
      },
    ],
    name: "ChunkCreated",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "int256",
        name: "chunkX",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "chunkY",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "chunkZ",
        type: "int256",
      },
    ],
    name: "chunkExists",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "int256",
        name: "chunkX",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "chunkY",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "chunkZ",
        type: "int256",
      },
    ],
    name: "createChunk",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "int256",
        name: "x",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "y",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "z",
        type: "int256",
      },
    ],
    name: "getBlock",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "int256",
        name: "chunkX",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "chunkY",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "chunkZ",
        type: "int256",
      },
    ],
    name: "getChunkData",
    outputs: [
      {
        internalType: "bytes",
        name: "",
        type: "bytes",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "int256",
        name: "chunkX",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "chunkY",
        type: "int256",
      },
      {
        internalType: "int256",
        name: "chunkZ",
        type: "int256",
      },
      {
        internalType: "bytes",
        name: "rleData",
        type: "bytes",
      },
    ],
    name: "setChunkData",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const
