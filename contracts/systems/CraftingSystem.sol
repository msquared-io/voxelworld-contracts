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

    IInventorySystem public immutable inventorySystem;
    IUserStatsSystem public userStatsSystem;

    // Event emitted when items are transferred between users
    event ItemTransferred(address indexed from, address indexed to, uint256 itemId, uint256 amount);

    // Tool type bit mask for identifying unique items
    uint256 public constant TOOL_TYPE_MASK = 0xFFFF; // First 16 bits for tool type

    // Constants from InventorySystem
    uint8 public constant MAX_SLOTS = 36;
    uint8 public constant SLOTS_PER_WORD = 9;
    uint8 public constant STORAGE_SLOTS_NEEDED = 4;

    // Mapping from output item ID to its recipe
    mapping(uint256 => Recipe) public recipes;
    
    // Mapping from swap ID to its swap details
    mapping(uint256 => Swap) public swaps;
    
    // Next available swap ID
    uint256 public nextSwapId = 1;

    constructor(address sessionManager, address _inventorySystem) WorldUtils(sessionManager) {
        inventorySystem = IInventorySystem(_inventorySystem);
        _initializeBasicRecipes();
        _initializeSwaps();
    }

    // Internal function to check if an item is a tool
    function _isToolItem(uint256 id) internal pure returns (bool) {
        // First check if it's a tool instance (has tool type in first 16 bits)
        uint256 typeId = id & TOOL_TYPE_MASK;

        return (
            typeId == MinecraftConstants.WOODEN_PICKAXE ||
            typeId == MinecraftConstants.STONE_PICKAXE ||
            typeId == MinecraftConstants.IRON_PICKAXE ||
            typeId == MinecraftConstants.DIAMOND_PICKAXE ||
            typeId == MinecraftConstants.GOLDEN_PICKAXE ||
            typeId == MinecraftConstants.SHEARS
        );
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

        // Stone crafting recipes
        // Cobblestone -> Stone (shapeless)
        uint256[] memory stoneInputIds = new uint256[](1);
        uint256[] memory stoneInputAmounts = new uint256[](1);
        stoneInputIds[0] = MinecraftConstants.COBBLESTONE;
        stoneInputAmounts[0] = 1;
        _addRecipeInternal(MinecraftConstants.STONE, stoneInputIds, stoneInputAmounts, 1);

        // Stone -> Stone Bricks (4 stone)
        uint256[] memory stoneBricksInputIds = new uint256[](1);
        uint256[] memory stoneBricksInputAmounts = new uint256[](1);
        stoneBricksInputIds[0] = MinecraftConstants.STONE;
        stoneBricksInputAmounts[0] = 4;
        _addRecipeInternal(MinecraftConstants.STONE_BRICKS, stoneBricksInputIds, stoneBricksInputAmounts, 1);

        // Iron Block (9 iron ingots)
        uint256[] memory ironBlockInputIds = new uint256[](1);
        uint256[] memory ironBlockInputAmounts = new uint256[](1);
        ironBlockInputIds[0] = MinecraftConstants.IRON_INGOT;
        ironBlockInputAmounts[0] = 9;
        _addRecipeInternal(MinecraftConstants.IRON_BLOCK, ironBlockInputIds, ironBlockInputAmounts, 1);

        // Gold Block (9 gold ingots)
        uint256[] memory goldBlockInputIds = new uint256[](1);
        uint256[] memory goldBlockInputAmounts = new uint256[](1);
        goldBlockInputIds[0] = MinecraftConstants.GOLD_INGOT;
        goldBlockInputAmounts[0] = 9;
        _addRecipeInternal(MinecraftConstants.GOLD_BLOCK, goldBlockInputIds, goldBlockInputAmounts, 1);

        // Diamond Block (9 diamonds)
        uint256[] memory diamondBlockInputIds = new uint256[](1);
        uint256[] memory diamondBlockInputAmounts = new uint256[](1);
        diamondBlockInputIds[0] = MinecraftConstants.DIAMOND;
        diamondBlockInputAmounts[0] = 9;
        _addRecipeInternal(MinecraftConstants.DIAMOND_BLOCK, diamondBlockInputIds, diamondBlockInputAmounts, 1);

        // Lapis Block (9 lapis lazuli)
        uint256[] memory lapisBlockInputIds = new uint256[](1);
        uint256[] memory lapisBlockInputAmounts = new uint256[](1);
        lapisBlockInputIds[0] = MinecraftConstants.LAPIS_LAZULI;
        lapisBlockInputAmounts[0] = 9;
        _addRecipeInternal(MinecraftConstants.LAPIS_BLOCK, lapisBlockInputIds, lapisBlockInputAmounts, 1);
    }

    // Initialize swaps for ores and wool colors
    function _initializeSwaps() internal {
        // Ore smelting swaps
        // Iron ore + coal -> Iron ingot
        uint256[] memory ironInputIds = new uint256[](2);
        uint256[] memory ironInputAmounts = new uint256[](2);
        ironInputIds[0] = MinecraftConstants.IRON_ORE;
        ironInputIds[1] = MinecraftConstants.COAL;
        ironInputAmounts[0] = 1;
        ironInputAmounts[1] = 1;
        _addSwapInternal(ironInputIds, ironInputAmounts, MinecraftConstants.IRON_INGOT, 1);

        // Gold ore + coal -> Gold ingot
        uint256[] memory goldInputIds = new uint256[](2);
        uint256[] memory goldInputAmounts = new uint256[](2);
        goldInputIds[0] = MinecraftConstants.GOLD_ORE;
        goldInputIds[1] = MinecraftConstants.COAL;
        goldInputAmounts[0] = 1;
        goldInputAmounts[1] = 1;
        _addSwapInternal(goldInputIds, goldInputAmounts, MinecraftConstants.GOLD_INGOT, 1);

        // Diamond ore -> Diamond (no coal needed)
        uint256[] memory diamondInputIds = new uint256[](1);
        uint256[] memory diamondInputAmounts = new uint256[](1);
        diamondInputIds[0] = MinecraftConstants.DIAMOND_ORE;
        diamondInputAmounts[0] = 1;
        _addSwapInternal(diamondInputIds, diamondInputAmounts, MinecraftConstants.DIAMOND, 1);

        // Lapis ore -> Lapis (no coal needed)
        uint256[] memory lapisInputIds = new uint256[](1);
        uint256[] memory lapisInputAmounts = new uint256[](1);
        lapisInputIds[0] = MinecraftConstants.LAPIS_LAZULI_ORE;
        lapisInputAmounts[0] = 1;
        _addSwapInternal(lapisInputIds, lapisInputAmounts, MinecraftConstants.LAPIS_LAZULI, 1);

        // Wool color swaps (200-214) - any color can be made from either diamond (32) or gold (16)
        // Diamond -> Wool colors (32 wool per diamond)
        for (uint256 i = 0; i < 15; i++) {
            uint256[] memory diamondWoolInputIds = new uint256[](1);
            uint256[] memory diamondWoolInputAmounts = new uint256[](1);
            diamondWoolInputIds[0] = MinecraftConstants.DIAMOND;
            diamondWoolInputAmounts[0] = 1;
            _addSwapInternal(diamondWoolInputIds, diamondWoolInputAmounts, 200 + i, 32);
        }

        // Gold -> Wool colors (16 wool per gold ingot)
        for (uint256 i = 0; i < 15; i++) {
            uint256[] memory goldWoolInputIds = new uint256[](1);
            uint256[] memory goldWoolInputAmounts = new uint256[](1);
            goldWoolInputIds[0] = MinecraftConstants.GOLD_INGOT;
            goldWoolInputAmounts[0] = 1;
            _addSwapInternal(goldWoolInputIds, goldWoolInputAmounts, 200 + i, 16);
        }
    }

    // Internal function to add swap
    function _addSwapInternal(
        uint256[] memory inputItemIds,
        uint256[] memory inputAmounts,
        uint256 outputItemId,
        uint256 outputAmount
    ) internal {
        if (inputItemIds.length == 0 || inputItemIds.length != inputAmounts.length) {
            revert InvalidRecipe();
        }

        swaps[nextSwapId] = Swap({
            inputItemIds: inputItemIds,
            inputAmounts: inputAmounts,
            outputItemId: outputItemId,
            outputAmount: outputAmount,
            exists: true
        });
        emit SwapAdded(nextSwapId, inputItemIds, inputAmounts, outputItemId, outputAmount);
        nextSwapId++;
    }

    // Execute a swap
    function executeSwap(uint256 swapId, uint256 amount) external override {
        address player = _msgSender();
        Swap storage swap = swaps[swapId];

        if (!swap.exists) {
            revert SwapDoesNotExist();
        }

        // Check if player has enough input items
        for (uint256 i = 0; i < swap.inputItemIds.length; i++) {
            if (inventorySystem.balanceOf(player, swap.inputItemIds[i]) < amount * swap.inputAmounts[i]) {
                revert InsufficientMaterials();
            }
        }

        // Burn input items
        for (uint256 i = 0; i < swap.inputItemIds.length; i++) {
            inventorySystem.burn(player, swap.inputItemIds[i], amount * swap.inputAmounts[i]);
        }

        // Mint output items
        inventorySystem.mint(player, swap.outputItemId, amount * swap.outputAmount);

        // Record stats
        if (address(userStatsSystem) != address(0)) {
            userStatsSystem.recordItemCrafted(player, swap.outputItemId, amount * swap.outputAmount);
        }

        emit SwapExecuted(player, swapId, swap.inputItemIds, swap.outputItemId, amount);
    }

    // Get swap details
    function getSwap(uint256 swapId) external view override returns (
        uint256[] memory inputItemIds,
        uint256[] memory inputAmounts,
        uint256 outputItemId,
        uint256 outputAmount,
        bool exists
    ) {
        Swap storage swap = swaps[swapId];
        return (swap.inputItemIds, swap.inputAmounts, swap.outputItemId, swap.outputAmount, swap.exists);
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

    // Add a new recipe
    function addRecipe(
        uint256 outputItemId,
        uint256[] calldata inputItemIds,
        uint256[] calldata inputAmounts,
        uint256 outputAmount
    ) external onlyOwner {
        if (recipes[outputItemId].exists) {
            revert RecipeAlreadyExists();
        }
        _addRecipeInternal(outputItemId, inputItemIds, inputAmounts, outputAmount);
        emit RecipeAdded(outputItemId, inputItemIds, inputAmounts);
    }

    // Remove an existing recipe
    function removeRecipe(uint256 outputItemId) external onlyOwner {
        if (!recipes[outputItemId].exists) {
            revert RecipeDoesNotExist();
        }
        delete recipes[outputItemId];
        emit RecipeRemoved(outputItemId);
    }

    /**
     * @notice Transfer items from sender to another address
     * @param to The address to transfer items to
     * @param itemId The ID of the item to transfer
     * @param amount The amount of items to transfer
     */
    function transferItems(address to, uint256 itemId, uint256 amount) external {
        address from = _msgSender();
        
        // Check for valid inputs
        if (to == address(0)) revert("Invalid recipient");
        if (amount == 0) revert("Invalid amount");
        
        // Check if sender has enough items
        if (inventorySystem.balanceOf(from, itemId) < amount) {
            revert InsufficientMaterials();
        }

        // Prevent transfer of tools/unique items
        if (_isToolItem(itemId)) {
            revert("Cannot transfer unique items");
        }
        
        // Burn items from sender
        inventorySystem.burn(from, itemId, amount);
        
        // Mint items to recipient
        inventorySystem.mint(to, itemId, amount);
        
        emit ItemTransferred(from, to, itemId, amount);
    }
} 