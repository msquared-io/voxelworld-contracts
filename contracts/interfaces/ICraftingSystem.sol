// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICraftingSystem {
    // Events
    event ItemCrafted(address indexed player, uint256 outputItemId, uint256[] inputItemIds, uint256[] inputAmounts);
    event RecipeAdded(uint256 indexed outputItemId, uint256[] inputItemIds, uint256[] inputAmounts);
    event RecipeRemoved(uint256 indexed outputItemId);
    event SwapAdded(uint256 indexed swapId, uint256[] inputItemIds, uint256[] inputAmounts, uint256 outputItemId, uint256 outputAmount);
    event SwapExecuted(address indexed player, uint256 swapId, uint256[] inputItemIds, uint256 outputItemId, uint256 amount);

    // Structs
    struct Recipe {
        uint256[] inputItemIds;    // Array of required input item IDs
        uint256[] inputAmounts;    // Array of required amounts for each input item
        uint256 outputAmount;      // Amount of items produced by the recipe
        bool exists;               // Whether the recipe exists
    }

    struct Swap {
        uint256[] inputItemIds;    // Array of required input item IDs
        uint256[] inputAmounts;    // Array of required amounts for each input item
        uint256 outputItemId;      // The item ID to swap to
        uint256 outputAmount;      // Amount of items produced by the swap
        bool exists;               // Whether the swap exists
    }

    // Functions
    function craftItem(uint256 outputItemId) external;
    function getRecipe(uint256 outputItemId) external view returns (uint256[] memory inputItemIds, uint256[] memory inputAmounts, uint256 outputAmount, bool exists);
    function executeSwap(uint256 swapId, uint256 amount) external;
    function getSwap(uint256 swapId) external view returns (uint256[] memory inputItemIds, uint256[] memory inputAmounts, uint256 outputItemId, uint256 outputAmount, bool exists);

    // Custom errors
    error InvalidRecipe();                 // Input arrays don't match or are empty
    error RecipeAlreadyExists();           // Recipe for this output already exists
    error RecipeDoesNotExist();           // Recipe for this output doesn't exist
    error InsufficientMaterials();         // Player doesn't have required materials
    error NoInventorySpace();              // No empty slot to place crafted item
    error Unauthorized();                  // Caller is not authorized to perform action
    error SwapDoesNotExist();             // Swap with given ID doesn't exist
    error SwapAlreadyExists();            // Swap with given ID already exists
} 