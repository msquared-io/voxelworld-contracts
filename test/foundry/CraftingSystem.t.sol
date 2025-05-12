// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TestHelper.sol";
import "../../contracts/interfaces/ICraftingSystem.sol";

contract CraftingSystemTest is TestHelper {
    event RecipeAdded(uint256 indexed outputItemId, uint256[] inputItemIds, uint256[] inputAmounts);
    event RecipeRemoved(uint256 indexed outputItemId);
    event SwapAdded(uint256 indexed swapId, uint256 inputItemId, uint256 outputItemId, uint256 outputAmount);
    event SwapExecuted(address indexed player, uint256 swapId, uint256[] inputItemIds, uint256 outputItemId, uint256 amount);

    function setUp() public override {
        super.setUp();
    }

    function test_BasicRecipeOperations() view public {
        // Test wooden pickaxe recipe
        (uint256[] memory inputIds1, uint256[] memory amounts1, uint256 outputAmount1, bool exists1) = craftingSystem.getRecipe(WOODEN_PICKAXE);
        
        assertTrue(exists1, "Wooden pickaxe recipe should exist from recipe");
        assertEq(inputIds1.length, 2, "Wooden pickaxe should have 2 ingredients from recipe");
        assertEq(amounts1.length, 2, "Wooden pickaxe should have 2 amounts from recipe");
        assertEq(outputAmount1, 1, "Should get 1 wooden pickaxe from recipe");
        
        // Check recipe ingredients (3 planks + 2 sticks)
        assertEq(inputIds1[0], WOOD_PLANKS, "First ingredient should be wood planks");
        assertEq(inputIds1[1], STICK, "Second ingredient should be stick");
        assertEq(amounts1[0], 3, "Should need 3 planks");
        assertEq(amounts1[1], 2, "Should need 2 sticks");

        // Test stone pickaxe recipe
        (uint256[] memory inputIds2, uint256[] memory amounts2, uint256 outputAmount2, bool exists2) = craftingSystem.getRecipe(STONE_PICKAXE);
        
        assertTrue(exists2, "Stone pickaxe recipe should exist");
        assertEq(inputIds2.length, 2, "Stone pickaxe should have 2 ingredients");
        assertEq(amounts2.length, 2, "Stone pickaxe should have 2 amounts");
        assertEq(outputAmount2, 1, "Should get 1 stone pickaxe");
        
        // Check recipe ingredients (3 cobblestone + 2 sticks)
        assertEq(inputIds2[0], COBBLESTONE, "First ingredient should be cobblestone");
        assertEq(inputIds2[1], STICK, "Second ingredient should be stick");
        assertEq(amounts2[0], 3, "Should need 3 cobblestone");
        assertEq(amounts2[1], 2, "Should need 2 sticks");

        // Test non-existent recipe
        (, , , bool exists3) = craftingSystem.getRecipe(999999);
        assertFalse(exists3, "Non-existent recipe should return false");
    }

    function test_CraftingOperations() public {
        vm.startPrank(address(craftingSystem));

        // get the next unique token id which will be the wooden pickaxe
        uint256 nextTokenId = inventorySystem.nextTokenId();
        uint256 woodenPickaxeTokenId = nextTokenId << 16 | WOODEN_PICKAXE;

        // Test crafting wooden planks from wood
        inventorySystem.mint(PLAYER, WOOD, 1);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        craftingSystem.craftItem(WOOD_PLANKS);
        assertEq(inventorySystem.balanceOf(PLAYER, WOOD_PLANKS), 4, "Should get 4 wooden planks from 1 wood");

        // Test crafting sticks from planks
        // We need 2 planks to craft sticks, and we have 4 from previous craft
        craftingSystem.craftItem(STICK);
        assertEq(inventorySystem.balanceOf(PLAYER, STICK), 4, "Should get 4 sticks from 2 planks");

        // Test crafting wooden pickaxe
        // Need 3 planks and 2 sticks
        // We used 2 planks for sticks, so mint 1 more wood for more planks
        vm.stopPrank();
        vm.startPrank(address(craftingSystem));
        inventorySystem.mint(PLAYER, WOOD, 1);
        vm.stopPrank();
        vm.startPrank(PLAYER);
        craftingSystem.craftItem(WOOD_PLANKS);  // Get 4 more planks
        craftingSystem.craftItem(WOODEN_PICKAXE);
        assertEq(inventorySystem.balanceOf(PLAYER, woodenPickaxeTokenId), 1, "Should get 1 wooden pickaxe");

        vm.stopPrank();
    }

    function test_RevertWhen_CraftingWithoutMaterials() public {
        vm.startPrank(PLAYER);
        
        // Try to craft iron pickaxe without materials
        vm.expectRevert(ICraftingSystem.InsufficientMaterials.selector);
        craftingSystem.craftItem(IRON_PICKAXE);
        
        vm.stopPrank();
    }

    function test_RevertWhen_CraftingNonExistentRecipe() public {
        vm.startPrank(PLAYER);
        
        vm.expectRevert(ICraftingSystem.RecipeDoesNotExist.selector);
        craftingSystem.craftItem(999999);
        
        vm.stopPrank();
    }

    function test_IntegrationWithInventory() public {
        vm.startPrank(address(craftingSystem));

        // Now mint exactly what we need
        inventorySystem.mint(PLAYER, COBBLESTONE, 3);
        inventorySystem.mint(PLAYER, STICK, 2);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        uint256 initialCobblestone = inventorySystem.balanceOf(PLAYER, COBBLESTONE);
        uint256 initialSticks = inventorySystem.balanceOf(PLAYER, STICK);
        assertEq(initialCobblestone, 3, "Should have 3 cobblestone");
        assertEq(initialSticks, 2, "Should have 2 sticks");

        // get the next unique token id which will be the stone pickaxe
        uint256 nextTokenId = inventorySystem.nextTokenId();
        uint256 stonePickaxeTokenId = nextTokenId << 16 | STONE_PICKAXE;

        craftingSystem.craftItem(STONE_PICKAXE);

        assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), initialCobblestone - 3, "Should use 3 cobblestone");
        assertEq(inventorySystem.balanceOf(PLAYER, STICK), initialSticks - 2, "Should use 2 sticks");
        assertEq(inventorySystem.balanceOf(PLAYER, stonePickaxeTokenId), 1, "Should get 1 stone pickaxe");

        vm.stopPrank();
    }

    function test_RevertWhen_CraftingWithFullInventory() public {
        vm.startPrank(address(craftingSystem));

        // Fill all inventory slots except the last two
        for (uint8 i = 0; i < 35; i++) {
            inventorySystem.addToSlot(PLAYER, i, STONE, 63);
        }

        // Try to craft something
        inventorySystem.mint(PLAYER, WOOD, 1);
        vm.expectRevert(ICraftingSystem.NoInventorySpace.selector);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        craftingSystem.craftItem(WOOD_PLANKS);

        vm.stopPrank();
    }

    function test_CraftingEvents() public {
        vm.startPrank(address(craftingSystem));

        // Prepare for crafting
        inventorySystem.mint(PLAYER, WOOD, 1);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Get the recipe details first
        (uint256[] memory inputIds, uint256[] memory amounts, , ) = craftingSystem.getRecipe(WOOD_PLANKS);

        // Test ItemCrafted event emission
        vm.expectEmit(true, false, false, true);
        emit ItemCrafted(PLAYER, WOOD_PLANKS, inputIds, amounts);
        craftingSystem.craftItem(WOOD_PLANKS);

        vm.stopPrank();
    }

    function test_AddRecipe() public {
        uint256[] memory inputIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        inputIds[0] = DIAMOND;
        inputIds[1] = STICK;
        amounts[0] = 4;
        amounts[1] = 1;
        uint256 outputAmount = 1;
        uint256 customItemId = 12345;

        vm.startPrank(OWNER);

        // Test event emission
        vm.expectEmit(true, false, false, true);
        emit RecipeAdded(customItemId, inputIds, amounts);
        craftingSystem.addRecipe(customItemId, inputIds, amounts, outputAmount);

        // Verify recipe was added correctly
        (uint256[] memory storedInputIds, uint256[] memory storedAmounts, uint256 storedOutputAmount, bool exists) = 
            craftingSystem.getRecipe(customItemId);

        assertTrue(exists, "Recipe should exist");
        assertEq(storedInputIds.length, 2, "Should have 2 input items");
        assertEq(storedInputIds[0], DIAMOND, "First input should be diamond");
        assertEq(storedInputIds[1], STICK, "Second input should be stick");
        assertEq(storedAmounts[0], 4, "Should need 4 diamonds");
        assertEq(storedAmounts[1], 1, "Should need 1 stick");
        assertEq(storedOutputAmount, outputAmount, "Output amount should match");

        vm.stopPrank();
    }

    function test_RemoveRecipe() public {
        uint256[] memory inputIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        inputIds[0] = DIAMOND;
        inputIds[1] = STICK;
        amounts[0] = 4;
        amounts[1] = 1;
        uint256 outputAmount = 1;
        uint256 customItemId = 12345;

        vm.startPrank(OWNER);

        // First add a recipe
        craftingSystem.addRecipe(customItemId, inputIds, amounts, outputAmount);
        
        // Test event emission for removal
        vm.expectEmit(true, false, false, true);
        emit RecipeRemoved(customItemId);
        craftingSystem.removeRecipe(customItemId);

        // Verify recipe was removed
        (, , , bool exists) = craftingSystem.getRecipe(customItemId);
        assertFalse(exists, "Recipe should not exist after removal");

        vm.stopPrank();
    }

    function test_RevertWhen_AddingDuplicateRecipe() public {
        uint256[] memory inputIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        inputIds[0] = DIAMOND;
        inputIds[1] = STICK;
        amounts[0] = 4;
        amounts[1] = 1;
        uint256 outputAmount = 1;
        uint256 customItemId = 12345;

        vm.startPrank(OWNER);

        // Add recipe first time
        craftingSystem.addRecipe(customItemId, inputIds, amounts, outputAmount);

        // Try to add same recipe again
        vm.expectRevert(ICraftingSystem.RecipeAlreadyExists.selector);
        craftingSystem.addRecipe(customItemId, inputIds, amounts, outputAmount);

        vm.stopPrank();
    }

    function test_RevertWhen_RemovingNonexistentRecipe() public {
        vm.startPrank(OWNER);

        vm.expectRevert(ICraftingSystem.RecipeDoesNotExist.selector);
        craftingSystem.removeRecipe(99999);

        vm.stopPrank();
    }

    function test_RevertWhen_NonOwnerManagesRecipes() public {
        uint256[] memory inputIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        inputIds[0] = DIAMOND;
        inputIds[1] = STICK;
        amounts[0] = 4;
        amounts[1] = 1;
        uint256 outputAmount = 1;
        uint256 customItemId = 12345;

        vm.startPrank(PLAYER);

        // Try to add recipe as non-owner
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", PLAYER));
        craftingSystem.addRecipe(customItemId, inputIds, amounts, outputAmount);

        // Try to remove recipe as non-owner
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", PLAYER));
        craftingSystem.removeRecipe(customItemId);

        vm.stopPrank();
    }

    function test_SmeltingSwaps() public {
        vm.startPrank(address(craftingSystem));

        // Test iron ore + coal -> iron ingot swap (should be swap ID 1)
        inventorySystem.mint(PLAYER, IRON_ORE, 1);
        inventorySystem.mint(PLAYER, COAL, 1);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Get swap details
        (uint256[] memory inputItemIds, uint256[] memory inputAmounts, uint256 outputItemId, uint256 outputAmount, bool exists) = craftingSystem.getSwap(1);
        assertTrue(exists, "Swap should exist");
        assertEq(inputItemIds.length, 2, "Should have 2 input items");
        assertEq(inputItemIds[0], IRON_ORE, "First input should be iron ore");
        assertEq(inputItemIds[1], COAL, "Second input should be coal");
        assertEq(inputAmounts[0], 1, "Should need 1 iron ore");
        assertEq(inputAmounts[1], 1, "Should need 1 coal");
        assertEq(outputItemId, IRON_INGOT, "Output should be iron ingot");
        assertEq(outputAmount, 1, "Should get 1 iron ingot per swap");

        // Execute swap
        craftingSystem.executeSwap(1, 1);
        assertEq(inventorySystem.balanceOf(PLAYER, IRON_ORE), 0, "Should have no iron ore left");
        assertEq(inventorySystem.balanceOf(PLAYER, COAL), 0, "Should have no coal left");
        assertEq(inventorySystem.balanceOf(PLAYER, IRON_INGOT), 1, "Should have 1 iron ingot");

        vm.stopPrank();
    }

    function test_CustomBlockSwaps() public {
        vm.startPrank(address(craftingSystem));

        // Test diamond -> orange wool swap (should be swap ID 5)
        inventorySystem.mint(PLAYER, DIAMOND, 1);
        // Also test gold -> orange wool (should be swap ID 20)
        inventorySystem.mint(PLAYER, GOLD_INGOT, 1);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Test diamond -> orange wool (ID 200)
        (uint256[] memory inputItemIds, uint256[] memory inputAmounts, uint256 outputItemId, uint256 outputAmount, bool exists) = craftingSystem.getSwap(5);
        assertTrue(exists, "Diamond swap should exist");
        assertEq(inputItemIds.length, 1, "Should have 1 input item");
        assertEq(inputItemIds[0], DIAMOND, "Input should be diamond");
        assertEq(inputAmounts[0], 1, "Should need 1 diamond");
        assertEq(outputItemId, 200, "Output should be orange wool (ID 200)");
        assertEq(outputAmount, 32, "Should get 32 colored wool per diamond");

        // Execute diamond swap
        craftingSystem.executeSwap(5, 1);
        assertEq(inventorySystem.balanceOf(PLAYER, DIAMOND), 0, "Should have no diamond left");
        assertEq(inventorySystem.balanceOf(PLAYER, 200), 32, "Should have 32 orange wool");

        // Test gold -> same color wool (orange, ID 200)
        (inputItemIds, inputAmounts, outputItemId, outputAmount, exists) = craftingSystem.getSwap(20);
        assertTrue(exists, "Gold swap should exist");
        assertEq(inputItemIds.length, 1, "Should have 1 input item");
        assertEq(inputItemIds[0], GOLD_INGOT, "Input should be gold ingot");
        assertEq(inputAmounts[0], 1, "Should need 1 gold ingot");
        assertEq(outputItemId, 200, "Output should be orange wool (ID 200)");
        assertEq(outputAmount, 16, "Should get 16 colored wool per gold ingot");

        // Execute gold swap
        craftingSystem.executeSwap(20, 1);
        assertEq(inventorySystem.balanceOf(PLAYER, GOLD_INGOT), 0, "Should have no gold ingot left");
        assertEq(inventorySystem.balanceOf(PLAYER, 200), 48, "Should have 48 orange wool total (32 from diamond + 16 from gold)");

        // Test that both materials can make the last color (black wool, ID 214)
        vm.stopPrank();
        vm.startPrank(address(craftingSystem));
        inventorySystem.mint(PLAYER, DIAMOND, 1);
        inventorySystem.mint(PLAYER, GOLD_INGOT, 1);
        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Diamond -> black wool
        (inputItemIds, inputAmounts, outputItemId, outputAmount, exists) = craftingSystem.getSwap(19);
        assertTrue(exists, "Diamond swap for black wool should exist");
        assertEq(outputItemId, 214, "Output should be black wool (ID 214)");
        assertEq(outputAmount, 32, "Should get 32 black wool per diamond");

        // Gold -> black wool
        (inputItemIds, inputAmounts, outputItemId, outputAmount, exists) = craftingSystem.getSwap(34);
        assertTrue(exists, "Gold swap for black wool should exist");
        assertEq(outputItemId, 214, "Output should be black wool (ID 214)");
        assertEq(outputAmount, 16, "Should get 16 black wool per gold");

        // Execute both swaps
        craftingSystem.executeSwap(19, 1);  // Diamond -> black wool
        craftingSystem.executeSwap(34, 1);  // Gold -> black wool
        assertEq(inventorySystem.balanceOf(PLAYER, 214), 48, "Should have 48 black wool total (32 from diamond + 16 from gold)");

        vm.stopPrank();
    }

    function test_BlockSwaps() public {
        vm.startPrank(address(craftingSystem));

        // Test iron ore + coal -> iron ingot swap (should be swap ID 1)
        inventorySystem.mint(PLAYER, IRON_ORE, 5);
        inventorySystem.mint(PLAYER, COAL, 5);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Get swap details
        (uint256[] memory inputItemIds, uint256[] memory inputAmounts, uint256 outputItemId, uint256 outputAmount, bool exists) = craftingSystem.getSwap(1);
        assertTrue(exists, "Swap should exist");
        assertEq(inputItemIds.length, 2, "Should have 2 input items");
        assertEq(inputItemIds[0], IRON_ORE, "First input should be iron ore");
        assertEq(inputItemIds[1], COAL, "Second input should be coal");
        assertEq(inputAmounts[0], 1, "Should need 1 iron ore");
        assertEq(inputAmounts[1], 1, "Should need 1 coal");
        assertEq(outputItemId, IRON_INGOT, "Output should be iron ingot");
        assertEq(outputAmount, 1, "Should get 1 iron ingot per swap");

        // Execute swap
        craftingSystem.executeSwap(1, 3); // Swap 3 iron ore + 3 coal
        assertEq(inventorySystem.balanceOf(PLAYER, IRON_ORE), 2, "Should have 2 iron ore left");
        assertEq(inventorySystem.balanceOf(PLAYER, COAL), 2, "Should have 2 coal left");
        assertEq(inventorySystem.balanceOf(PLAYER, IRON_INGOT), 3, "Should have 3 iron ingots");

        vm.stopPrank();
    }

    function test_RevertWhen_SwapDoesNotExist() public {
        vm.startPrank(PLAYER);
        
        vm.expectRevert(ICraftingSystem.SwapDoesNotExist.selector);
        craftingSystem.executeSwap(999, 1);
        
        vm.stopPrank();
    }

    function test_RevertWhen_InsufficientMaterialsForSwap() public {
        vm.startPrank(PLAYER);
        
        // Try to swap without having any materials
        vm.expectRevert(ICraftingSystem.InsufficientMaterials.selector);
        craftingSystem.executeSwap(1, 1);
        
        vm.stopPrank();
    }

    function test_SwapEvents() public {
        vm.startPrank(address(craftingSystem));

        // Mint some iron ore and coal
        inventorySystem.mint(PLAYER, IRON_ORE, 1);
        inventorySystem.mint(PLAYER, COAL, 1);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Test SwapExecuted event emission
        vm.expectEmit(true, true, false, true);
        uint256[] memory expectedInputIds = new uint256[](2);
        expectedInputIds[0] = IRON_ORE;
        expectedInputIds[1] = COAL;
        emit SwapExecuted(PLAYER, 1, expectedInputIds, IRON_INGOT, 1);
        craftingSystem.executeSwap(1, 1);

        vm.stopPrank();
    }

    function test_TransferItems() public {
        address RECIPIENT = address(0x123);
        
        vm.startPrank(address(craftingSystem));
        // Mint some regular items to the player
        inventorySystem.mint(PLAYER, WOOD, 10);
        inventorySystem.mint(PLAYER, STONE, 5);
        vm.stopPrank();

        vm.startPrank(PLAYER);
        
        // Test transferring wood
        craftingSystem.transferItems(RECIPIENT, WOOD, 5);
        assertEq(inventorySystem.balanceOf(PLAYER, WOOD), 5, "Player should have 5 wood left");
        assertEq(inventorySystem.balanceOf(RECIPIENT, WOOD), 5, "Recipient should have 5 wood");

        // Test transferring stone
        craftingSystem.transferItems(RECIPIENT, STONE, 3);
        assertEq(inventorySystem.balanceOf(PLAYER, STONE), 2, "Player should have 2 stone left");
        assertEq(inventorySystem.balanceOf(RECIPIENT, STONE), 3, "Recipient should have 3 stone");

        vm.stopPrank();
    }

    function test_RevertWhen_TransferringTools() public {
        address RECIPIENT = address(0x123);
        
        vm.startPrank(address(craftingSystem));
        // First mint materials for a wooden pickaxe
        inventorySystem.mint(PLAYER, WOOD_PLANKS, 3);  // Need 3 planks
        inventorySystem.mint(PLAYER, STICK, 2);        // Need 2 sticks
        vm.stopPrank();

        vm.startPrank(PLAYER);
        
        // Craft the wooden pickaxe
        craftingSystem.craftItem(WOODEN_PICKAXE);

        // Try to transfer the wooden pickaxe
        uint256 pickaxeId = (inventorySystem.nextTokenId() - 1) << 16 | WOODEN_PICKAXE;
        vm.expectRevert("Cannot transfer unique items");
        craftingSystem.transferItems(RECIPIENT, pickaxeId, 1);

        vm.stopPrank();
    }

    function test_RevertWhen_TransferringInvalidAmount() public {
        address RECIPIENT = address(0x123);
        
        vm.startPrank(PLAYER);
        
        // Try to transfer 0 items
        vm.expectRevert("Invalid amount");
        craftingSystem.transferItems(RECIPIENT, WOOD, 0);

        vm.stopPrank();
    }

    function test_RevertWhen_TransferringToInvalidAddress() public {
        vm.startPrank(PLAYER);
        
        // Try to transfer to zero address
        vm.expectRevert("Invalid recipient");
        craftingSystem.transferItems(address(0), WOOD, 1);

        vm.stopPrank();
    }

    function test_RevertWhen_TransferringMoreThanOwned() public {
        address RECIPIENT = address(0x123);
        
        vm.startPrank(address(craftingSystem));
        // Mint some wood to the player
        inventorySystem.mint(PLAYER, WOOD, 5);
        vm.stopPrank();

        vm.startPrank(PLAYER);
        
        // Try to transfer more than owned
        vm.expectRevert(ICraftingSystem.InsufficientMaterials.selector);
        craftingSystem.transferItems(RECIPIENT, WOOD, 10);

        vm.stopPrank();
    }

    function test_MineralBlockRecipes() public {
        vm.startPrank(address(craftingSystem));

        // Mint materials for testing
        inventorySystem.mint(PLAYER, IRON_INGOT, 9);
        inventorySystem.mint(PLAYER, GOLD_INGOT, 9);
        inventorySystem.mint(PLAYER, DIAMOND, 9);
        inventorySystem.mint(PLAYER, LAPIS_LAZULI, 9);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Test Iron Block recipe
        (uint256[] memory inputIds, uint256[] memory amounts, uint256 outputAmount, bool exists) = craftingSystem.getRecipe(IRON_BLOCK);
        assertTrue(exists, "Iron block recipe should exist");
        assertEq(inputIds.length, 1, "Iron block should have 1 ingredient");
        assertEq(inputIds[0], IRON_INGOT, "Input should be iron ingot");
        assertEq(amounts[0], 9, "Should need 9 iron ingots");
        assertEq(outputAmount, 1, "Should get 1 iron block");

        // Test Gold Block recipe
        (inputIds, amounts, outputAmount, exists) = craftingSystem.getRecipe(GOLD_BLOCK);
        assertTrue(exists, "Gold block recipe should exist");
        assertEq(inputIds.length, 1, "Gold block should have 1 ingredient");
        assertEq(inputIds[0], GOLD_INGOT, "Input should be gold ingot");
        assertEq(amounts[0], 9, "Should need 9 gold ingots");
        assertEq(outputAmount, 1, "Should get 1 gold block");

        // Test Diamond Block recipe
        (inputIds, amounts, outputAmount, exists) = craftingSystem.getRecipe(DIAMOND_BLOCK);
        assertTrue(exists, "Diamond block recipe should exist");
        assertEq(inputIds.length, 1, "Diamond block should have 1 ingredient");
        assertEq(inputIds[0], DIAMOND, "Input should be diamond");
        assertEq(amounts[0], 9, "Should need 9 diamonds");
        assertEq(outputAmount, 1, "Should get 1 diamond block");

        // Test Lapis Block recipe
        (inputIds, amounts, outputAmount, exists) = craftingSystem.getRecipe(LAPIS_BLOCK);
        assertTrue(exists, "Lapis block recipe should exist");
        assertEq(inputIds.length, 1, "Lapis block should have 1 ingredient");
        assertEq(inputIds[0], LAPIS_LAZULI, "Input should be lapis lazuli");
        assertEq(amounts[0], 9, "Should need 9 lapis lazuli");
        assertEq(outputAmount, 1, "Should get 1 lapis block");

        // Test crafting each block
        craftingSystem.craftItem(IRON_BLOCK);
        craftingSystem.craftItem(GOLD_BLOCK);
        craftingSystem.craftItem(DIAMOND_BLOCK);
        craftingSystem.craftItem(LAPIS_BLOCK);

        // Verify blocks were crafted and materials consumed
        assertEq(inventorySystem.balanceOf(PLAYER, IRON_BLOCK), 1, "Should have 1 iron block");
        assertEq(inventorySystem.balanceOf(PLAYER, GOLD_BLOCK), 1, "Should have 1 gold block");
        assertEq(inventorySystem.balanceOf(PLAYER, DIAMOND_BLOCK), 1, "Should have 1 diamond block");
        assertEq(inventorySystem.balanceOf(PLAYER, LAPIS_BLOCK), 1, "Should have 1 lapis block");

        assertEq(inventorySystem.balanceOf(PLAYER, IRON_INGOT), 0, "Should have no iron ingots left");
        assertEq(inventorySystem.balanceOf(PLAYER, GOLD_INGOT), 0, "Should have no gold ingots left");
        assertEq(inventorySystem.balanceOf(PLAYER, DIAMOND), 0, "Should have no diamonds left");
        assertEq(inventorySystem.balanceOf(PLAYER, LAPIS_LAZULI), 0, "Should have no lapis lazuli left");

        vm.stopPrank();
    }
} 