export const craftingAbi = [
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "sessionManager",
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
    "name": "InsufficientMaterials",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "InvalidRecipe",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "NoInventorySpace",
    "type": "error"
  },
  {
    "inputs": [],
    "name": "RecipeDoesNotExist",
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
        "internalType": "uint256",
        "name": "outputItemId",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "inputItemIds",
        "type": "uint256[]"
      },
      {
        "indexed": false,
        "internalType": "uint256[]",
        "name": "inputAmounts",
        "type": "uint256[]"
      }
    ],
    "name": "ItemCrafted",
    "type": "event"
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
        "internalType": "bool",
        "name": "exists",
        "type": "bool"
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
  }
] as const; 