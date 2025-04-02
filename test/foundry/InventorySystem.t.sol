// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TestHelper.sol";
import "../../contracts/interfaces/IInventorySystem.sol";

contract InventorySystemTest is TestHelper {
    function setUp() public override {
        super.setUp();
    }

    function test_BasicInventoryOperations() public {
        // Test initialization
        assertEq(inventorySystem.name(), "Voxel World Items");
        assertEq(inventorySystem.symbol(), "VW");

        // Test adding items to empty slots
        vm.startPrank(PLAYER);
        
        uint8 slot = 0;
        uint256 amount = 5;
        
        inventorySystem.addToSlot(PLAYER, slot, STONE, amount);
        
        assertEq(inventorySystem.inventorySlots(PLAYER, slot), STONE);
        assertEq(inventorySystem.slotCounts(PLAYER, slot), amount);

        // Test moving partial stack to empty slot
        uint8 fromSlot = 0;
        uint8 toSlot = 2;
        uint256 moveAmount = 2;

        uint256 initialFromAmount = inventorySystem.slotCounts(PLAYER, fromSlot);
        inventorySystem.moveItems(PLAYER, fromSlot, toSlot, moveAmount);

        assertEq(inventorySystem.slotCounts(PLAYER, fromSlot), initialFromAmount - moveAmount);
        assertEq(inventorySystem.slotCounts(PLAYER, toSlot), moveAmount);
        assertEq(inventorySystem.inventorySlots(PLAYER, toSlot), STONE);

        // Test removing items from slots
        uint8 removeSlot = 2;
        uint256 removeAmount = 1;

        uint256 initialAmount = inventorySystem.slotCounts(PLAYER, removeSlot);
        inventorySystem.removeFromSlot(PLAYER, removeSlot, removeAmount);

        assertEq(inventorySystem.slotCounts(PLAYER, removeSlot), initialAmount - removeAmount);

        vm.stopPrank();
    }

    function test_ToolValidation() view public {
        // Test tool validation for different block types
        assertTrue(inventorySystem.isValidToolForBlock(WOODEN_PICKAXE, uint8(STONE)), "Wooden pickaxe should work on stone");
        assertTrue(inventorySystem.isValidToolForBlock(STONE_PICKAXE, uint8(IRON_ORE)), "Stone pickaxe should work on iron ore");
        assertTrue(inventorySystem.isValidToolForBlock(IRON_PICKAXE, uint8(DIAMOND_ORE)), "Iron pickaxe should work on diamond ore");
        assertTrue(inventorySystem.isValidToolForBlock(DIAMOND_PICKAXE, uint8(DIAMOND_ORE)), "Diamond pickaxe should work on diamond ore");
        assertTrue(inventorySystem.isValidToolForBlock(SHEARS, uint8(LEAVES)), "Shears should work on leaves");
        
        // Test invalid tool combinations
        assertFalse(inventorySystem.isValidToolForBlock(WOODEN_PICKAXE, uint8(DIAMOND_ORE)), "Wooden pickaxe should not work on diamond ore");
        assertFalse(inventorySystem.isValidToolForBlock(STONE_PICKAXE, uint8(DIAMOND_ORE)), "Stone pickaxe should not work on diamond ore");
        assertFalse(inventorySystem.isValidToolForBlock(WOODEN_PICKAXE, uint8(LEAVES)), "Pickaxe should not work on leaves");
    }

    // function test_ToolUsage() public {
    //     vm.startPrank(PLAYER);

    //     // Add tools to inventory
    //     inventorySystem.addToSlot(PLAYER, 0, WOODEN_PICKAXE, 1);
    //     inventorySystem.addToSlot(PLAYER, 1, IRON_PICKAXE, 1);
    //     inventorySystem.addToSlot(PLAYER, 2, SHEARS, 1);

    //     // Test using correct tool
    //     assertTrue(inventorySystem.useToolFromSlot(PLAYER, 0, uint8(STONE)), "Should be able to use wooden pickaxe on stone");
    //     (uint256 itemId0,) = inventorySystem.getSlotData(PLAYER, 0);
    //     assertEq(itemId0, 0, "Tool should be consumed");

    //     // Test using better tool than required
    //     assertTrue(inventorySystem.useToolFromSlot(PLAYER, 1, uint8(STONE)), "Should be able to use iron pickaxe on stone");
    //     (uint256 itemId1,) = inventorySystem.getSlotData(PLAYER, 1);
    //     assertEq(itemId1, 0, "Tool should be consumed");

    //     // Test using correct tool for special case (shears)
    //     assertTrue(inventorySystem.useToolFromSlot(PLAYER, 2, uint8(LEAVES)), "Should be able to use shears on leaves");
    //     (uint256 itemId2,) = inventorySystem.getSlotData(PLAYER, 2);
    //     assertEq(itemId2, 0, "Tool should be consumed");

    //     vm.stopPrank();
    // }

    function test_BlockBreaking() public {
        // Create the chunk first
        vm.startPrank(OWNER);
        chunkSystem.createChunk(0, 4, 0);
        vm.stopPrank();

        vm.startPrank(PLAYER);

        // Add tools and stone block
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.addToSlot(PLAYER, 1, STONE, 1);

        // Place the stone block
        overlaySystem.placeBlock(0, 64, 0, uint8(STONE));

        // Try breaking stone with wooden pickaxe
        inventorySystem.setSelectedSlot(0);
        overlaySystem.removeBlock(0, 64, 0);

        // Verify tool was consumed
        // assertEq(inventorySystem.balanceOf(PLAYER, WOODEN_PICKAXE), 0, "Tool should be consumed");
        assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), 1, "Should receive cobblestone block");

        // Test breaking without proper tool
        inventorySystem.setSelectedSlot(1);
        overlaySystem.removeBlock(0, 64, 1); // Try breaking stone without tool
        assertEq(inventorySystem.balanceOf(PLAYER, COBBLESTONE), 1, "Should not receive additional cobblestone block");

        vm.stopPrank();
    }

    function test_ToolManagement() public {
        vm.startPrank(PLAYER);

        // Test wooden pickaxe for stone mining
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        (uint256 toolId,) = inventorySystem.getSlotData(PLAYER, 0);
        assertTrue(inventorySystem.isValidToolForBlock(toolId, uint8(STONE)), "Wooden pickaxe should work on stone");
        assertFalse(inventorySystem.isValidToolForBlock(toolId, uint8(IRON_ORE)), "Wooden pickaxe should not work on iron ore");

        // Test shears for leaves
        assertFalse(inventorySystem.isValidToolForBlock(toolId, uint8(LEAVES)), "Pickaxe should not work on leaves");
        inventorySystem.addToSlot(PLAYER, 1, SHEARS, 1);
        (uint256 shearsId,) = inventorySystem.getSlotData(PLAYER, 1);
        assertTrue(inventorySystem.isValidToolForBlock(shearsId, uint8(LEAVES)), "Shears should work on leaves");

        // Test removing shears
        inventorySystem.removeFromSlot(PLAYER, 1, 1);
        (uint256 emptyId,) = inventorySystem.getSlotData(PLAYER, 1);
        assertFalse(inventorySystem.isValidToolForBlock(emptyId, uint8(LEAVES)), "Empty slot should not work on leaves");

        vm.stopPrank();
    }

    function test_ERC1155Functionality() public {
        vm.startPrank(PLAYER);

        // Test minting
        uint256 amount = 10;
        inventorySystem.mint(PLAYER, STONE, amount);
        assertEq(inventorySystem.balanceOf(PLAYER, STONE), amount);

        // Test burning
        uint256 burnAmount = 5;
        uint256 initialBalance = inventorySystem.balanceOf(PLAYER, STONE);
        inventorySystem.burn(PLAYER, STONE, burnAmount);
        assertEq(inventorySystem.balanceOf(PLAYER, STONE), initialBalance - burnAmount);

        // Test URI
        string memory tokenUri = inventorySystem.uri(STONE);
        assertTrue(bytes(tokenUri).length > 0);

        vm.stopPrank();
    }

    function test_InventoryContents() public {
        vm.startPrank(PLAYER);

        // Initially inventory should be empty
        InventoryItem[] memory emptyContents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(emptyContents.length, 0, "Initial inventory should be empty");

        // Test minting items goes into first available slot
        inventorySystem.mint(PLAYER, STONE, 5);
        InventoryItem[] memory contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents.length, 1, "Should have one item type");
        assertEq(contents[0].slot, 0, "Should be in first slot");
        assertEq(contents[0].itemId, STONE, "Should be stone");
        assertEq(contents[0].amount, 5, "Should have 5 stones");
        assertEq(contents[0].name, "Stone", "Should have correct name");

        // Test minting same item type stacks in same slot if possible
        inventorySystem.mint(PLAYER, STONE, 3);
        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents.length, 1, "Should still have one item type");
        assertEq(contents[0].amount, 8, "Should have 8 stones total");

        // Test minting tool goes into new slot
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents.length, 2, "Should have two item types");
        
        // Find the pickaxe (should be in slot 1)
        bool foundPickaxe = false;
        for (uint i = 0; i < contents.length; i++) {
            if (contents[i].itemId & 0xFFFF == WOODEN_PICKAXE) {
                foundPickaxe = true;
                assertEq(contents[i].slot, 1, "Pickaxe should be in second slot");
                assertEq(contents[i].amount, 1, "Should have 1 pickaxe");
                assertEq(contents[i].name, "Wooden Pickaxe", "Should have correct name");
            }
        }
        assertTrue(foundPickaxe, "Should have found the pickaxe");

        // Test minting beyond stack size creates new slot
        inventorySystem.mint(PLAYER, STONE, 60);
        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents.length, 3, "Should have three item stacks");
        
        // Verify stone distribution across slots
        uint256 totalStone = 0;
        bool foundFullStack = false;
        bool foundPartialStack = false;
        
        for (uint i = 0; i < contents.length; i++) {
            if (contents[i].itemId == STONE) {
                totalStone += contents[i].amount;
                if (contents[i].amount == 63) foundFullStack = true;
                if (contents[i].amount < 63) foundPartialStack = true;
            }
        }
        
        assertEq(totalStone, 68, "Should have 68 stones total");
        assertTrue(foundFullStack, "Should have a full stack of stones");
        assertTrue(foundPartialStack, "Should have a partial stack of stones");

        vm.stopPrank();
    }

    function test_ItemStackingPriority() public {
        vm.startPrank(PLAYER);

        // First create some existing stacks with space
        inventorySystem.mint(PLAYER, STONE, 60); // First slot almost full
        inventorySystem.mint(PLAYER, DIRT, 1);   // Second slot with different item
        inventorySystem.mint(PLAYER, STONE, 40); // Third slot partially full

        // Verify initial state
        InventoryItem[] memory initialContents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(initialContents.length, 3, "Should have three item stacks initially");

        // Now mint more stone - should go to the non-full existing stack first
        inventorySystem.mint(PLAYER, STONE, 10);

        // Check final state
        InventoryItem[] memory finalContents = inventorySystem.getInventoryContents(PLAYER);
        
        // Find the stone stacks and verify distribution
        uint256 stack1Amount = 0;
        uint256 stack2Amount = 0;
        for (uint i = 0; i < finalContents.length; i++) {
            if (finalContents[i].itemId == STONE) {
                if (stack1Amount == 0) {
                    stack1Amount = finalContents[i].amount;
                } else {
                    stack2Amount = finalContents[i].amount;
                }
            }
        }

        // Verify that one stack is full and the other contains the remainder
        assertTrue(
            (stack1Amount == 63 && stack2Amount == 47) || 
            (stack1Amount == 47 && stack2Amount == 63),
            "Stone should be properly distributed across stacks"
        );

        // Test that tools don't stack
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        
        finalContents = inventorySystem.getInventoryContents(PLAYER);
        uint256 pickaxeCount = 0;
        for (uint i = 0; i < finalContents.length; i++) {
            if (finalContents[i].itemId & 0xFFFF == WOODEN_PICKAXE) {
                pickaxeCount++;
                assertEq(finalContents[i].amount, 1, "Each pickaxe should be in its own slot");
            }
        }
        assertEq(pickaxeCount, 2, "Should have two separate pickaxe slots");

        vm.stopPrank();
    }

    function test_SwapEntireSlots() public {
        vm.startPrank(PLAYER);

        // Setup: Add two different stacks
        inventorySystem.addToSlot(PLAYER, 0, STONE, 32);
        inventorySystem.addToSlot(PLAYER, 1, DIRT, 16);

        // Test swapping entire stacks
        inventorySystem.moveItems(PLAYER, 0, 1, 32);

        // Verify the swap
        assertEq(inventorySystem.inventorySlots(PLAYER, 0), DIRT, "Slot 0 should now contain dirt");
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 16, "Dirt amount should be 16");
        assertEq(inventorySystem.inventorySlots(PLAYER, 1), STONE, "Slot 1 should now contain stone");
        assertEq(inventorySystem.slotCounts(PLAYER, 1), 32, "Stone amount should be 32");

        vm.stopPrank();
    }

    function test_SwapToolWithItems() public {
        vm.startPrank(PLAYER);

        // Setup: Add a stack of stones and a pickaxe
        inventorySystem.addToSlot(PLAYER, 0, STONE, 32);
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);

        // Test swapping tool with entire stack
        inventorySystem.moveItems(PLAYER, 0, 1, 32);

        // Verify the swap
        assertEq(inventorySystem.inventorySlots(PLAYER, 0) & 0xFFFF, WOODEN_PICKAXE, "Slot 0 should now contain pickaxe");
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 1, "Pickaxe amount should be 1");
        assertEq(inventorySystem.inventorySlots(PLAYER, 1), STONE, "Slot 1 should now contain stone");
        assertEq(inventorySystem.slotCounts(PLAYER, 1), 32, "Stone amount should be 32");

        vm.stopPrank();
    }

    function test_MoveToEmptySlot() public {
        vm.startPrank(PLAYER);

        // Setup: Add a stack of stones
        inventorySystem.addToSlot(PLAYER, 0, STONE, 32);

        // Test moving partial stack to empty slot
        inventorySystem.moveItems(PLAYER, 0, 1, 16);

        // Verify the move
        assertEq(inventorySystem.inventorySlots(PLAYER, 0), STONE, "Slot 0 should still contain stone");
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 16, "Original slot should have 16 stones");
        assertEq(inventorySystem.inventorySlots(PLAYER, 1), STONE, "Slot 1 should now contain stone");
        assertEq(inventorySystem.slotCounts(PLAYER, 1), 16, "New slot should have 16 stones");

        vm.stopPrank();
    }

    function test_MoveToolToEmptySlot() public {
        vm.startPrank(PLAYER);

        // Setup: Add a pickaxe
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);

        // Test moving tool to empty slot
        inventorySystem.moveItems(PLAYER, 0, 1, 1);

        // Verify the move
        assertEq(inventorySystem.inventorySlots(PLAYER, 0), 0, "Original slot should be empty");
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 0, "Original slot should have 0 items");
        assertEq(inventorySystem.inventorySlots(PLAYER, 1) & 0xFFFF, WOODEN_PICKAXE, "New slot should contain pickaxe");
        assertEq(inventorySystem.slotCounts(PLAYER, 1), 1, "New slot should have 1 pickaxe");

        vm.stopPrank();
    }

    function test_RevertWhen_PartialSlotSwap() public {
        vm.startPrank(PLAYER);

        // Setup: Add two different stacks
        inventorySystem.addToSlot(PLAYER, 0, STONE, 32);
        inventorySystem.addToSlot(PLAYER, 1, DIRT, 16);

        // Try to swap partial stack (should fail)
        vm.expectRevert("Must swap entire slot contents");
        inventorySystem.moveItems(PLAYER, 0, 1, 16);


        vm.stopPrank();
    }

    function test_RevertWhen_PartialToolMove() public {
        vm.startPrank(PLAYER);

        // Setup: Add a pickaxe
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);

        // Try to move tool with wrong amount (should fail)
        vm.expectRevert("Insufficient items in source slot");
        inventorySystem.moveItems(PLAYER, 0, 1, 2);

        vm.stopPrank();
    }

    function test_RevertWhen_ExceedMaxStackSize() public {
        vm.startPrank(PLAYER);
        
        uint8 slot = 1;
        uint256 amount = 65; // MAX_STACK_SIZE is 64
        
        vm.expectRevert("Stack size limit exceeded");
        inventorySystem.addToSlot(PLAYER, slot, STONE, amount);
        
        vm.stopPrank();
    }

    function test_RevertWhen_ToolStacking() public {
        vm.startPrank(PLAYER);
        
        uint8 slot = 4;
        
        // First mint a tool
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        
        // Try to add another tool to the same slot
        vm.expectRevert("Tools cannot stack");
        inventorySystem.addToSlot(PLAYER, slot, WOODEN_PICKAXE, 2);


        vm.stopPrank();
    }

    function test_ToolDurability() public {
        vm.startPrank(PLAYER);

        // Test wooden pickaxe durability
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        (, uint256 amount) = inventorySystem.getSlotData(PLAYER, 0);
        assertEq(amount, 1, "Should have 1 wooden pickaxe");
        
        // Get initial durability
        InventoryItem[] memory contents = inventorySystem.getInventoryContents(PLAYER);
        uint16 initialDurability = contents[0].durability;
        assertEq(initialDurability, MinecraftConstants.WOODEN_PICKAXE_DURABILITY, "Should have full durability initially");

        // Use the tool multiple times
        for (uint i = 0; i < initialDurability - 1; i++) {
            assertTrue(inventorySystem.useToolFromSlot(PLAYER, 0, uint8(STONE)), "Should be able to use wooden pickaxe on stone");
            
            // Check durability decreased
            contents = inventorySystem.getInventoryContents(PLAYER);
            assertEq(contents[0].durability, initialDurability - (i + 1), "Durability should decrease by 1");
        }

        // Use the tool one last time - should break
        assertTrue(inventorySystem.useToolFromSlot(PLAYER, 0, uint8(STONE)), "Should be able to use wooden pickaxe one last time");
        (uint256 finalItemId, uint256 finalAmount) = inventorySystem.getSlotData(PLAYER, 0);
        assertEq(finalAmount, 0, "Tool should be consumed when durability reaches 0");
        assertEq(finalItemId, 0, "Slot should be empty after tool breaks");

        // Test iron pickaxe durability
        inventorySystem.mint(PLAYER, IRON_PICKAXE, 1);
        contents = inventorySystem.getInventoryContents(PLAYER);
        uint16 ironPickaxeDurability = contents[0].durability;
        assertEq(ironPickaxeDurability, MinecraftConstants.IRON_PICKAXE_DURABILITY, "Iron pickaxe should have correct initial durability");

        // Test diamond pickaxe durability
        inventorySystem.mint(PLAYER, DIAMOND_PICKAXE, 1);
        contents = inventorySystem.getInventoryContents(PLAYER);
        uint16 diamondPickaxeDurability = contents[1].durability;
        assertEq(diamondPickaxeDurability, MinecraftConstants.DIAMOND_PICKAXE_DURABILITY, "Diamond pickaxe should have correct initial durability");

        // Test shears durability
        inventorySystem.mint(PLAYER, SHEARS, 1);
        contents = inventorySystem.getInventoryContents(PLAYER);
        uint16 shearsDurability = contents[2].durability;
        assertEq(shearsDurability, MinecraftConstants.SHEARS_DURABILITY, "Shears should have correct initial durability");

        // Test that non-tool items don't have durability
        inventorySystem.mint(PLAYER, STONE, 1);
        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents[3].durability, 0, "Non-tool items should have 0 durability");

        vm.stopPrank();
    }

    function test_ToolDurabilityWithInvalidUse() public {
        vm.startPrank(PLAYER);

        // Add a wooden pickaxe
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        
        // Try to use the tool on an invalid block type (leaves)
        assertFalse(inventorySystem.useToolFromSlot(PLAYER, 0, uint8(LEAVES)), "Should not be able to use pickaxe on leaves");
        
        // Verify durability wasn't affected
        InventoryItem[] memory contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents[0].durability, MinecraftConstants.WOODEN_PICKAXE_DURABILITY, "Durability should not decrease for invalid use");

        // Try to use tool from empty slot
        assertFalse(inventorySystem.useToolFromSlot(PLAYER, 1, uint8(STONE)), "Should not be able to use tool from empty slot");

        // Add a non-tool item and try to use it
        inventorySystem.addToSlot(PLAYER, 2, STONE, 1);
        assertFalse(inventorySystem.useToolFromSlot(PLAYER, 2, uint8(STONE)), "Should not be able to use non-tool item as tool");

        vm.stopPrank();
    }

    function test_SelectedSlot() public {
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

        // Test that invalid slot reverts
        vm.expectRevert("Invalid slot number");
        inventorySystem.setSelectedSlot(36);

        vm.stopPrank();
    }

    function test_MultipleToolInstances() public {
        vm.startPrank(PLAYER);

        // Mint two wooden pickaxes
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);

        // Get the inventory contents to verify we have two pickaxes with full durability
        InventoryItem[] memory contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents.length, 2, "Should have two pickaxes");
        
        // Store the second pickaxe's ID for later comparison
        uint256 secondPickaxeId;
        uint16 initialDurability;
        for (uint i = 0; i < contents.length; i++) {
            if (contents[i].slot == 1) { // Second pickaxe should be in slot 1
                secondPickaxeId = contents[i].itemId;
                initialDurability = contents[i].durability;
                break;
            }
        }
        
        // Use first pickaxe until it breaks
        uint8 slot = 0;
        for (uint i = 0; i < initialDurability; i++) {
            assertTrue(inventorySystem.useToolFromSlot(PLAYER, slot, uint8(STONE)), "Should be able to use first pickaxe");
        }

        // Verify first pickaxe is gone
        (uint256 firstSlotItemId, uint256 firstSlotAmount) = inventorySystem.getSlotData(PLAYER, 0);
        assertEq(firstSlotItemId, 0, "First slot should be empty");
        assertEq(firstSlotAmount, 0, "First slot should have no items");

        // Verify second pickaxe still exists with full durability
        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents.length, 1, "Should have one pickaxe left");
        assertEq(contents[0].itemId, secondPickaxeId, "Second pickaxe should have same ID");
        assertEq(contents[0].durability, initialDurability, "Second pickaxe should have full durability");

        // Verify second pickaxe works
        assertTrue(inventorySystem.useToolFromSlot(PLAYER, 1, uint8(STONE)), "Should be able to use second pickaxe");
        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents[0].durability, initialDurability - 1, "Second pickaxe durability should decrease by 1");

        vm.stopPrank();
    }
} 