// Auto-generated ABI file for UserStatsSystem
export const UserStatsSystemAbi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "sessionManager",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_overlaySystem",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_craftingSystem",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_inventorySystem",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_playerSystem",
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
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint8",
        "name": "blockType",
        "type": "uint8"
      }
    ],
    "name": "BlockMined",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "user",
        "type": "address"
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
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "distance",
        "type": "uint256"
      }
    ],
    "name": "DistanceMoved",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "totalCount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "lastUpdateTimestamp",
        "type": "uint256"
      }
    ],
    "name": "GlobalCounterUpdated",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "ItemBurned",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "ItemCrafted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "ItemMinted",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint8",
        "name": "fromSlot",
        "type": "uint8"
      },
      {
        "indexed": false,
        "internalType": "uint8",
        "name": "toSlot",
        "type": "uint8"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "ItemMoved",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "inputTypes",
        "type": "uint256[]"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "inputAmounts",
        "type": "uint256[]"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "outputType",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "outputAmount",
        "type": "uint256"
      }
    ],
    "name": "ItemSwapped",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "indexed": true,
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "ItemTransferred",
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
    "anonymous": false,
    "inputs": [
      {
        "indexed": true,
        "internalType": "address",
        "name": "user",
        "type": "address"
      }
    ],
    "name": "PlayerUpdated",
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
    "inputs": [],
    "name": "craftingSystem",
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
        "internalType": "uint256[]",
        "name": "totalSwapped",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "totalTransferredOut",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "totalTransferredIn",
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
    "inputs": [],
    "name": "getGlobalCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "totalCount",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "lastUpdateTimestamp",
        "type": "uint256"
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
        "internalType": "uint256",
        "name": "totalSwapped",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalTransferredOut",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalTransferredIn",
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
        "internalType": "uint256",
        "name": "totalSwapped",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalTransferredOut",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "totalTransferredIn",
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
    "name": "overlaySystem",
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
    "name": "playerSystem",
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
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "uint8",
        "name": "blockType",
        "type": "uint8"
      }
    ],
    "name": "recordBlockMined",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "uint8",
        "name": "blockType",
        "type": "uint8"
      }
    ],
    "name": "recordBlockPlaced",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "distance",
        "type": "uint256"
      }
    ],
    "name": "recordDistanceMoved",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "recordItemBurned",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "recordItemCrafted",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "recordItemMinted",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "uint8",
        "name": "fromSlot",
        "type": "uint8"
      },
      {
        "internalType": "uint8",
        "name": "toSlot",
        "type": "uint8"
      },
      {
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "recordItemMoved",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "internalType": "uint256[]",
        "name": "inputTypes",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "inputAmounts",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256",
        "name": "outputType",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "outputAmount",
        "type": "uint256"
      }
    ],
    "name": "recordItemSwapped",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "from",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "to",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "itemType",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "recordItemTransferred",
    "outputs": [],
    "stateMutability": "nonpayable",
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
    "name": "recordPlayerUpdate",
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
        "name": "_craftingSystem",
        "type": "address"
      }
    ],
    "name": "setCraftingSystem",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_inventorySystem",
        "type": "address"
      }
    ],
    "name": "setInventorySystem",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_overlaySystem",
        "type": "address"
      }
    ],
    "name": "setOverlaySystem",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "_playerSystem",
        "type": "address"
      }
    ],
    "name": "setPlayerSystem",
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
