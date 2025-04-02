// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TestHelper.sol";

contract CraftingSystemTest is TestHelper {
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
        vm.startPrank(PLAYER);

        // get the next unique token id which will be the wooden pickaxe
        uint256 nextTokenId = inventorySystem.nextTokenId();
        uint256 woodenPickaxeTokenId = nextTokenId << 16 | WOODEN_PICKAXE;

        // Test crafting wooden planks from wood
        inventorySystem.mint(PLAYER, WOOD, 1);
        craftingSystem.craftItem(WOOD_PLANKS);
        assertEq(inventorySystem.balanceOf(PLAYER, WOOD_PLANKS), 4, "Should get 4 wooden planks from 1 wood");

        // Test crafting sticks from planks
        // We need 2 planks to craft sticks, and we have 4 from previous craft
        craftingSystem.craftItem(STICK);
        assertEq(inventorySystem.balanceOf(PLAYER, STICK), 4, "Should get 4 sticks from 2 planks");

        // Test crafting wooden pickaxe
        // Need 3 planks and 2 sticks
        // We used 2 planks for sticks, so mint 1 more wood for more planks
        inventorySystem.mint(PLAYER, WOOD, 1);
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
        vm.startPrank(PLAYER);

        // Now mint exactly what we need
        inventorySystem.mint(PLAYER, COBBLESTONE, 3);
        inventorySystem.mint(PLAYER, STICK, 2);

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
        vm.startPrank(PLAYER);

        // Fill all inventory slots except the last two
        for (uint8 i = 0; i < 35; i++) {
            inventorySystem.addToSlot(PLAYER, i, STONE, 63);
        }

        // Try to craft something
        inventorySystem.mint(PLAYER, WOOD, 1);
        vm.expectRevert(ICraftingSystem.NoInventorySpace.selector);
        craftingSystem.craftItem(WOOD_PLANKS);

        vm.stopPrank();
    }

    function test_CraftingEvents() public {
        vm.startPrank(PLAYER);

        // Prepare for crafting
        inventorySystem.mint(PLAYER, WOOD, 1);

        // Get the recipe details first
        (uint256[] memory inputIds, uint256[] memory amounts, , ) = craftingSystem.getRecipe(WOOD_PLANKS);

        // Test ItemCrafted event emission
        vm.expectEmit(true, false, false, true);
        emit ItemCrafted(PLAYER, WOOD_PLANKS, inputIds, amounts);
        craftingSystem.craftItem(WOOD_PLANKS);

        vm.stopPrank();
    }
} 