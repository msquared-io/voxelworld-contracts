// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TestHelper.sol";
import "../../contracts/interfaces/IOverlaySystem.sol";
import "../../contracts/interfaces/IInventorySystem.sol";

contract OverlaySystemTest is TestHelper {
    function setUp() public override {
        super.setUp();
    }

    function test_BlockRemovalWithoutTool() public {
        vm.startPrank(OWNER);
        chunkSystem.createChunk(0, 0, 0);
        vm.stopPrank();

        vm.startPrank(address(overlaySystem));

        // Place a stone block
        inventorySystem.mint(PLAYER, STONE, 1);

        vm.stopPrank();

        vm.startPrank(PLAYER);
        overlaySystem.placeBlock(0, 0, 0, uint8(STONE));

        // Try to remove it without a pickaxe (using empty slot 0)
        inventorySystem.setSelectedSlot(0);
        overlaySystem.removeBlock(0, 0, 0);

        // Block should be removed but no items given
        assertEq(inventorySystem.balanceOf(PLAYER, STONE), 0, "Should not receive stone without proper tool");

        vm.stopPrank();
    }

    function test_NoToolBlockRemoval() public {
        vm.startPrank(OWNER);
        // Create chunks first
        chunkSystem.createChunk(0, 0, 0);
        vm.stopPrank();

        vm.startPrank(address(overlaySystem));
        // Test grass block
        inventorySystem.mint(PLAYER, GRASS, 1);

        vm.stopPrank();

        vm.startPrank(PLAYER);
        overlaySystem.placeBlock(0, 0, 0, uint8(GRASS));
        
        // Initial balance should be 0 after placing
        assertEq(inventorySystem.balanceOf(PLAYER, GRASS), 0, "Should have no grass after placing");
        
        // Remove grass block without any tools (using empty slot 0)
        inventorySystem.setSelectedSlot(0);
        overlaySystem.removeBlock(0, 0, 0);
        
        // Should get grass block back
        assertEq(inventorySystem.balanceOf(PLAYER, GRASS), 1, "Should receive grass block without needing tools");

        // Test wood block
        vm.stopPrank();
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, WOOD, 1);
        vm.stopPrank();
        vm.startPrank(PLAYER);
        overlaySystem.placeBlock(0, 0, 1, uint8(WOOD));
        
        // Initial balance should be 0 after placing
        assertEq(inventorySystem.balanceOf(PLAYER, WOOD), 0, "Should have no wood after placing");
        
        // Remove wood block without any tools (using empty slot 0)
        inventorySystem.setSelectedSlot(0);
        overlaySystem.removeBlock(0, 0, 1);
        
        // Should get wood block back
        assertEq(inventorySystem.balanceOf(PLAYER, WOOD), 1, "Should receive wood block without needing tools");

        vm.stopPrank();
    }

    function test_BlockRemovalWithTool() public {
        vm.startPrank(OWNER);
        chunkSystem.createChunk(0, 0, 0);
        vm.stopPrank();

        vm.startPrank(address(overlaySystem));

        // Give player a wooden pickaxe and some stone
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.mint(PLAYER, STONE, 1);

        vm.stopPrank();

        vm.startPrank(PLAYER);

        // Place a stone block
        overlaySystem.placeBlock(0, 0, 0, uint8(STONE));

        // Initial stone balance should be 0 after placing
        assertEq(inventorySystem.balanceOf(PLAYER, STONE), 0, "Should have no stone after placing");

        // Remove the stone block with wooden pickaxe in slot 0
        inventorySystem.setSelectedSlot(0);
        overlaySystem.removeBlock(0, 0, 0);

        // Should get cobblestone instead of stone
        assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), 1, "Should receive cobblestone when using proper tool");

        vm.stopPrank();
    }

    function test_BlockRemovalWithToolDurability() public {
        vm.startPrank(OWNER);
        // Create chunks for all positions we'll use
        for(int32 i = 0; i < 5; i++) {
            chunkSystem.createChunk(i, 0, 0);
        }
        vm.stopPrank();

        vm.startPrank(address(overlaySystem));

        // First give stone
        inventorySystem.mint(PLAYER, STONE, 63);
        
        // Then give pickaxes in slots 1-5
        for(uint i = 0; i < 5; i++) {
            inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        }

        vm.stopPrank();

        vm.startPrank(PLAYER);

        // Initial balances should be correct
        assertEq(inventorySystem.balanceOf(PLAYER, STONE), 63, "Should have 63 stone initially");
        // assertEq(inventorySystem.balanceOf(PLAYER, WOODEN_PICKAXE), 5, "Should have 5 pickaxes initially");

        // Place first stone block
        overlaySystem.placeBlock(0, 0, 0, uint8(STONE));

        // Place remaining stone blocks
        for(int32 i = 1; i < 5; i++) {
            overlaySystem.placeBlock(i, 0, 0, uint8(STONE));
        }

        // Stone balance should be reduced
        assertEq(inventorySystem.balanceOf(PLAYER, STONE), 58, "Should have 58 stone after placing 5");
        // assertEq(inventorySystem.balanceOf(PLAYER, WOODEN_PICKAXE), 5, "Should still have 5 pickaxes after placing");

        // Remove all stone blocks with wooden pickaxes
        for(int32 i = 0; i < 5; i++) {
            inventorySystem.setSelectedSlot(uint8(uint32(i + 1))); // Use pickaxes from slots 1-5
            overlaySystem.removeBlock(i, 0, 0);
            // After each removal, verify the balances
            uint256 expectedCobblestone = uint256(uint32(i + 1));
            assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), expectedCobblestone, "Should get cobblestone back");
        }

        // Final verification
        assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), 5, "Should have 5 cobblestone back");

        vm.stopPrank();
    }

    function test_BlockRemovalWithMultipleTools() public {
        vm.startPrank(OWNER);
        chunkSystem.createChunk(0, 0, 0);
        vm.stopPrank();

        vm.startPrank(address(overlaySystem));

        // Give player multiple tools and blocks in specific slots
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.mint(PLAYER, STONE_PICKAXE, 1);
        inventorySystem.mint(PLAYER, STONE_PICKAXE, 1);
        inventorySystem.mint(PLAYER, STONE, 1);
        inventorySystem.mint(PLAYER, IRON_ORE, 1);

        vm.stopPrank();

        vm.startPrank(PLAYER);

        // Place blocks
        overlaySystem.placeBlock(0, 0, 0, uint8(STONE));  // Requires wooden pickaxe
        overlaySystem.placeBlock(0, 0, 1, uint8(IRON_ORE));  // Requires stone pickaxe

        // Remove stone with wooden pickaxe in slot 0
        inventorySystem.setSelectedSlot(0);
        overlaySystem.removeBlock(0, 0, 0);
        assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), 1, "Should receive cobblestone with wooden pickaxe");

        // Remove iron ore with stone pickaxe in slot 2
        inventorySystem.setSelectedSlot(2);
        overlaySystem.removeBlock(0, 0, 1);
        assertEq(inventorySystem.balanceOf(PLAYER, IRON_ORE), 1, "Should receive iron ore with stone pickaxe");

        vm.stopPrank();
    }

    function test_MixedBlockRemoval() public {
        vm.startPrank(OWNER);
        chunkSystem.createChunk(0, 0, 0);
        vm.stopPrank();

        vm.startPrank(address(overlaySystem));

        // Give player one of each block type in specific slots
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.mint(PLAYER, STONE, 1);
        inventorySystem.mint(PLAYER, GRASS, 1);
        inventorySystem.mint(PLAYER, WOOD, 1);

        vm.stopPrank();

        vm.startPrank(PLAYER);

        // Place all blocks
        overlaySystem.placeBlock(0, 0, 0, uint8(STONE));  // Requires pickaxe
        overlaySystem.placeBlock(0, 0, 1, uint8(GRASS));  // No tool required
        overlaySystem.placeBlock(0, 0, 2, uint8(WOOD));   // No tool required

        // Initial balances should be 0 after placing
        assertEq(inventorySystem.balanceOf(PLAYER, STONE), 0, "Should have no stone after placing");
        assertEq(inventorySystem.balanceOf(PLAYER, GRASS), 0, "Should have no grass after placing");
        assertEq(inventorySystem.balanceOf(PLAYER, WOOD), 0, "Should have no wood after placing");

        // Remove blocks in different order
        inventorySystem.setSelectedSlot(4); // Remove grass with empty slot
        overlaySystem.removeBlock(0, 0, 1);
        inventorySystem.setSelectedSlot(4); // Remove wood with empty slot
        overlaySystem.removeBlock(0, 0, 2);
        inventorySystem.setSelectedSlot(0); // Remove stone with wooden pickaxe
        overlaySystem.removeBlock(0, 0, 0);

        // Final balances should match initial
        assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), 1, "Should have cobblestone back");
        assertEq(inventorySystem.balanceOf(PLAYER, GRASS), 1, "Should have grass back");
        assertEq(inventorySystem.balanceOf(PLAYER, WOOD), 1, "Should have wood back");

        vm.stopPrank();
    }

    function test_StoneGivesCobblestone() public {
        vm.startPrank(OWNER);
        chunkSystem.createChunk(0, 0, 0);
        vm.stopPrank();

        vm.startPrank(address(overlaySystem));

        // Give player a wooden pickaxe and stone
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.mint(PLAYER, STONE, 1);

        vm.stopPrank();

        vm.startPrank(PLAYER);

        // Place a stone block
        overlaySystem.placeBlock(0, 0, 0, uint8(STONE));

        // Initial balances
        assertEq(inventorySystem.balanceOf(PLAYER, STONE), 0, "Should have no stone after placing");
        assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), 0, "Should have no cobblestone initially");

        // Remove the stone block with wooden pickaxe in slot 0
        inventorySystem.setSelectedSlot(0);
        overlaySystem.removeBlock(0, 0, 0);

        // Should get cobblestone instead of stone
        assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), 1, "Should receive cobblestone instead");

        vm.stopPrank();
    }

    function test_SelectedSlotChanged() public {
        vm.startPrank(PLAYER);

        // Test that event is emitted when setting slot
        vm.expectEmit(true, false, false, true);
        emit IInventorySystem.SelectedSlotChanged(PLAYER, 5);
        inventorySystem.setSelectedSlot(5);

        // Test that event is emitted when changing slot
        vm.expectEmit(true, false, false, true);
        emit IInventorySystem.SelectedSlotChanged(PLAYER, 2);
        inventorySystem.setSelectedSlot(2);

        // Test that the slot value is actually stored
        assertEq(inventorySystem.getSelectedSlot(PLAYER), 2, "Selected slot should be updated");

        // Test that event is emitted for a different player
        vm.stopPrank();
        vm.startPrank(OWNER);
        
        vm.expectEmit(true, false, false, true);
        emit IInventorySystem.SelectedSlotChanged(OWNER, 3);
        inventorySystem.setSelectedSlot(3);

        // Verify each player has their own slot stored
        assertEq(inventorySystem.getSelectedSlot(OWNER), 3, "Owner's selected slot should be 3");
        assertEq(inventorySystem.getSelectedSlot(PLAYER), 2, "Player's selected slot should still be 2");

        vm.stopPrank();
    }

    function test_WipeChunkOverlay() public {
        vm.startPrank(OWNER);
        // Create chunk
        chunkSystem.createChunk(0, 0, 0);
        vm.stopPrank();

        vm.startPrank(address(overlaySystem));
        // Give player some blocks
        inventorySystem.mint(PLAYER, STONE, 3);
        inventorySystem.mint(PLAYER, GRASS, 3);
        vm.stopPrank();

        vm.startPrank(PLAYER);
        // Place multiple blocks in the chunk
        overlaySystem.placeBlock(0, 0, 0, uint8(STONE));
        overlaySystem.placeBlock(0, 1, 0, uint8(STONE));
        overlaySystem.placeBlock(0, 2, 0, uint8(GRASS));
        vm.stopPrank();

        // Verify blocks are in the overlay
        (uint16[] memory positions, uint8[] memory blockTypes) = overlaySystem.getChunkOverlay(0, 0, 0);
        assertEq(positions.length, 3, "Should have 3 blocks in overlay before wiping");
        assertEq(blockTypes.length, 3, "Should have 3 block types in overlay before wiping");

        // Non-owner should not be able to wipe
        vm.startPrank(PLAYER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", PLAYER));
        overlaySystem.wipeChunkOverlay(0, 0, 0);
        vm.stopPrank();

        // Owner wipes the chunk overlay
        vm.startPrank(OWNER);
        overlaySystem.wipeChunkOverlay(0, 0, 0);
        vm.stopPrank();

        // Verify overlay is empty
        (positions, blockTypes) = overlaySystem.getChunkOverlay(0, 0, 0);
        assertEq(positions.length, 0, "Should have no blocks in overlay after wiping");
        assertEq(blockTypes.length, 0, "Should have no block types in overlay after wiping");
    }

    function test_WipeChunkOverlayNonexistentChunk() public {
        // Try to wipe a nonexistent chunk
        vm.startPrank(OWNER);
        vm.expectRevert(IOverlaySystem.ChunkDoesNotExist.selector);
        overlaySystem.wipeChunkOverlay(999, 999, 999);
        vm.stopPrank();
    }

    function test_WipeChunkOverlayEmptyChunk() public {
        vm.startPrank(OWNER);
        // Create empty chunk
        chunkSystem.createChunk(0, 0, 0);
        
        // Should succeed but have no effect
        overlaySystem.wipeChunkOverlay(0, 0, 0);
        
        // Verify overlay is empty
        (uint16[] memory positions, uint8[] memory blockTypes) = overlaySystem.getChunkOverlay(0, 0, 0);
        assertEq(positions.length, 0, "Should have no blocks in overlay");
        assertEq(blockTypes.length, 0, "Should have no block types in overlay");
        vm.stopPrank();
    }
} 