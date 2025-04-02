// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../base/WorldUtils.sol";
import "../interfaces/ICraftingSystem.sol";
import "../interfaces/IInventorySystem.sol";
import "../interfaces/IUserStatsSystem.sol";
import "../constants/MinecraftConstants.sol";

contract CraftingSystem is WorldUtils, ICraftingSystem {
    using MinecraftConstants for uint8;
    using MinecraftConstants for uint16;

    // Constants from InventorySystem
    uint8 public constant MAX_SLOTS = 36;
    uint8 public constant SLOTS_PER_WORD = 9;
    uint8 public constant STORAGE_SLOTS_NEEDED = 4;

    // Mapping from output item ID to its recipe
    mapping(uint256 => Recipe) private recipes;
    
    // Reference to the inventory system
    IInventorySystem public immutable inventorySystem;
    IUserStatsSystem public userStatsSystem;

    constructor(address sessionManager, address _inventorySystem) WorldUtils(sessionManager) {
        inventorySystem = IInventorySystem(_inventorySystem);
        _initializeBasicRecipes();
    }

    function setUserStatsSystem(address _userStatsSystem) external onlyOwner {
        if (_userStatsSystem == address(0)) revert("Invalid address");
        userStatsSystem = IUserStatsSystem(_userStatsSystem);
    }

    // Initialize basic Minecraft recipes
    function _initializeBasicRecipes() internal {
        // Wood Planks (4 planks from 1 wood)
        uint256[] memory woodInputIds = new uint256[](1);
        uint256[] memory woodInputAmounts = new uint256[](1);
        woodInputIds[0] = MinecraftConstants.WOOD;
        woodInputAmounts[0] = 1;
        _addRecipeInternal(MinecraftConstants.WOOD_PLANKS, woodInputIds, woodInputAmounts, 4);

        // Sticks (4 sticks from 2 planks)
        uint256[] memory stickInputIds = new uint256[](1);
        uint256[] memory stickInputAmounts = new uint256[](1);
        stickInputIds[0] = MinecraftConstants.WOOD_PLANKS;
        stickInputAmounts[0] = 2;
        _addRecipeInternal(MinecraftConstants.STICK, stickInputIds, stickInputAmounts, 4);

        // Wooden Pickaxe (3 planks + 2 sticks)
        uint256[] memory woodenPickInputIds = new uint256[](2);
        uint256[] memory woodenPickInputAmounts = new uint256[](2);
        woodenPickInputIds[0] = MinecraftConstants.WOOD_PLANKS;
        woodenPickInputIds[1] = MinecraftConstants.STICK;
        woodenPickInputAmounts[0] = 3;
        woodenPickInputAmounts[1] = 2;
        _addRecipeInternal(MinecraftConstants.WOODEN_PICKAXE, woodenPickInputIds, woodenPickInputAmounts, 1);

        // Stone Pickaxe (3 cobblestone + 2 sticks)
        uint256[] memory stonePickInputIds = new uint256[](2);
        uint256[] memory stonePickInputAmounts = new uint256[](2);
        stonePickInputIds[0] = MinecraftConstants.COBBLESTONE;
        stonePickInputIds[1] = MinecraftConstants.STICK;
        stonePickInputAmounts[0] = 3;
        stonePickInputAmounts[1] = 2;
        _addRecipeInternal(MinecraftConstants.STONE_PICKAXE, stonePickInputIds, stonePickInputAmounts, 1);

        // Iron Pickaxe (3 iron ingots + 2 sticks)
        uint256[] memory ironPickInputIds = new uint256[](2);
        uint256[] memory ironPickInputAmounts = new uint256[](2);
        ironPickInputIds[0] = MinecraftConstants.IRON_INGOT;
        ironPickInputIds[1] = MinecraftConstants.STICK;
        ironPickInputAmounts[0] = 3;
        ironPickInputAmounts[1] = 2;
        _addRecipeInternal(MinecraftConstants.IRON_PICKAXE, ironPickInputIds, ironPickInputAmounts, 1);

        // Diamond Pickaxe (3 diamonds + 2 sticks)
        uint256[] memory diamondPickInputIds = new uint256[](2);
        uint256[] memory diamondPickInputAmounts = new uint256[](2);
        diamondPickInputIds[0] = MinecraftConstants.DIAMOND;
        diamondPickInputIds[1] = MinecraftConstants.STICK;
        diamondPickInputAmounts[0] = 3;
        diamondPickInputAmounts[1] = 2;
        _addRecipeInternal(MinecraftConstants.DIAMOND_PICKAXE, diamondPickInputIds, diamondPickInputAmounts, 1);

        // Golden Pickaxe (3 gold ingots + 2 sticks)
        uint256[] memory goldPickInputIds = new uint256[](2);
        uint256[] memory goldPickInputAmounts = new uint256[](2);
        goldPickInputIds[0] = MinecraftConstants.GOLD_INGOT;
        goldPickInputIds[1] = MinecraftConstants.STICK;
        goldPickInputAmounts[0] = 3;
        goldPickInputAmounts[1] = 2;
        _addRecipeInternal(MinecraftConstants.GOLDEN_PICKAXE, goldPickInputIds, goldPickInputAmounts, 1);
    }

    // Internal function to add recipe without emitting events
    function _addRecipeInternal(
        uint256 outputItemId,
        uint256[] memory inputItemIds,
        uint256[] memory inputAmounts,
        uint256 outputAmount
    ) internal {
        if (inputItemIds.length == 0 || inputItemIds.length != inputAmounts.length) {
            revert InvalidRecipe();
        }

        recipes[outputItemId] = Recipe({
            inputItemIds: inputItemIds,
            inputAmounts: inputAmounts,
            outputAmount: outputAmount,
            exists: true
        });
    }

    // Get recipe details
    function getRecipe(uint256 outputItemId) external view override returns (
        uint256[] memory inputItemIds,
        uint256[] memory inputAmounts,
        uint256 outputAmount,
        bool exists
    ) {
        Recipe storage recipe = recipes[outputItemId];
        return (recipe.inputItemIds, recipe.inputAmounts, recipe.outputAmount, recipe.exists);
    }

    // Craft an item
    function craftItem(uint256 outputItemId) external override {
        address player = _msgSender();
        Recipe storage recipe = recipes[outputItemId];

        // Check if recipe exists
        if (!recipe.exists) {
            revert RecipeDoesNotExist();
        }

        // Get inventory contents in one storage read
        InventoryItem[] memory inventory = inventorySystem.getInventoryContents(player);
        
        // Track materials found and find first empty slot in single pass
        uint256[] memory materialsFound = new uint256[](recipe.inputItemIds.length);
        uint8 expectedSlot = 0;
        uint8 emptySlot = type(uint8).max;
        
        for (uint256 i = 0; i < inventory.length; i++) {
            InventoryItem memory item = inventory[i];
            
            // Find first gap in slot sequence
            while (expectedSlot < item.slot) {
                if (emptySlot == type(uint8).max) {
                    emptySlot = expectedSlot;
                    // Don't break as we still need to count materials
                }
                expectedSlot++;
            }
            expectedSlot = item.slot + 1;
            
            // Track materials
            for (uint256 j = 0; j < recipe.inputItemIds.length; j++) {
                if (item.itemId == recipe.inputItemIds[j]) {
                    materialsFound[j] += item.amount;
                }
            }
        }
        
        // If no gaps found in sequence, the next slot is empty
        if (emptySlot == type(uint8).max) {
            emptySlot = expectedSlot;
        }
        
        if (emptySlot >= MAX_SLOTS) {
            revert NoInventorySpace();
        }

        // Verify we have all required materials
        for (uint256 i = 0; i < recipe.inputItemIds.length; i++) {
            if (materialsFound[i] < recipe.inputAmounts[i]) {
                revert InsufficientMaterials();
            }
        }

        // Burn input items
        for (uint256 i = 0; i < recipe.inputItemIds.length; i++) {
            inventorySystem.burn(player, recipe.inputItemIds[i], recipe.inputAmounts[i]);
        }

        // Mint the crafted item with the correct output amount
        inventorySystem.mint(player, outputItemId, recipe.outputAmount);

        // Record crafting stats
        if (address(userStatsSystem) != address(0)) {
            userStatsSystem.recordItemCrafted(player, outputItemId, recipe.outputAmount);
        }

        emit ItemCrafted(player, outputItemId, recipe.inputItemIds, recipe.inputAmounts);
    }
} 