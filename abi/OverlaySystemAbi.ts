// Auto-generated ABI file for OverlaySystem
export const OverlaySystemAbi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "sessionManager",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_chunkSystem",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_inventorySystem",
        "type": "address"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [],
    "name": "BlockAlreadyExists",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "CannotPlaceAir",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "CannotRemoveAir",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "ChunkDoesNotExist",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "InsufficientBlocks",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "InsufficientTools",
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
        "indexed": true,
        "internalType": "address",
        "name": "player",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "int32",
        "name": "x",
        "type": "int32"
      },
      {
        "indexed": false,
        "internalType": "int32",
        "name": "y",
        "type": "int32"
      },
      {
        "indexed": false,
        "internalType": "int32",
        "name": "z",
        "type": "int32"
      },
      {
        "indexed": false,
        "internalType": "uint8",
        "name": "blockType",
        "type": "uint8"
      }
    ],
    "name": "BlockPlaced",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "player",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "int32",
        "name": "x",
        "type": "int32"
      },
      {
        "indexed": false,
        "internalType": "int32",
        "name": "y",
        "type": "int32"
      },
      {
        "indexed": false,
        "internalType": "int32",
        "name": "z",
        "type": "int32"
      },
      {
        "indexed": false,
        "internalType": "uint8",
        "name": "blockType",
        "type": "uint8"
      },
      {
        "indexed": false,
        "internalType": "bool",
        "name": "minted",
        "type": "bool"
      }
    ],
    "name": "BlockRemoved",
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
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "blockModifications",
    "outputs": [
      {
        "internalType": "address",
        "name": "modifierAddress",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "timestamp",
        "type": "uint256"
      },
      {
        "internalType": "uint8",
        "name": "blockType",
        "type": "uint8"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "chunkSystem",
    "outputs": [
      {
        "internalType": "contract IChunkSystem",
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
    "name": "getBlockModification",
    "outputs": [
      {
        "internalType": "address",
        "name": "modifierAddress",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "timestamp",
        "type": "uint256"
      },
      {
        "internalType": "uint8",
        "name": "blockType",
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
    "name": "getChunkOverlay",
    "outputs": [
      {
        "internalType": "uint16[]",
        "name": "positions",
        "type": "uint16[]"
      },
      {
        "internalType": "uint8[]",
        "name": "blockTypes",
        "type": "uint8[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "inventorySystem",
    "outputs": [
      {
        "internalType": "contract IInventorySystem",
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
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "modifiedSlotTracker",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "name": "overlay",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
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
      },
      {
        "internalType": "uint8",
        "name": "blockType",
        "type": "uint8"
      }
    ],
    "name": "placeBlock",
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
    "name": "removeBlock",
    "outputs": [],
    "stateMutability": "nonpayable",
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
        "internalType": "address",
        "name": "_userStatsSystem",
        "type": "address"
      }
    ],
    "name": "setUserStatsSystem",
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
  },
  {
    "inputs": [],
    "name": "userStatsSystem",
    "outputs": [
      {
        "internalType": "contract IUserStatsSystem",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
] as const;
