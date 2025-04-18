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
        vm.startPrank(address(craftingSystem));
        
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

    function test_OnlyCraftingOrOverlayCanModifyInventory() public {
        vm.startPrank(PLAYER);
        
        vm.expectRevert("Only CraftingSystem or OverlaySystem can call this");
        inventorySystem.mint(PLAYER, STONE, 1);
        
        vm.expectRevert("Only CraftingSystem or OverlaySystem can call this");
        inventorySystem.burn(PLAYER, STONE, 1);
        
        vm.expectRevert("Only CraftingSystem or OverlaySystem can call this");
        inventorySystem.addToSlot(PLAYER, 0, STONE, 1);
        
        vm.expectRevert("Only CraftingSystem or OverlaySystem can call this");
        inventorySystem.removeFromSlot(PLAYER, 0, 1);

        vm.expectRevert("Only CraftingSystem or OverlaySystem can call this");
        inventorySystem.useToolFromSlot(PLAYER, 0, uint8(STONE));
        
        vm.stopPrank();
        
        // Test that crafting system can call these functions
        vm.startPrank(address(craftingSystem));
        inventorySystem.mint(PLAYER, STONE, 1);
        inventorySystem.burn(PLAYER, STONE, 1);
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        assertTrue(inventorySystem.useToolFromSlot(PLAYER, 0, uint8(STONE)));
        vm.stopPrank();
        
        // Test that overlay system can call these functions
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, STONE, 1);
        inventorySystem.burn(PLAYER, STONE, 1);
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        assertTrue(inventorySystem.useToolFromSlot(PLAYER, 0, uint8(STONE)));
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

        vm.startPrank(address(overlaySystem));

        // Add tools and stone block
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.addToSlot(PLAYER, 1, STONE, 1);

        vm.stopPrank();

        vm.startPrank(PLAYER);

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
        vm.startPrank(address(overlaySystem));

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
        vm.startPrank(address(overlaySystem));

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
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, STONE, 5);
        vm.stopPrank();

        vm.startPrank(PLAYER);
        InventoryItem[] memory contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents.length, 1, "Should have one item type");
        assertEq(contents[0].slot, 0, "Should be in first slot");
        assertEq(contents[0].itemId, STONE, "Should be stone");
        assertEq(contents[0].amount, 5, "Should have 5 stones");
        assertEq(contents[0].name, "Stone", "Should have correct name");

        // Test minting same item type stacks in same slot if possible
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, STONE, 3);
        vm.stopPrank();

        vm.startPrank(PLAYER);
        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents.length, 1, "Should still have one item type");
        assertEq(contents[0].amount, 8, "Should have 8 stones total");

        // Test minting tool goes into new slot
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        vm.stopPrank();

        vm.startPrank(PLAYER);
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
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, STONE, 60);
        vm.stopPrank();

        vm.startPrank(PLAYER);
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
        vm.startPrank(address(overlaySystem));

        // First create some existing stacks with space
        inventorySystem.mint(PLAYER, STONE, 60); // First slot almost full
        inventorySystem.mint(PLAYER, DIRT, 1);   // Second slot with different item
        inventorySystem.mint(PLAYER, STONE, 40); // Third slot partially full

        vm.stopPrank();

        vm.startPrank(PLAYER);

        // Verify initial state
        InventoryItem[] memory initialContents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(initialContents.length, 3, "Should have three item stacks initially");

        vm.stopPrank();
        vm.startPrank(address(overlaySystem));

        // Now mint more stone - should go to the non-full existing stack first
        inventorySystem.mint(PLAYER, STONE, 10);

        vm.stopPrank();
        vm.startPrank(PLAYER);

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
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        vm.stopPrank();

        vm.startPrank(PLAYER);
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
        vm.startPrank(address(overlaySystem));

        // Setup: Add two different stacks
        inventorySystem.addToSlot(PLAYER, 0, STONE, 32);
        inventorySystem.addToSlot(PLAYER, 1, DIRT, 16);

        // Test swapping entire stacks
        vm.stopPrank();
        vm.startPrank(PLAYER);
        inventorySystem.moveItems(PLAYER, 0, 1, 32);

        // Verify the swap
        assertEq(inventorySystem.inventorySlots(PLAYER, 0), DIRT, "Slot 0 should now contain dirt");
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 16, "Dirt amount should be 16");
        assertEq(inventorySystem.inventorySlots(PLAYER, 1), STONE, "Slot 1 should now contain stone");
        assertEq(inventorySystem.slotCounts(PLAYER, 1), 32, "Stone amount should be 32");

        vm.stopPrank();
    }

    function test_SwapToolWithItems() public {
        vm.startPrank(address(overlaySystem));

        // Setup: Add a stack of stones and a pickaxe
        inventorySystem.addToSlot(PLAYER, 0, STONE, 32);
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);

        // Test swapping tool with entire stack
        vm.stopPrank();
        vm.startPrank(PLAYER);
        inventorySystem.moveItems(PLAYER, 0, 1, 32);

        // Verify the swap
        assertEq(inventorySystem.inventorySlots(PLAYER, 0) & 0xFFFF, WOODEN_PICKAXE, "Slot 0 should now contain pickaxe");
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 1, "Pickaxe amount should be 1");
        assertEq(inventorySystem.inventorySlots(PLAYER, 1), STONE, "Slot 1 should now contain stone");
        assertEq(inventorySystem.slotCounts(PLAYER, 1), 32, "Stone amount should be 32");

        vm.stopPrank();
    }

    function test_MoveToEmptySlot() public {
        vm.startPrank(address(overlaySystem));

        // Setup: Add a stack of stones
        inventorySystem.addToSlot(PLAYER, 0, STONE, 32);

        vm.stopPrank();
        vm.startPrank(PLAYER);

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
        vm.startPrank(address(overlaySystem));

        // Setup: Add a pickaxe
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);

        vm.stopPrank();
        vm.startPrank(PLAYER);

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
        vm.startPrank(address(overlaySystem));

        // Setup: Add two different stacks
        inventorySystem.addToSlot(PLAYER, 0, STONE, 32);
        inventorySystem.addToSlot(PLAYER, 1, DIRT, 16);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Try to swap partial stack (should fail)
        vm.expectRevert("Must swap entire slot contents");
        inventorySystem.moveItems(PLAYER, 0, 1, 16);


        vm.stopPrank();
    }

    function test_RevertWhen_PartialToolMove() public {
        vm.startPrank(address(overlaySystem));

        // Setup: Add a pickaxe
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Try to move tool with wrong amount (should fail)
        vm.expectRevert("Insufficient items in source slot");
        inventorySystem.moveItems(PLAYER, 0, 1, 2);

        vm.stopPrank();
    }

    function test_RevertWhen_ExceedMaxStackSize() public {
        vm.startPrank(address(overlaySystem));
        
        uint8 slot = 1;
        uint256 amount = 65; // MAX_STACK_SIZE is 64
        
        vm.expectRevert("Stack size limit exceeded");
        inventorySystem.addToSlot(PLAYER, slot, STONE, amount);
        
        vm.stopPrank();
    }

    function test_RevertWhen_ToolStacking() public {
        vm.startPrank(address(overlaySystem));

        uint8 slot = 4;
        
        // First mint a tool
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        
        // Try to add another tool to the same slot
        vm.expectRevert("Tools cannot stack");
        inventorySystem.addToSlot(PLAYER, slot, WOODEN_PICKAXE, 2);


        vm.stopPrank();
    }

    function test_ToolDurability() public {
        vm.startPrank(address(overlaySystem));

        // Test wooden pickaxe durability
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        (, uint256 amount) = inventorySystem.getSlotData(PLAYER, 0);
        assertEq(amount, 1, "Should have 1 wooden pickaxe");
        
        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Get initial durability
        InventoryItem[] memory contents = inventorySystem.getInventoryContents(PLAYER);
        uint16 initialDurability = contents[0].durability;
        assertEq(initialDurability, MinecraftConstants.WOODEN_PICKAXE_DURABILITY, "Should have full durability initially");

        vm.stopPrank();
        vm.startPrank(address(craftingSystem));

        // Use the tool multiple times
        for (uint i = 0; i < initialDurability - 1; i++) {
            assertTrue(inventorySystem.useToolFromSlot(PLAYER, 0, uint8(STONE)), "Should be able to use wooden pickaxe on stone");
            
            // Check durability decreased
            contents = inventorySystem.getInventoryContents(PLAYER);
            assertEq(contents[0].durability, initialDurability - (i + 1), "Durability should decrease by 1");
        }

        // Use the tool one last time - should break
        assertTrue(inventorySystem.useToolFromSlot(PLAYER, 0, uint8(STONE)), "Should be able to use wooden pickaxe one last time");
        
        vm.stopPrank();
        vm.startPrank(PLAYER);

        (uint256 finalItemId, uint256 finalAmount) = inventorySystem.getSlotData(PLAYER, 0);
        assertEq(finalAmount, 0, "Tool should be consumed when durability reaches 0");
        assertEq(finalItemId, 0, "Slot should be empty after tool breaks");

        // Test iron pickaxe durability
        vm.stopPrank();
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, IRON_PICKAXE, 1);
        vm.stopPrank();
        vm.startPrank(PLAYER);
        contents = inventorySystem.getInventoryContents(PLAYER);
        uint16 ironPickaxeDurability = contents[0].durability;
        assertEq(ironPickaxeDurability, MinecraftConstants.IRON_PICKAXE_DURABILITY, "Iron pickaxe should have correct initial durability");

        // Test diamond pickaxe durability
        vm.stopPrank();
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, DIAMOND_PICKAXE, 1);
        vm.stopPrank();
        vm.startPrank(PLAYER);
        contents = inventorySystem.getInventoryContents(PLAYER);
        uint16 diamondPickaxeDurability = contents[1].durability;
        assertEq(diamondPickaxeDurability, MinecraftConstants.DIAMOND_PICKAXE_DURABILITY, "Diamond pickaxe should have correct initial durability");

        // Test shears durability
        vm.stopPrank();
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, SHEARS, 1);
        vm.stopPrank();
        vm.startPrank(PLAYER);
        contents = inventorySystem.getInventoryContents(PLAYER);
        uint16 shearsDurability = contents[2].durability;
        assertEq(shearsDurability, MinecraftConstants.SHEARS_DURABILITY, "Shears should have correct initial durability");

        // Test that non-tool items don't have durability
        vm.stopPrank();
        vm.startPrank(address(overlaySystem));
        inventorySystem.mint(PLAYER, STONE, 1);
        vm.stopPrank();
        vm.startPrank(PLAYER);
        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents[3].durability, 0, "Non-tool items should have 0 durability");

        vm.stopPrank();
    }

    function test_ToolDurabilityWithInvalidUse() public {
        vm.startPrank(address(overlaySystem));

        // Add a wooden pickaxe
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
    
        
        // Try to use the tool on an invalid block type (leaves)
        assertFalse(inventorySystem.useToolFromSlot(PLAYER, 0, uint8(LEAVES)), "Should not be able to use pickaxe on leaves");
        
        vm.stopPrank();
        vm.startPrank(PLAYER);
        
        // Verify durability wasn't affected
        InventoryItem[] memory contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents[0].durability, MinecraftConstants.WOODEN_PICKAXE_DURABILITY, "Durability should not decrease for invalid use");

        vm.stopPrank();
        vm.startPrank(address(craftingSystem));

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
        vm.startPrank(address(overlaySystem));

        // Mint two wooden pickaxes
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);
        inventorySystem.mint(PLAYER, WOODEN_PICKAXE, 1);

        vm.stopPrank();
        vm.startPrank(PLAYER);

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

        vm.stopPrank();
        vm.startPrank(address(overlaySystem));

        // Use first pickaxe until it breaks
        uint8 slot = 0;
        for (uint i = 0; i < initialDurability; i++) {
            assertTrue(inventorySystem.useToolFromSlot(PLAYER, slot, uint8(STONE)), "Should be able to use first pickaxe");
        }

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Verify first pickaxe is gone
        (uint256 firstSlotItemId, uint256 firstSlotAmount) = inventorySystem.getSlotData(PLAYER, 0);
        assertEq(firstSlotItemId, 0, "First slot should be empty");
        assertEq(firstSlotAmount, 0, "First slot should have no items");

        // Verify second pickaxe still exists with full durability
        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents.length, 1, "Should have one pickaxe left");
        assertEq(contents[0].itemId, secondPickaxeId, "Second pickaxe should have same ID");
        assertEq(contents[0].durability, initialDurability, "Second pickaxe should have full durability");

        vm.stopPrank();
        vm.startPrank(address(overlaySystem));

        // Verify second pickaxe works
        assertTrue(inventorySystem.useToolFromSlot(PLAYER, 1, uint8(STONE)), "Should be able to use second pickaxe");

        vm.stopPrank();
        vm.startPrank(PLAYER);

        contents = inventorySystem.getInventoryContents(PLAYER);
        assertEq(contents[0].durability, initialDurability - 1, "Second pickaxe durability should decrease by 1");

        vm.stopPrank();
    }

    function test_StackSplitting() public {
        vm.startPrank(address(overlaySystem));

        // Test 1: Split stack into empty slot
        // Create a stack of 40 stones
        inventorySystem.addToSlot(PLAYER, 0, STONE, 40);

        vm.stopPrank();
        vm.startPrank(PLAYER);
        
        // Split half (20) into empty slot
        inventorySystem.moveItems(PLAYER, 0, 1, 20);
        
        // Verify split was successful
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 20, "Original slot should have 20 stones");
        assertEq(inventorySystem.slotCounts(PLAYER, 1), 20, "New slot should have 20 stones");
        assertEq(inventorySystem.inventorySlots(PLAYER, 1), STONE, "New slot should contain stone");

        vm.stopPrank();
        vm.startPrank(address(overlaySystem));

        // Test 2: Split stack into partially filled slot
        // Add 30 stones to slot 2
        inventorySystem.addToSlot(PLAYER, 2, STONE, 30);

        vm.stopPrank();
        vm.startPrank(PLAYER);
        
        // Try to move 20 stones from slot 0 to slot 2 (should work as 30 + 20 < 63)
        inventorySystem.moveItems(PLAYER, 0, 2, 20);
        
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 0, "Original slot should be empty");
        assertEq(inventorySystem.slotCounts(PLAYER, 2), 50, "Target slot should have 50 stones");

        vm.stopPrank();
        vm.startPrank(address(overlaySystem));

        // Test 3: Split stack respecting max stack size
        // Create a stack of 40 stones in slot 3
        inventorySystem.addToSlot(PLAYER, 3, STONE, 40);

        vm.stopPrank();
        vm.startPrank(PLAYER);
        
        // Try to move 40 stones to slot 2 which already has 50 (should fail due to max stack size)
        vm.expectRevert("Stack size limit exceeded");
        inventorySystem.moveItems(PLAYER, 3, 2, 40);
        
        // Move only what fits (13 stones to reach max of 63)
        inventorySystem.moveItems(PLAYER, 3, 2, 13);
        
        assertEq(inventorySystem.slotCounts(PLAYER, 2), 63, "Target slot should be at max capacity");
        assertEq(inventorySystem.slotCounts(PLAYER, 3), 27, "Source slot should have remaining stones");

        // Test 4: Split uneven amounts
        // Move 7 stones from slot 3 to empty slot 4
        inventorySystem.moveItems(PLAYER, 3, 4, 7);
        
        assertEq(inventorySystem.slotCounts(PLAYER, 3), 20, "Source slot should have 20 stones");
        assertEq(inventorySystem.slotCounts(PLAYER, 4), 7, "Target slot should have 7 stones");

        // Test 5: Split entire stack
        // Move all 20 stones from slot 3 to slot 5
        inventorySystem.moveItems(PLAYER, 3, 5, 20);
        
        assertEq(inventorySystem.slotCounts(PLAYER, 3), 0, "Source slot should be empty");
        assertEq(inventorySystem.inventorySlots(PLAYER, 3), 0, "Source slot should have no item type");
        assertEq(inventorySystem.slotCounts(PLAYER, 5), 20, "Target slot should have all stones");
        assertEq(inventorySystem.inventorySlots(PLAYER, 5), STONE, "Target slot should contain stone");

        vm.stopPrank();
    }

    function test_StackSplittingSlotPrecision() public {
        vm.startPrank(address(overlaySystem));

        // Setup: Create some empty slots between filled slots to test precision
        inventorySystem.addToSlot(PLAYER, 0, STONE, 40);  // Slot 0: 40 stones
        inventorySystem.addToSlot(PLAYER, 3, DIRT, 10);   // Slot 3: 10 dirt (to ensure empty slots in between)
        inventorySystem.addToSlot(PLAYER, 5, STONE, 20);  // Slot 5: 20 stones

        vm.stopPrank();
        vm.startPrank(PLAYER);

        // Test 1: Split stack to a specific empty slot (slot 2), ensuring it doesn't go to slot 1
        inventorySystem.moveItems(PLAYER, 0, 2, 15);
        
        // Verify slot 1 remains empty
        assertEq(inventorySystem.inventorySlots(PLAYER, 1), 0, "Slot 1 should remain empty");
        assertEq(inventorySystem.slotCounts(PLAYER, 1), 0, "Slot 1 should have no items");
        
        // Verify slot 2 got exactly what we moved
        assertEq(inventorySystem.inventorySlots(PLAYER, 2), STONE, "Slot 2 should contain stone");
        assertEq(inventorySystem.slotCounts(PLAYER, 2), 15, "Slot 2 should have 15 stones");
        
        // Verify source slot (0) was properly reduced
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 25, "Slot 0 should have 25 stones remaining");

        // Test 2: Move to slot with same item type, skipping empty slots
        inventorySystem.moveItems(PLAYER, 0, 5, 10);
        
        // Verify intermediate slots weren't affected
        assertEq(inventorySystem.inventorySlots(PLAYER, 1), 0, "Slot 1 should still be empty");
        assertEq(inventorySystem.inventorySlots(PLAYER, 4), 0, "Slot 4 should remain empty");
        
        // Verify destination got the correct amount
        assertEq(inventorySystem.slotCounts(PLAYER, 5), 30, "Slot 5 should now have 30 stones");
        
        // Verify source slot was properly reduced
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 15, "Slot 0 should have 15 stones remaining");

        // Test 3: Attempt to split stack to maximum capacity
        vm.stopPrank();
        vm.startPrank(address(overlaySystem));
        inventorySystem.addToSlot(PLAYER, 6, STONE, 60); // Nearly full stack
        vm.stopPrank();
        vm.startPrank(PLAYER);
        inventorySystem.moveItems(PLAYER, 0, 6, 3); // Add 3 more to reach 63
        
        // Verify it reached but didn't exceed max stack size
        assertEq(inventorySystem.slotCounts(PLAYER, 6), 63, "Slot 6 should be at max capacity");
        
        // Verify source slot was properly reduced
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 12, "Slot 0 should have 12 stones remaining");

        // Test 4: Verify that moving items doesn't auto-stack with other available slots
        inventorySystem.moveItems(PLAYER, 0, 7, 5);
        
        // Verify the items went to slot 7 specifically, not to other slots with the same item type
        assertEq(inventorySystem.slotCounts(PLAYER, 7), 5, "Slot 7 should have exactly 5 stones");
        assertEq(inventorySystem.slotCounts(PLAYER, 6), 63, "Slot 6 should still be at 63 (max capacity)");
        assertEq(inventorySystem.slotCounts(PLAYER, 5), 30, "Slot 5 should still have 30 stones");
        
        // Verify source slot has remaining items
        assertEq(inventorySystem.slotCounts(PLAYER, 0), 7, "Slot 0 should have 7 stones remaining");

        vm.stopPrank();
    }
} 