// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TestHelper.sol";
import "../../contracts/systems/PlayerSystem.sol";

contract PlayerSystemTest is TestHelper {
    function setUp() public override {
        super.setUp();
    }

    // Helper function to encode position (matches JS encodePosition)
    function encodePosition(int x, int y, int z) internal pure returns (uint256) {
        // Adjust position by eye height (1.4 blocks)
        int adjustedY = y - 14_000; // 1.4 * 10000 for fixed point

        // Add offset to handle negative values (1,000,000) and multiply by 1000 for fixed point
        uint256 posX = uint256(int256((x + 1_000_000) * 1000)) & 0xffffffff;
        uint256 posY = uint256(int256((adjustedY + 1_000_000) * 1000)) & 0xffffffff;
        uint256 posZ = uint256(int256((z + 1_000_000) * 1000)) & 0xffffffff;

        // Pack into 96 bits (3x32 bits)
        return (posX << 64) | (posY << 32) | posZ;
    }

    // Helper function to encode rotation (matches JS encodeRotation)
    function encodeRotation(int x, int y, int z) internal pure returns (uint256) {
        // Convert to fixed point by multiplying by 1000 and add offset (6.3 ≈ 2π)
        uint256 xFixed = uint256(int256((x + 63_000) * 10)) & 0xffffffff;
        uint256 yFixed = uint256(int256((y + 63_000) * 10)) & 0xffffffff;
        uint256 zFixed = uint256(int256((z + 63_000) * 10)) & 0xffffffff;

        return (xFixed << 64) | (yFixed << 32) | zFixed;
    }

    // Helper function to encode combined data (matches JS encodeCombined)
    function encodeCombined(
        uint256 timestamp,
        int posX,
        int posY,
        int posZ,
        int rotX,
        int rotY,
        int rotZ
    ) internal pure returns (uint256) {
        // Calculate chunk coordinates
        int chunkX = posX / 16;
        int chunkY = (posY - 16_500) / 16; // Subtract 1.65 blocks eye height
        int chunkZ = posZ / 16;

        // Combine chunk coordinates into a single 32-bit value
        uint256 chunkKey = (
            (uint256(int256(chunkX + 512) & 0x3ff) << 20) |
            (uint256(int256(chunkY + 512) & 0x3ff) << 10) |
            uint256(int256(chunkZ + 512) & 0x3ff)
        );

        // Encode position and rotation
        uint256 position = encodePosition(posX, posY, posZ);
        uint256 rotation = encodeRotation(rotX, rotY, rotZ);

        // Format: [position(96) | rotation(96) | chunkKey(32) | timestamp(32)]
        return (position << 160) | (rotation << 64) | (chunkKey << 32) | timestamp;
    }

    function test_UpdatePlayerTransform() public {
        vm.startPrank(PLAYER);

        // Initial position at (0,0,0)
        uint256 initialTransform = _packTransform(0, 0, 0, 0, 0, 0, 0);
        playerSystem.updatePlayerTransform(initialTransform);

        // Move to (10,0,0)
        uint256 newTransform = _packTransform(10, 0, 0, 0, 0, 0, 1);
        playerSystem.updatePlayerTransform(newTransform);

        // Get user stats
        (
            address userAddress,
            ,  // totalMined
            ,  // totalPlaced
            uint256 totalDistance,
            ,  // totalCrafted
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

        assertEq(userAddress, PLAYER);
        assertEq(totalDistance, 10);

        vm.stopPrank();
    }

    function test_SetPlayerProfile() public {
        vm.startPrank(PLAYER);

        string memory name = "TestPlayer";
        string memory skinUrl = "https://example.com/skin.png";

        playerSystem.setPlayerProfile(name, skinUrl);

        (string memory storedName, string memory storedSkinUrl, bool initialized) = playerSystem.getPlayerProfile(PLAYER);

        assertEq(storedName, name);
        assertEq(storedSkinUrl, skinUrl);
        assertTrue(initialized);

        vm.stopPrank();
    }

    function test_GetPlayerProfile_Uninitialized() view public {
        (string memory name, string memory skinUrl, bool initialized) = playerSystem.getPlayerProfile(PLAYER);

        assertEq(name, "");
        assertEq(skinUrl, "");
        assertFalse(initialized);
    }

    function test_DecodePosition() view public {
        // Test position (10, 20, 30)
        uint256 transform = _packTransform(10, 20, 30, 0, 0, 0, 0);
        (int x, int y, int z) = playerSystem.decodePosition(transform);

        assertEq(x, 10);
        assertEq(y, 20);
        assertEq(z, 30);

        // Test negative position (-10, -20, -30)
        transform = _packTransform(-10, -20, -30, 0, 0, 0, 0);
        (x, y, z) = playerSystem.decodePosition(transform);

        assertEq(x, -10);
        assertEq(y, -20);
        assertEq(z, -30);

        // Test large position (1000, 2000, 3000)
        transform = _packTransform(1000, 2000, 3000, 0, 0, 0, 0);
        (x, y, z) = playerSystem.decodePosition(transform);

        assertEq(x, 1000);
        assertEq(y, 2000);
        assertEq(z, 3000);
    }

    function _packTransform(
        int x, int y, int z,
        uint8 rotX, uint8 rotY, uint8 rotZ,
        uint32 timestamp
    ) internal pure returns (uint256) {
        // Convert coordinates to fixed point with 3 decimal places and add offset
        uint32 xFixed = uint32(int32(x * 1000) + 1_000_000_000);
        uint32 yFixed = uint32(int32(y * 1000) + 1_000_000_000);
        uint32 zFixed = uint32(int32(z * 1000) + 1_000_000_000);

        // Pack position into upper 96 bits (32 bits each)
        uint256 position = uint256(xFixed) << 64 | uint256(yFixed) << 32 | uint256(zFixed);

        // Pack rotation into middle 24 bits (8 bits each)
        uint256 rotation = uint256(rotX) << 16 | uint256(rotY) << 8 | uint256(rotZ);

        // Pack timestamp into lower 32 bits
        uint256 time = timestamp;

        // Combine all components
        // Position: bits 256-161 (96 bits)
        // Rotation: bits 160-137 (24 bits)
        // Reserved: bits 136-33 (104 bits)
        // Timestamp: bits 32-1 (32 bits)
        return position << 160 | rotation << 136 | time;
    }
} 