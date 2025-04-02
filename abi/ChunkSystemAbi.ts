// Auto-generated ABI file for ChunkSystem
export const ChunkSystemAbi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "sessionManager",
        "type": "address"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [],
    "name": "ChunkAlreadyExists",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "ChunkDoesNotExist",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "InvalidRLEData",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "NotOwner",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "owner",
        "type": "address"
      }
    ],
    "name": "OwnableInvalidOwner",
    "type": "error"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "OwnableUnauthorizedAccount",
    "type": "error"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "int32",
        "name": "chunkX",
        "type": "int32"
      },
      {
        "indexed": false,
        "internalType": "int32",
        "name": "chunkY",
        "type": "int32"
      },
      {
        "indexed": false,
        "internalType": "int32",
        "name": "chunkZ",
        "type": "int32"
      }
    ],
    "name": "ChunkCreated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "previousOwner",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "OwnershipTransferred",
    "type": "event"
  },
  {
    "inputs": [],
    "name": "AIR",
    "outputs": [
      {
        "internalType": "uint8",
        "name": "",
        "type": "uint8"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "int32",
        "name": "chunkX",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "chunkY",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "chunkZ",
        "type": "int32"
      }
    ],
    "name": "chunkExists",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "int256",
        "name": "",
        "type": "int256"
      },
      {
        "internalType": "int256",
        "name": "",
        "type": "int256"
      },
      {
        "internalType": "int256",
        "name": "",
        "type": "int256"
      }
    ],
    "name": "chunks",
    "outputs": [
      {
        "internalType": "bool",
        "name": "exists",
        "type": "bool"
      },
      {
        "internalType": "bytes",
        "name": "rleData",
        "type": "bytes"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "int32",
        "name": "chunkX",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "chunkY",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "chunkZ",
        "type": "int32"
      }
    ],
    "name": "createChunk",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "int32",
        "name": "x",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "y",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "z",
        "type": "int32"
      }
    ],
    "name": "getBlock",
    "outputs": [
      {
        "internalType": "uint8",
        "name": "",
        "type": "uint8"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "int32",
        "name": "chunkX",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "chunkY",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "chunkZ",
        "type": "int32"
      }
    ],
    "name": "getChunkData",
    "outputs": [
      {
        "internalType": "bytes",
        "name": "",
        "type": "bytes"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "owner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "renounceOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "sessionManager",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "int32",
        "name": "chunkX",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "chunkY",
        "type": "int32"
      },
      {
        "internalType": "int32",
        "name": "chunkZ",
        "type": "int32"
      },
      {
        "internalType": "bytes",
        "name": "rleData",
        "type": "bytes"
      }
    ],
    "name": "setChunkData",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "transferOwnership",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
] as const;
