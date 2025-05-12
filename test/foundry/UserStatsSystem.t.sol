// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TestHelper.sol";
import "../../contracts/systems/UserStatsSystem.sol";

contract UserStatsSystemTest is TestHelper {
    address constant PLAYER2 = address(0x3);
    address constant FAKE_OVERLAY = address(0x4);
    address constant FAKE_CRAFTING = address(0x6);
    address constant FAKE_INVENTORY = address(0x7);
    address constant FAKE_PLAYER = address(0x8);

    function setUp() public override {
        super.setUp();
        
        vm.startPrank(OWNER);
        userStatsSystem = new UserStatsSystem(
            address(sessionManager),
            FAKE_OVERLAY,
            FAKE_CRAFTING,
            FAKE_INVENTORY,
            FAKE_PLAYER
        );
        vm.stopPrank();
    }

    function testRecordBlockMined() public {
        vm.startPrank(FAKE_OVERLAY);
        
        // Record some mining stats
        userStatsSystem.recordBlockMined(PLAYER, uint8(STONE));
        userStatsSystem.recordBlockMined(PLAYER, uint8(STONE));
        userStatsSystem.recordBlockMined(PLAYER, uint8(IRON_ORE));
        
        // Get user stats
        (
            address userAddress,
            uint256 totalMined,
            ,  // totalPlaced
            ,  // totalDistance
            ,  // totalCrafted
            ,  // totalPlayerUpdates
            IUserStatsSystem.BlockTypeCount[] memory minedBlocks,
            ,  // placedBlocks
            ,  // craftedItems
            uint256[] memory minedBlockTypes,
            uint256[] memory minedCounts,
            ,  // placedBlockTypes
            ,  // placedCounts
            ,  // craftedItemTypes
            // craftedCounts
        ) = userStatsSystem.getUserStats(PLAYER);
        
        // Verify stats
        assertEq(userAddress, PLAYER);
        assertEq(totalMined, 3);
        assertEq(minedBlocks.length, 2);
        assertEq(minedBlockTypes.length, 2);
        assertEq(minedCounts.length, 2);
        
        // Find STONE and IRON_ORE stats
        bool foundStone = false;
        bool foundIron = false;
        for (uint256 i = 0; i < minedBlocks.length; i++) {
            if (minedBlocks[i].blockType == uint8(STONE)) {
                foundStone = true;
                assertEq(minedBlocks[i].count, 2);
                assertEq(minedCounts[i], 2);
            }
            if (minedBlocks[i].blockType == uint8(IRON_ORE)) {
                foundIron = true;
                assertEq(minedBlocks[i].count, 1);
                assertEq(minedCounts[i], 1);
            }
        }
        
        assertTrue(foundStone, "STONE not found");
        assertTrue(foundIron, "IRON_ORE not found");
        
        vm.stopPrank();
    }

    function testRecordBlockPlaced() public {
        vm.startPrank(FAKE_OVERLAY);
        
        // Record some placement stats
        userStatsSystem.recordBlockPlaced(PLAYER, uint8(WOOD));
        userStatsSystem.recordBlockPlaced(PLAYER, uint8(WOOD));
        userStatsSystem.recordBlockPlaced(PLAYER, uint8(STONE));
        
        // Get user stats
        (
            address userAddress,
            ,  // totalMined
            uint256 totalPlaced,
            ,  // totalDistance
            ,  // totalCrafted
            ,  // totalPlayerUpdates
            ,  // minedBlocks
            IUserStatsSystem.BlockTypeCount[] memory placedBlocks,
            ,  // craftedItems
            ,  // minedBlockTypes
            ,  // minedCounts
            uint256[] memory placedBlockTypes,
            uint256[] memory placedCounts,
            ,  // craftedItemTypes
            // craftedCounts
        ) = userStatsSystem.getUserStats(PLAYER);
        
        // Verify stats
        assertEq(userAddress, PLAYER);
        assertEq(totalPlaced, 3);
        assertEq(placedBlocks.length, 2);
        assertEq(placedBlockTypes.length, 2);
        assertEq(placedCounts.length, 2);
        
        // Find WOOD and STONE stats
        bool foundWood = false;
        bool foundStone = false;
        for (uint256 i = 0; i < placedBlocks.length; i++) {
            if (placedBlocks[i].blockType == uint8(WOOD)) {
                foundWood = true;
                assertEq(placedBlocks[i].count, 2);
                assertEq(placedCounts[i], 2);
            }
            if (placedBlocks[i].blockType == uint8(STONE)) {
                foundStone = true;
                assertEq(placedBlocks[i].count, 1);
                assertEq(placedCounts[i], 1);
            }
        }
        
        assertTrue(foundWood, "WOOD not found");
        assertTrue(foundStone, "STONE not found");
        
        vm.stopPrank();
    }

    function testRecordDistanceMoved() public {
        vm.startPrank(FAKE_PLAYER);
        
        // Record some movement
        userStatsSystem.recordDistanceMoved(PLAYER, 100);
        userStatsSystem.recordDistanceMoved(PLAYER, 50);
        
        // Get user stats
        (
            address userAddress,
            ,  // totalMined
            ,  // totalPlaced
            uint256 totalDistance,
            ,  // totalCrafted
            ,  // totalPlayerUpdates
            ,  // minedBlocks
            ,  // placedBlocks
            ,  // craftedItems
            ,  // minedBlockTypes
            ,  // minedCounts
            ,  // placedBlockTypes
            ,  // placedCounts
            ,  // craftedItemTypes
            // craftedCounts
        ) = userStatsSystem.getUserStats(PLAYER);
        
        // Verify stats
        assertEq(userAddress, PLAYER);
        assertEq(totalDistance, 150);
        
        vm.stopPrank();
    }

    function testRecordItemCrafted() public {
        vm.startPrank(FAKE_CRAFTING);
        
        // Record some crafting stats
        userStatsSystem.recordItemCrafted(PLAYER, WOODEN_PICKAXE, 1);
        userStatsSystem.recordItemCrafted(PLAYER, STONE_PICKAXE, 1);
        userStatsSystem.recordItemCrafted(PLAYER, WOODEN_PICKAXE, 1);
        
        // Get user stats
        (
            address userAddress,
            ,  // totalMined
            ,  // totalPlaced
            ,  // totalDistance
            uint256 totalCrafted,
            ,  // totalPlayerUpdates
            ,  // minedBlocks
            ,  // placedBlocks
            IUserStatsSystem.ItemTypeCount[] memory craftedItems,
            ,  // minedBlockTypes
            ,  // minedCounts
            ,  // placedBlockTypes
            ,  // placedCounts
            uint256[] memory craftedItemTypes,
            uint256[] memory craftedCounts
        ) = userStatsSystem.getUserStats(PLAYER);
        
        // Verify stats
        assertEq(userAddress, PLAYER);
        assertEq(totalCrafted, 3);
        assertEq(craftedItems.length, 2);
        assertEq(craftedItemTypes.length, 2);
        assertEq(craftedCounts.length, 2);
        
        // Find WOODEN_PICKAXE and STONE_PICKAXE stats
        bool foundWoodenPick = false;
        bool foundStonePick = false;
        for (uint256 i = 0; i < craftedItems.length; i++) {
            if (craftedItems[i].itemType == WOODEN_PICKAXE) {
                foundWoodenPick = true;
                assertEq(craftedItems[i].count, 2);
                assertEq(craftedCounts[i], 2);
            }
            if (craftedItems[i].itemType == STONE_PICKAXE) {
                foundStonePick = true;
                assertEq(craftedItems[i].count, 1);
                assertEq(craftedCounts[i], 1);
            }
        }
        
        assertTrue(foundWoodenPick, "WOODEN_PICKAXE not found");
        assertTrue(foundStonePick, "STONE_PICKAXE not found");
        
        vm.stopPrank();
    }

    function testGetAllUsers() public {
        vm.startPrank(FAKE_OVERLAY);
        
        // Add some users through mining
        userStatsSystem.recordBlockMined(PLAYER, uint8(STONE));
        userStatsSystem.recordBlockMined(PLAYER2, uint8(STONE));
        
        // Test pagination of addresses
        address[] memory users = userStatsSystem.getAllUsers(0, 1);
        assertEq(users.length, 1);
        assertEq(users[0], PLAYER);
        
        users = userStatsSystem.getAllUsers(1, 1);
        assertEq(users.length, 1);
        assertEq(users[0], PLAYER2);
        
        users = userStatsSystem.getAllUsers(0, 2);
        assertEq(users.length, 2);
        assertEq(users[0], PLAYER);
        assertEq(users[1], PLAYER2);
        
        // Test pagination of stats
        (
            address[] memory userAddresses,
            uint256[] memory totalMined,
            ,  // totalPlaced
            ,  // totalDistance
            ,  // totalCrafted
            ,  // totalPlayerUpdates
            IUserStatsSystem.BlockTypeCount[][] memory minedBlocks,
            ,  // placedBlocks
            ,  // craftedItems
            ,  // minedBlockTypes
            ,  // minedCounts
            ,  // placedBlockTypes
            ,  // placedCounts
            ,  // craftedItemTypes
            // craftedCounts
        ) = userStatsSystem.getAllUserStats(0, 2);
        
        assertEq(userAddresses.length, 2);
        assertEq(userAddresses[0], PLAYER);
        assertEq(userAddresses[1], PLAYER2);
        assertEq(totalMined[0], 1);
        assertEq(totalMined[1], 1);
        assertEq(minedBlocks[0].length, 1);
        assertEq(minedBlocks[1].length, 1);
        assertEq(minedBlocks[0][0].blockType, uint8(STONE));
        assertEq(minedBlocks[1][0].blockType, uint8(STONE));
        assertEq(minedBlocks[0][0].count, 1);
        assertEq(minedBlocks[1][0].count, 1);
        
        // Test offset beyond length
        users = userStatsSystem.getAllUsers(2, 1);
        assertEq(users.length, 0);
        
        (
            userAddresses,
            ,  // totalMined
            ,  // totalPlaced
            ,  // totalDistance
            ,  // totalCrafted
            ,  // totalPlayerUpdates
            ,  // minedBlocks
            ,  // placedBlocks
            ,  // craftedItems
            ,  // minedBlockTypes
            ,  // minedCounts
            ,  // placedBlockTypes
            ,  // placedCounts
            ,  // craftedItemTypes
            // craftedCounts
        ) = userStatsSystem.getAllUserStats(2, 1);
        assertEq(userAddresses.length, 0);
        
        vm.stopPrank();
    }

    function testOnlyOverlaySystemCanRecordBlocks() public {
        vm.startPrank(PLAYER);
        
        vm.expectRevert("Only OverlaySystem can call this");
        userStatsSystem.recordBlockMined(PLAYER, uint8(STONE));
        
        vm.expectRevert("Only OverlaySystem can call this");
        userStatsSystem.recordBlockPlaced(PLAYER, uint8(STONE));
        
        vm.stopPrank();
    }

    function testOnlyMovementSystemCanRecordDistance() public {
        vm.startPrank(PLAYER);
        
        vm.expectRevert("Only PlayerSystem can call this");
        userStatsSystem.recordDistanceMoved(PLAYER, 100);
        
        vm.stopPrank();
    }

    function testOnlyCraftingSystemCanRecordCrafting() public {
        vm.startPrank(PLAYER);
        
        vm.expectRevert("Only CraftingSystem can call this");
        userStatsSystem.recordItemCrafted(PLAYER, WOODEN_PICKAXE, 1);
        
        vm.stopPrank();
    }

    function testInventoryTracking() public {
        vm.startPrank(FAKE_INVENTORY);
        
        // Test minting tracking
        userStatsSystem.recordItemMinted(PLAYER, STONE, 5);
        userStatsSystem.recordItemMinted(PLAYER, STONE, 3);
        userStatsSystem.recordItemMinted(PLAYER, DIRT, 2);
        
        // Test burning tracking
        userStatsSystem.recordItemBurned(PLAYER, STONE, 2);
        userStatsSystem.recordItemBurned(PLAYER, DIRT, 1);
        
        // Test moving tracking
        userStatsSystem.recordItemMoved(PLAYER, 0, 1, STONE, 3);
        userStatsSystem.recordItemMoved(PLAYER, 1, 2, STONE, 2);
        
        // Get user inventory stats and verify
        (
            uint256 totalMinted,
            uint256 totalBurned,
            uint256 totalMoved,
            uint256 totalSwapped,
            uint256 totalTransferredOut,
            uint256 totalTransferredIn,
            IUserStatsSystem.ItemTypeCount[] memory mintedItems,
            IUserStatsSystem.ItemTypeCount[] memory burnedItems,
            uint256[] memory mintedItemTypes,
            uint256[] memory mintedCounts,
            uint256[] memory burnedItemTypes,
            uint256[] memory burnedCounts
        ) = userStatsSystem.getUserInventoryStats(PLAYER);
        
        assertEq(totalMinted, 10, "Total minted should be 10");
        assertEq(totalBurned, 3, "Total burned should be 3");
        assertEq(totalMoved, 5, "Total moved should be 5");
        assertEq(totalSwapped, 0, "Total swapped should be 0");
        assertEq(totalTransferredOut, 0, "Total transferred out should be 0");
        assertEq(totalTransferredIn, 0, "Total transferred in should be 0");
        
        // Verify minted items
        assertEq(mintedItems.length, 2, "Should have 2 types of items minted");
        assertEq(mintedItemTypes.length, 2, "Should have 2 types in mintedItemTypes");
        assertEq(mintedCounts.length, 2, "Should have 2 counts in mintedCounts");
        
        // Find STONE and DIRT stats in minted items
        bool foundStone = false;
        bool foundDirt = false;
        for (uint256 i = 0; i < mintedItems.length; i++) {
            if (mintedItems[i].itemType == STONE) {
                foundStone = true;
                assertEq(mintedItems[i].count, 8, "STONE minted count should be 8");
                assertEq(mintedCounts[i], 8, "STONE minted count in array should be 8");
            }
            if (mintedItems[i].itemType == DIRT) {
                foundDirt = true;
                assertEq(mintedItems[i].count, 2, "DIRT minted count should be 2");
                assertEq(mintedCounts[i], 2, "DIRT minted count in array should be 2");
            }
        }
        
        assertTrue(foundStone, "STONE not found in minted items");
        assertTrue(foundDirt, "DIRT not found in minted items");
        
        // Verify burned items
        assertEq(burnedItems.length, 2, "Should have 2 types of items burned");
        assertEq(burnedItemTypes.length, 2, "Should have 2 types in burnedItemTypes");
        assertEq(burnedCounts.length, 2, "Should have 2 counts in burnedCounts");
        
        // Find STONE and DIRT stats in burned items
        foundStone = false;
        foundDirt = false;
        for (uint256 i = 0; i < burnedItems.length; i++) {
            if (burnedItems[i].itemType == STONE) {
                foundStone = true;
                assertEq(burnedItems[i].count, 2, "STONE burned count should be 2");
                assertEq(burnedCounts[i], 2, "STONE burned count in array should be 2");
            }
            if (burnedItems[i].itemType == DIRT) {
                foundDirt = true;
                assertEq(burnedItems[i].count, 1, "DIRT burned count should be 1");
                assertEq(burnedCounts[i], 1, "DIRT burned count in array should be 1");
            }
        }
        
        assertTrue(foundStone, "STONE not found in burned items");
        assertTrue(foundDirt, "DIRT not found in burned items");
        
        vm.stopPrank();
    }

    function testOnlyInventorySystemCanRecordInventoryActions() public {
        vm.startPrank(PLAYER);
        
        vm.expectRevert("Only InventorySystem can call this");
        userStatsSystem.recordItemMinted(PLAYER, STONE, 1);
        
        vm.expectRevert("Only InventorySystem can call this");
        userStatsSystem.recordItemBurned(PLAYER, STONE, 1);
        
        vm.expectRevert("Only InventorySystem can call this");
        userStatsSystem.recordItemMoved(PLAYER, 0, 1, STONE, 1);
        
        uint256[] memory inputTypes = new uint256[](1);
        uint256[] memory inputAmounts = new uint256[](1);
        inputTypes[0] = IRON_ORE;
        inputAmounts[0] = 1;
        
        vm.expectRevert("Only InventorySystem can call this");
        userStatsSystem.recordItemSwapped(PLAYER, inputTypes, inputAmounts, IRON_INGOT, 1);
        
        vm.expectRevert("Only InventorySystem can call this");
        userStatsSystem.recordItemTransferred(PLAYER, PLAYER2, STONE, 1);
        
        vm.stopPrank();
    }

    function testGetAllUserInventoryStats() public {
        vm.startPrank(FAKE_INVENTORY);
        
        // Add some inventory stats
        userStatsSystem.recordItemMinted(PLAYER, STONE, 5);
        userStatsSystem.recordItemMinted(PLAYER2, IRON_ORE, 3);
        userStatsSystem.recordItemBurned(PLAYER, STONE, 2);
        userStatsSystem.recordItemBurned(PLAYER2, IRON_ORE, 1);
        userStatsSystem.recordItemMoved(PLAYER, 0, 1, STONE, 3);
        userStatsSystem.recordItemMoved(PLAYER2, 0, 1, IRON_ORE, 2);
        
        vm.stopPrank();
        
        // Test pagination of inventory stats
        (
            uint256[] memory totalMinted,
            uint256[] memory totalBurned,
            uint256[] memory totalMoved,
            uint256[] memory totalSwapped,
            uint256[] memory totalTransferredOut,
            uint256[] memory totalTransferredIn,
            IUserStatsSystem.ItemTypeCount[][] memory mintedItems,
            IUserStatsSystem.ItemTypeCount[][] memory burnedItems,
            uint256[][] memory mintedItemTypes,
            uint256[][] memory mintedCounts,
            uint256[][] memory burnedItemTypes,
            uint256[][] memory burnedCounts
        ) = userStatsSystem.getAllUserInventoryStats(0, 2);
        
        assertEq(totalMinted.length, 2, "Should have 2 users' minted totals");
        assertEq(totalBurned.length, 2, "Should have 2 users' burned totals");
        assertEq(totalMoved.length, 2, "Should have 2 users' moved totals");
        assertEq(totalSwapped.length, 2, "Should have 2 users' swapped totals");
        assertEq(totalTransferredOut.length, 2, "Should have 2 users' transferred out totals");
        assertEq(totalTransferredIn.length, 2, "Should have 2 users' transferred in totals");
        assertEq(mintedItems.length, 2, "Should have 2 users' minted items");
        assertEq(burnedItems.length, 2, "Should have 2 users' burned items");
        
        // Check PLAYER stats
        assertEq(totalMinted[0], 5, "PLAYER total minted should be 5");
        assertEq(totalBurned[0], 2, "PLAYER total burned should be 2");
        assertEq(totalMoved[0], 3, "PLAYER total moved should be 3");
        assertEq(totalSwapped[0], 0, "PLAYER total swapped should be 0");
        assertEq(totalTransferredOut[0], 0, "PLAYER total transferred out should be 0");
        assertEq(totalTransferredIn[0], 0, "PLAYER total transferred in should be 0");
        assertEq(mintedItems[0].length, 1, "PLAYER should have 1 type of minted item");
        assertEq(mintedItems[0][0].itemType, STONE, "PLAYER minted item should be STONE");
        assertEq(mintedItems[0][0].count, 5, "PLAYER minted STONE count should be 5");
        assertEq(burnedItems[0].length, 1, "PLAYER should have 1 type of burned item");
        assertEq(burnedItems[0][0].itemType, STONE, "PLAYER burned item should be STONE");
        assertEq(burnedItems[0][0].count, 2, "PLAYER burned STONE count should be 2");
        
        // Check PLAYER2 stats
        assertEq(totalMinted[1], 3, "PLAYER2 total minted should be 3");
        assertEq(totalBurned[1], 1, "PLAYER2 total burned should be 1");
        assertEq(totalMoved[1], 2, "PLAYER2 total moved should be 2");
        assertEq(totalSwapped[1], 0, "PLAYER2 total swapped should be 0");
        assertEq(totalTransferredOut[1], 0, "PLAYER2 total transferred out should be 0");
        assertEq(totalTransferredIn[1], 0, "PLAYER2 total transferred in should be 0");
        assertEq(mintedItems[1].length, 1, "PLAYER2 should have 1 type of minted item");
        assertEq(mintedItems[1][0].itemType, IRON_ORE, "PLAYER2 minted item should be IRON_ORE");
        assertEq(mintedItems[1][0].count, 3, "PLAYER2 minted IRON_ORE count should be 3");
        assertEq(burnedItems[1].length, 1, "PLAYER2 should have 1 type of burned item");
        assertEq(burnedItems[1][0].itemType, IRON_ORE, "PLAYER2 burned item should be IRON_ORE");
        assertEq(burnedItems[1][0].count, 1, "PLAYER2 burned IRON_ORE count should be 1");
        
        // Test pagination with offset
        (
            totalMinted,
            totalBurned,
            totalMoved,
            totalSwapped,
            totalTransferredOut,
            totalTransferredIn,
            mintedItems,
            burnedItems,
            mintedItemTypes,
            mintedCounts,
            burnedItemTypes,
            burnedCounts
        ) = userStatsSystem.getAllUserInventoryStats(1, 1);
        
        assertEq(totalMinted.length, 1, "Should have 1 user's minted totals");
        assertEq(totalMinted[0], 3, "PLAYER2 total minted should be 3");
        assertEq(totalBurned[0], 1, "PLAYER2 total burned should be 1");
        assertEq(totalMoved[0], 2, "PLAYER2 total moved should be 2");
        assertEq(totalSwapped[0], 0, "PLAYER2 total swapped should be 0");
        assertEq(totalTransferredOut[0], 0, "PLAYER2 total transferred out should be 0");
        assertEq(totalTransferredIn[0], 0, "PLAYER2 total transferred in should be 0");
        
        // Test offset beyond length
        (
            totalMinted,
            totalBurned,
            totalMoved,
            totalSwapped,
            totalTransferredOut,
            totalTransferredIn,
            mintedItems,
            burnedItems,
            mintedItemTypes,
            mintedCounts,
            burnedItemTypes,
            burnedCounts
        ) = userStatsSystem.getAllUserInventoryStats(2, 1);
        
        assertEq(totalMinted.length, 0, "Should have 0 users' minted totals");
    }

    function testGlobalStats() public {
        vm.startPrank(FAKE_OVERLAY);
        
        // Record some mining stats for multiple users
        userStatsSystem.recordBlockMined(PLAYER, uint8(STONE));
        userStatsSystem.recordBlockMined(PLAYER, uint8(STONE));
        userStatsSystem.recordBlockMined(PLAYER2, uint8(IRON_ORE));
        
        vm.stopPrank();
        
        vm.startPrank(FAKE_PLAYER);
        // Record some movement stats
        userStatsSystem.recordDistanceMoved(PLAYER, 100);
        userStatsSystem.recordDistanceMoved(PLAYER2, 50);
        vm.stopPrank();
        
        vm.startPrank(FAKE_CRAFTING);
        // Record some crafting stats
        userStatsSystem.recordItemCrafted(PLAYER, WOODEN_PICKAXE, 1);
        userStatsSystem.recordItemCrafted(PLAYER2, STONE_PICKAXE, 1);
        vm.stopPrank();
        
        // Get global stats
        (
            uint256 totalMined,
            uint256 totalPlaced,
            uint256 totalDistance,
            uint256 totalCrafted,
            uint256 totalPlayerUpdates,
            IUserStatsSystem.BlockTypeCount[] memory minedBlocks,
            ,  // placedBlocks
            IUserStatsSystem.ItemTypeCount[] memory craftedItems,
            uint256[] memory minedBlockTypes,
            uint256[] memory minedCounts,
            ,  // placedBlockTypes
            ,  // placedCounts
            uint256[] memory craftedItemTypes,
            uint256[] memory craftedCounts
        ) = userStatsSystem.getGlobalStats();
        
        // Verify global totals
        assertEq(totalMined, 3, "Global total mined should be 3");
        assertEq(totalPlaced, 0, "Global total placed should be 0");
        assertEq(totalDistance, 150, "Global total distance should be 150");
        assertEq(totalCrafted, 2, "Global total crafted should be 2");
        assertEq(totalPlayerUpdates, 0, "Global total player updates should be 0");
        
        // Verify mined blocks
        assertEq(minedBlocks.length, 2, "Should have 2 types of blocks mined globally");
        assertEq(minedBlockTypes.length, 2, "Should have 2 types in minedBlockTypes");
        assertEq(minedCounts.length, 2, "Should have 2 counts in minedCounts");
        
        // Find STONE and IRON_ORE stats in global stats
        bool foundStone = false;
        bool foundIron = false;
        for (uint256 i = 0; i < minedBlocks.length; i++) {
            if (minedBlocks[i].blockType == uint8(STONE)) {
                foundStone = true;
                assertEq(minedBlocks[i].count, 2, "Global STONE count should be 2");
                assertEq(minedCounts[i], 2, "Global STONE count in array should be 2");
            }
            if (minedBlocks[i].blockType == uint8(IRON_ORE)) {
                foundIron = true;
                assertEq(minedBlocks[i].count, 1, "Global IRON_ORE count should be 1");
                assertEq(minedCounts[i], 1, "Global IRON_ORE count in array should be 1");
            }
        }
        
        assertTrue(foundStone, "STONE not found in global stats");
        assertTrue(foundIron, "IRON_ORE not found in global stats");
        
        // Verify crafted items
        assertEq(craftedItems.length, 2, "Should have 2 types of items crafted globally");
        assertEq(craftedItemTypes.length, 2, "Should have 2 types in craftedItemTypes");
        assertEq(craftedCounts.length, 2, "Should have 2 counts in craftedCounts");
        
        // Find WOODEN_PICKAXE and STONE_PICKAXE stats in global stats
        bool foundWoodenPick = false;
        bool foundStonePick = false;
        for (uint256 i = 0; i < craftedItems.length; i++) {
            if (craftedItems[i].itemType == WOODEN_PICKAXE) {
                foundWoodenPick = true;
                assertEq(craftedItems[i].count, 1, "Global WOODEN_PICKAXE count should be 1");
                assertEq(craftedCounts[i], 1, "Global WOODEN_PICKAXE count in array should be 1");
            }
            if (craftedItems[i].itemType == STONE_PICKAXE) {
                foundStonePick = true;
                assertEq(craftedItems[i].count, 1, "Global STONE_PICKAXE count should be 1");
                assertEq(craftedCounts[i], 1, "Global STONE_PICKAXE count in array should be 1");
            }
        }
        
        assertTrue(foundWoodenPick, "WOODEN_PICKAXE not found in global stats");
        assertTrue(foundStonePick, "STONE_PICKAXE not found in global stats");
    }

    function testGlobalInventoryStats() public {
        vm.startPrank(FAKE_INVENTORY);
        
        // Record minting stats for multiple users
        userStatsSystem.recordItemMinted(PLAYER, STONE, 5);
        userStatsSystem.recordItemMinted(PLAYER, DIRT, 2);
        userStatsSystem.recordItemMinted(PLAYER2, STONE, 3);
        userStatsSystem.recordItemMinted(PLAYER2, IRON_ORE, 1);
        
        // Record burning stats
        userStatsSystem.recordItemBurned(PLAYER, STONE, 2);
        userStatsSystem.recordItemBurned(PLAYER2, STONE, 1);
        
        // Record moving stats
        userStatsSystem.recordItemMoved(PLAYER, 0, 1, STONE, 3);
        userStatsSystem.recordItemMoved(PLAYER2, 1, 2, STONE, 2);
        
        vm.stopPrank();
        
        // Get global inventory stats
        (
            uint256 totalMinted,
            uint256 totalBurned,
            uint256 totalMoved,
            uint256 totalSwapped,
            uint256 totalTransferredOut,
            uint256 totalTransferredIn,
            IUserStatsSystem.ItemTypeCount[] memory mintedItems,
            IUserStatsSystem.ItemTypeCount[] memory burnedItems,
            uint256[] memory mintedItemTypes,
            uint256[] memory mintedCounts,
            uint256[] memory burnedItemTypes,
            uint256[] memory burnedCounts
        ) = userStatsSystem.getGlobalInventoryStats();
        
        // Verify global totals
        assertEq(totalMinted, 11, "Global total minted should be 11");
        assertEq(totalBurned, 3, "Global total burned should be 3");
        assertEq(totalMoved, 5, "Global total moved should be 5");
        assertEq(totalSwapped, 0, "Global total swapped should be 0");
        assertEq(totalTransferredOut, 0, "Global total transferred out should be 0");
        assertEq(totalTransferredIn, 0, "Global total transferred in should be 0");
        
        // Verify minted items
        assertEq(mintedItems.length, 3, "Should have 3 types of items minted globally");
        assertEq(mintedItemTypes.length, 3, "Should have 3 types in mintedItemTypes");
        assertEq(mintedCounts.length, 3, "Should have 3 counts in mintedCounts");
        
        // Find STONE, DIRT, and IRON_ORE stats in minted items
        bool foundStone = false;
        bool foundDirt = false;
        bool foundIron = false;
        for (uint256 i = 0; i < mintedItems.length; i++) {
            if (mintedItems[i].itemType == STONE) {
                foundStone = true;
                assertEq(mintedItems[i].count, 8, "Global STONE minted count should be 8");
                assertEq(mintedCounts[i], 8, "Global STONE minted count in array should be 8");
            }
            if (mintedItems[i].itemType == DIRT) {
                foundDirt = true;
                assertEq(mintedItems[i].count, 2, "Global DIRT minted count should be 2");
                assertEq(mintedCounts[i], 2, "Global DIRT minted count in array should be 2");
            }
            if (mintedItems[i].itemType == IRON_ORE) {
                foundIron = true;
                assertEq(mintedItems[i].count, 1, "Global IRON_ORE minted count should be 1");
                assertEq(mintedCounts[i], 1, "Global IRON_ORE minted count in array should be 1");
            }
        }
        
        assertTrue(foundStone, "STONE not found in global minted items");
        assertTrue(foundDirt, "DIRT not found in global minted items");
        assertTrue(foundIron, "IRON_ORE not found in global minted items");
        
        // Verify burned items
        assertEq(burnedItems.length, 1, "Should have 1 type of item burned globally");
        assertEq(burnedItemTypes.length, 1, "Should have 1 type in burnedItemTypes");
        assertEq(burnedCounts.length, 1, "Should have 1 count in burnedCounts");
        
        // Verify STONE burned stats
        assertEq(burnedItems[0].itemType, STONE, "Should be STONE in burned items");
        assertEq(burnedItems[0].count, 3, "Global STONE burned count should be 3");
        assertEq(burnedCounts[0], 3, "Global STONE burned count in array should be 3");
    }

    function testRecordPlayerUpdate() public {
        vm.startPrank(FAKE_PLAYER);
        
        // Record some updates
        userStatsSystem.recordPlayerUpdate(PLAYER);
        userStatsSystem.recordPlayerUpdate(PLAYER);
        userStatsSystem.recordPlayerUpdate(PLAYER2);
        
        // Get user stats for PLAYER
        (
            address userAddress,
            ,  // totalMined
            ,  // totalPlaced
            ,  // totalDistance
            ,  // totalCrafted
            uint256 totalPlayerUpdates,
            ,  // minedBlocks
            ,  // placedBlocks
            ,  // craftedItems
            ,  // minedBlockTypes
            ,  // minedCounts
            ,  // placedBlockTypes
            ,  // placedCounts
            ,  // craftedItemTypes
            // craftedCounts
        ) = userStatsSystem.getUserStats(PLAYER);
        
        // Verify stats for PLAYER
        assertEq(userAddress, PLAYER);
        assertEq(totalPlayerUpdates, 2);
        
        // Get user stats for PLAYER2
        (
            userAddress,
            ,  // totalMined
            ,  // totalPlaced
            ,  // totalDistance
            ,  // totalCrafted
            totalPlayerUpdates,
            ,  // minedBlocks
            ,  // placedBlocks
            ,  // craftedItems
            ,  // minedBlockTypes
            ,  // minedCounts
            ,  // placedBlockTypes
            ,  // placedCounts
            ,  // craftedItemTypes
            // craftedCounts
        ) = userStatsSystem.getUserStats(PLAYER2);
        
        // Verify stats for PLAYER2
        assertEq(userAddress, PLAYER2);
        assertEq(totalPlayerUpdates, 1);
        
        // Get global stats
        (
            ,  // totalMined
            ,  // totalPlaced
            ,  // totalDistance
            ,  // totalCrafted
            totalPlayerUpdates,
            ,  // minedBlocks
            ,  // placedBlocks
            ,  // craftedItems
            ,  // minedBlockTypes
            ,  // minedCounts
            ,  // placedBlockTypes
            ,  // placedCounts
            ,  // craftedItemTypes
            // craftedCounts
        ) = userStatsSystem.getGlobalStats();
        
        // Verify global stats
        assertEq(totalPlayerUpdates, 3, "Global total player updates should be 3");
        
        vm.stopPrank();
    }

    function testOnlyPlayerSystemCanRecordUpdates() public {
        vm.startPrank(PLAYER);
        
        vm.expectRevert("Only PlayerSystem can call this");
        userStatsSystem.recordPlayerUpdate(PLAYER);
        
        vm.stopPrank();
    }

    function testRecordItemSwapped() public {
        vm.startPrank(FAKE_INVENTORY);
        
        // Prepare swap data
        uint256[] memory inputTypes = new uint256[](2);
        uint256[] memory inputAmounts = new uint256[](2);
        inputTypes[0] = IRON_ORE;
        inputTypes[1] = COAL;
        inputAmounts[0] = 1;
        inputAmounts[1] = 1;
        uint256 outputType = IRON_INGOT;
        uint256 outputAmount = 1;
        
        // Record swaps
        userStatsSystem.recordItemSwapped(PLAYER, inputTypes, inputAmounts, outputType, outputAmount);
        userStatsSystem.recordItemSwapped(PLAYER, inputTypes, inputAmounts, outputType, outputAmount);
        
        // Different output type
        uint256[] memory goldInputTypes = new uint256[](2);
        uint256[] memory goldInputAmounts = new uint256[](2);
        goldInputTypes[0] = GOLD_ORE;
        goldInputTypes[1] = COAL;
        goldInputAmounts[0] = 1;
        goldInputAmounts[1] = 1;
        uint256 goldOutputType = GOLD_INGOT;
        uint256 goldOutputAmount = 1;
        
        userStatsSystem.recordItemSwapped(PLAYER, goldInputTypes, goldInputAmounts, goldOutputType, goldOutputAmount);
        
        // Get user inventory stats
        (
            ,  // totalMinted
            ,  // totalBurned
            ,  // totalMoved
            uint256 totalSwapped,
            ,  // totalTransferredOut
            ,  // totalTransferredIn
            ,  // mintedItems
            ,  // burnedItems
            ,  // mintedItemTypes
            ,  // mintedCounts
            ,  // burnedItemTypes
            // burnedCounts
        ) = userStatsSystem.getUserInventoryStats(PLAYER);
        
        // Verify stats
        assertEq(totalSwapped, 3, "User total swapped should be 3");
        
        // Get global inventory stats
        (
            ,  // totalMinted
            ,  // totalBurned
            ,  // totalMoved
            uint256 globalTotalSwapped,
            ,  // totalTransferredOut
            ,  // totalTransferredIn
            ,  // mintedItems
            ,  // burnedItems
            ,  // mintedItemTypes
            ,  // mintedCounts
            ,  // burnedItemTypes
            // burnedCounts
        ) = userStatsSystem.getGlobalInventoryStats();
        
        // Verify global stats
        assertEq(globalTotalSwapped, 3, "Global total swapped should be 3");
        
        vm.stopPrank();
    }
    
    function testRecordItemTransferred() public {
        vm.startPrank(FAKE_INVENTORY);
        
        // Record transfers
        userStatsSystem.recordItemTransferred(PLAYER, PLAYER2, STONE, 5);
        userStatsSystem.recordItemTransferred(PLAYER, PLAYER2, DIRT, 3);
        userStatsSystem.recordItemTransferred(PLAYER2, PLAYER, IRON_ORE, 2);
        
        // Get user inventory stats for PLAYER (sender)
        (
            ,  // totalMinted
            ,  // totalBurned
            ,  // totalMoved
            ,  // totalSwapped
            uint256 totalTransferredOut,
            uint256 totalTransferredIn,
            ,  // mintedItems
            ,  // burnedItems
            ,  // mintedItemTypes
            ,  // mintedCounts
            ,  // burnedItemTypes
            // burnedCounts
        ) = userStatsSystem.getUserInventoryStats(PLAYER);
        
        // Verify PLAYER stats
        assertEq(totalTransferredOut, 8, "PLAYER transferred out should be 8");
        assertEq(totalTransferredIn, 2, "PLAYER transferred in should be 2");
        
        // Get user inventory stats for PLAYER2 (receiver)
        (
            ,  // totalMinted
            ,  // totalBurned
            ,  // totalMoved
            ,  // totalSwapped
            uint256 player2TransferredOut,
            uint256 player2TransferredIn,
            ,  // mintedItems
            ,  // burnedItems
            ,  // mintedItemTypes
            ,  // mintedCounts
            ,  // burnedItemTypes
            // burnedCounts
        ) = userStatsSystem.getUserInventoryStats(PLAYER2);
        
        // Verify PLAYER2 stats
        assertEq(player2TransferredOut, 2, "PLAYER2 transferred out should be 2");
        assertEq(player2TransferredIn, 8, "PLAYER2 transferred in should be 8");
        
        // Get global inventory stats
        (
            ,  // totalMinted
            ,  // totalBurned
            ,  // totalMoved
            ,  // totalSwapped
            uint256 globalTransferredOut,
            uint256 globalTransferredIn,
            ,  // mintedItems
            ,  // burnedItems
            ,  // mintedItemTypes
            ,  // mintedCounts
            ,  // burnedItemTypes
            // burnedCounts
        ) = userStatsSystem.getGlobalInventoryStats();
        
        // Verify global stats
        assertEq(globalTransferredOut, 10, "Global transferred out should be 10");
        assertEq(globalTransferredIn, 10, "Global transferred in should be 10");
        
        vm.stopPrank();
    }
} 