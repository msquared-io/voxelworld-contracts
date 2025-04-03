// Auto-generated ABI file for VoxelWorld
export const VoxelWorldAbi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "chunkSystemAddress",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "overlaySystemAddress",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "playerSystemAddress",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "inventorySystemAddress",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "craftingSystemAddress",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "userStatsSystemAddress",
        "type": "address"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      }
    ],
    "name": "balanceOf",
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
        "internalType": "uint256",
        "name": "outputItemId",
        "type": "uint256"
      }
    ],
    "name": "craftItem",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "craftingSystem",
    "outputs": [
      {
        "internalType": "contract ICraftingSystem",
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
    "name": "createChunk",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "offset",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "limit",
        "type": "uint256"
      }
    ],
    "name": "getAllUserInventoryStats",
    "outputs": [
      {
        "internalType": "uint256[]",
        "name": "totalMinted",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "totalBurned",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "totalMoved",
        "type": "uint256[]"
      },
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "itemType",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.ItemTypeCount[][]",
        "name": "mintedItems",
        "type": "tuple[][]"
      },
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "itemType",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.ItemTypeCount[][]",
        "name": "burnedItems",
        "type": "tuple[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "mintedItemTypes",
        "type": "uint256[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "mintedCounts",
        "type": "uint256[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "burnedItemTypes",
        "type": "uint256[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "burnedCounts",
        "type": "uint256[][]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "offset",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "limit",
        "type": "uint256"
      }
    ],
    "name": "getAllUserStats",
    "outputs": [
      {
        "internalType": "address[]",
        "name": "userAddresses",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "totalMined",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "totalPlaced",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "totalDistance",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "totalCrafted",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "totalPlayerUpdates",
        "type": "uint256[]"
      },
      {
        "components": [
          {
            "internalType": "uint8",
            "name": "blockType",
            "type": "uint8"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.BlockTypeCount[][]",
        "name": "minedBlocks",
        "type": "tuple[][]"
      },
      {
        "components": [
          {
            "internalType": "uint8",
            "name": "blockType",
            "type": "uint8"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.BlockTypeCount[][]",
        "name": "placedBlocks",
        "type": "tuple[][]"
      },
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "itemType",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.ItemTypeCount[][]",
        "name": "craftedItems",
        "type": "tuple[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "minedBlockTypes",
        "type": "uint256[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "minedCounts",
        "type": "uint256[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "placedBlockTypes",
        "type": "uint256[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "placedCounts",
        "type": "uint256[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "craftedItemTypes",
        "type": "uint256[][]"
      },
      {
        "internalType": "uint256[][]",
        "name": "craftedCounts",
        "type": "uint256[][]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "offset",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "limit",
        "type": "uint256"
      }
    ],
    "name": "getAllUsers",
    "outputs": [
      {
        "internalType": "address[]",
        "name": "users",
        "type": "address[]"
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
    "name": "getGlobalInventoryStats",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "totalMinted",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalBurned",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalMoved",
        "type": "uint256"
      },
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "itemType",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.ItemTypeCount[]",
        "name": "mintedItems",
        "type": "tuple[]"
      },
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "itemType",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.ItemTypeCount[]",
        "name": "burnedItems",
        "type": "tuple[]"
      },
      {
        "internalType": "uint256[]",
        "name": "mintedItemTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "mintedCounts",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "burnedItemTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "burnedCounts",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getGlobalStats",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "totalMined",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalPlaced",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalDistance",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalCrafted",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalPlayerUpdates",
        "type": "uint256"
      },
      {
        "components": [
          {
            "internalType": "uint8",
            "name": "blockType",
            "type": "uint8"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.BlockTypeCount[]",
        "name": "minedBlocks",
        "type": "tuple[]"
      },
      {
        "components": [
          {
            "internalType": "uint8",
            "name": "blockType",
            "type": "uint8"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.BlockTypeCount[]",
        "name": "placedBlocks",
        "type": "tuple[]"
      },
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "itemType",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.ItemTypeCount[]",
        "name": "craftedItems",
        "type": "tuple[]"
      },
      {
        "internalType": "uint256[]",
        "name": "minedBlockTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "minedCounts",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "placedBlockTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "placedCounts",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "craftedItemTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "craftedCounts",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "player",
        "type": "address"
      }
    ],
    "name": "getPlayerProfile",
    "outputs": [
      {
        "internalType": "string",
        "name": "name",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "skinUrl",
        "type": "string"
      },
      {
        "internalType": "bool",
        "name": "initialized",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "outputItemId",
        "type": "uint256"
      }
    ],
    "name": "getRecipe",
    "outputs": [
      {
        "internalType": "uint256[]",
        "name": "inputItemIds",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "inputAmounts",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256",
        "name": "outputAmount",
        "type": "uint256"
      },
      {
        "internalType": "bool",
        "name": "exists",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      }
    ],
    "name": "getUserInventoryStats",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "totalMinted",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalBurned",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalMoved",
        "type": "uint256"
      },
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "itemType",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.ItemTypeCount[]",
        "name": "mintedItems",
        "type": "tuple[]"
      },
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "itemType",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.ItemTypeCount[]",
        "name": "burnedItems",
        "type": "tuple[]"
      },
      {
        "internalType": "uint256[]",
        "name": "mintedItemTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "mintedCounts",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "burnedItemTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "burnedCounts",
        "type": "uint256[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      }
    ],
    "name": "getUserStats",
    "outputs": [
      {
        "internalType": "address",
        "name": "userAddress",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "totalMined",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalPlaced",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalDistance",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalCrafted",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalPlayerUpdates",
        "type": "uint256"
      },
      {
        "components": [
          {
            "internalType": "uint8",
            "name": "blockType",
            "type": "uint8"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.BlockTypeCount[]",
        "name": "minedBlocks",
        "type": "tuple[]"
      },
      {
        "components": [
          {
            "internalType": "uint8",
            "name": "blockType",
            "type": "uint8"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.BlockTypeCount[]",
        "name": "placedBlocks",
        "type": "tuple[]"
      },
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "itemType",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "count",
            "type": "uint256"
          }
        ],
        "internalType": "struct IUserStatsSystem.ItemTypeCount[]",
        "name": "craftedItems",
        "type": "tuple[]"
      },
      {
        "internalType": "uint256[]",
        "name": "minedBlockTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "minedCounts",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "placedBlockTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "placedCounts",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "craftedItemTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "craftedCounts",
        "type": "uint256[]"
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
    "inputs": [],
    "name": "overlaySystem",
    "outputs": [
      {
        "internalType": "contract IOverlaySystem",
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
    "inputs": [],
    "name": "playerSystem",
    "outputs": [
      {
        "internalType": "contract IPlayerSystem",
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
    "name": "removeBlock",
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
        "internalType": "string",
        "name": "name",
        "type": "string"
      },
      {
        "internalType": "string",
        "name": "skinUrl",
        "type": "string"
      }
    ],
    "name": "setPlayerProfile",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint8",
        "name": "slot",
        "type": "uint8"
      }
    ],
    "name": "setSelectedSlot",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "combined",
        "type": "uint256"
      }
    ],
    "name": "updatePlayerTransform",
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
