// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IChunkSystem.sol";
import "./interfaces/IOverlaySystem.sol";
import "./interfaces/IPlayerSystem.sol";
import "./interfaces/IInventorySystem.sol";
import "./interfaces/ICraftingSystem.sol";
import "./interfaces/IUserStatsSystem.sol";

/**
 * @title VoxelWorld
 * @dev Main contract that ties together all the systems in the Voxel world.
 * Uses an Entity Component System (ECS) style architecture for modularity.
 */
contract VoxelWorld {
    IChunkSystem public immutable chunkSystem;
    IOverlaySystem public immutable overlaySystem;
    IPlayerSystem public immutable playerSystem;
    IInventorySystem public immutable inventorySystem;
    ICraftingSystem public immutable craftingSystem;
    IUserStatsSystem public immutable userStatsSystem;

    constructor(
        address chunkSystemAddress,
        address overlaySystemAddress,
        address playerSystemAddress,
        address inventorySystemAddress,
        address craftingSystemAddress,
        address userStatsSystemAddress
    ) {
        // Validate addresses
        require(chunkSystemAddress != address(0), "Invalid chunk system address");
        require(overlaySystemAddress != address(0), "Invalid overlay system address");
        require(playerSystemAddress != address(0), "Invalid player system address");
        require(inventorySystemAddress != address(0), "Invalid inventory system address");
        require(craftingSystemAddress != address(0), "Invalid crafting system address");
        require(userStatsSystemAddress != address(0), "Invalid user stats system address");

        // Initialize references
        chunkSystem = IChunkSystem(chunkSystemAddress);
        overlaySystem = IOverlaySystem(overlaySystemAddress);
        playerSystem = IPlayerSystem(playerSystemAddress);
        inventorySystem = IInventorySystem(inventorySystemAddress);
        craftingSystem = ICraftingSystem(craftingSystemAddress);
        userStatsSystem = IUserStatsSystem(userStatsSystemAddress);
    }

    // Convenience functions to access all systems in one place
    
    // Chunk System functions
    function createChunk(int32 x, int32 y, int32 z) external {
        chunkSystem.createChunk(x, y, z);
    }

    function getChunkData(int32 x, int32 y, int32 z) external view returns (bytes memory) {
        return chunkSystem.getChunkData(x, y, z);
    }

    function setChunkData(int32 x, int32 y, int32 z, bytes calldata rleData) external {
        chunkSystem.setChunkData(x, y, z, rleData);
    }

    // Overlay System functions
    function placeBlock(int32 x, int32 y, int32 z, uint8 blockType) external {
        overlaySystem.placeBlock(x, y, z, blockType);
    }

    function setSelectedSlot(uint8 slot) external {
        inventorySystem.setSelectedSlot(slot);
    }

    function removeBlock(int32 x, int32 y, int32 z) external {
        overlaySystem.removeBlock(x, y, z);
    }

    function getBlockModification(int32 x, int32 y, int32 z) external view returns (
        address modifierAddress,
        uint256 timestamp,
        uint8 blockType
    ) {
        return overlaySystem.getBlockModification(x, y, z);
    }

    function getChunkOverlay(int32 chunkX, int32 chunkY, int32 chunkZ) external view returns (uint16[] memory positions, uint8[] memory blockTypes) {
        return overlaySystem.getChunkOverlay(chunkX, chunkY, chunkZ);
    }

    // Player System functions
    function updatePlayerTransform(uint256 combined) external {
        playerSystem.updatePlayerTransform(combined);
    }

    function setPlayerProfile(string calldata name, string calldata skinUrl) external {
        playerSystem.setPlayerProfile(name, skinUrl);
    }

    function getPlayerProfile(address player) external view returns (
        string memory name,
        string memory skinUrl,
        bool initialized
    ) {
        return playerSystem.getPlayerProfile(player);
    }

    // Inventory System functions
    function balanceOf(address account, uint256 id) external view returns (uint256) {
        return inventorySystem.balanceOf(account, id);
    }

    function craftItem(uint256 outputItemId) external {
        craftingSystem.craftItem(outputItemId);
    }

    function getRecipe(uint256 outputItemId) external view returns (uint256[] memory inputItemIds, uint256[] memory inputAmounts, uint256 outputAmount, bool exists) {
        return craftingSystem.getRecipe(outputItemId);
    }

    // User Stats System functions
    function getUserStats(address user) external view returns (
        address userAddress,
        uint256 totalMined,
        uint256 totalPlaced,
        uint256 totalDistance,
        uint256 totalCrafted,
        uint256 totalPlayerUpdates,
        IUserStatsSystem.BlockTypeCount[] memory minedBlocks,
        IUserStatsSystem.BlockTypeCount[] memory placedBlocks,
        IUserStatsSystem.ItemTypeCount[] memory craftedItems,
        uint256[] memory minedBlockTypes,
        uint256[] memory minedCounts,
        uint256[] memory placedBlockTypes,
        uint256[] memory placedCounts,
        uint256[] memory craftedItemTypes,
        uint256[] memory craftedCounts
    ) {
        return userStatsSystem.getUserStats(user);
    }

    function getUserInventoryStats(address user) external view returns (
        uint256 totalMinted,
        uint256 totalBurned,
        uint256 totalMoved,
        IUserStatsSystem.ItemTypeCount[] memory mintedItems,
        IUserStatsSystem.ItemTypeCount[] memory burnedItems,
        uint256[] memory mintedItemTypes,
        uint256[] memory mintedCounts,
        uint256[] memory burnedItemTypes,
        uint256[] memory burnedCounts
    ) {
        return userStatsSystem.getUserInventoryStats(user);
    }

    function getAllUsers(uint256 offset, uint256 limit) external view returns (address[] memory users) {
        return userStatsSystem.getAllUsers(offset, limit);
    }

    function getAllUserStats(uint256 offset, uint256 limit) external view returns (
        address[] memory userAddresses,
        uint256[] memory totalMined,
        uint256[] memory totalPlaced,
        uint256[] memory totalDistance,
        uint256[] memory totalCrafted,
        uint256[] memory totalPlayerUpdates,
        IUserStatsSystem.BlockTypeCount[][] memory minedBlocks,
        IUserStatsSystem.BlockTypeCount[][] memory placedBlocks,
        IUserStatsSystem.ItemTypeCount[][] memory craftedItems,
        uint256[][] memory minedBlockTypes,
        uint256[][] memory minedCounts,
        uint256[][] memory placedBlockTypes,
        uint256[][] memory placedCounts,
        uint256[][] memory craftedItemTypes,
        uint256[][] memory craftedCounts
    ) {
        return userStatsSystem.getAllUserStats(offset, limit);
    }

    function getAllUserInventoryStats(uint256 offset, uint256 limit) external view returns (
        uint256[] memory totalMinted,
        uint256[] memory totalBurned,
        uint256[] memory totalMoved,
        IUserStatsSystem.ItemTypeCount[][] memory mintedItems,
        IUserStatsSystem.ItemTypeCount[][] memory burnedItems,
        uint256[][] memory mintedItemTypes,
        uint256[][] memory mintedCounts,
        uint256[][] memory burnedItemTypes,
        uint256[][] memory burnedCounts
    ) {
        return userStatsSystem.getAllUserInventoryStats(offset, limit);
    }

    function getGlobalStats() external view returns (
        uint256 totalMined,
        uint256 totalPlaced,
        uint256 totalDistance,
        uint256 totalCrafted,
        uint256 totalPlayerUpdates,
        IUserStatsSystem.BlockTypeCount[] memory minedBlocks,
        IUserStatsSystem.BlockTypeCount[] memory placedBlocks,
        IUserStatsSystem.ItemTypeCount[] memory craftedItems,
        uint256[] memory minedBlockTypes,
        uint256[] memory minedCounts,
        uint256[] memory placedBlockTypes,
        uint256[] memory placedCounts,
        uint256[] memory craftedItemTypes,
        uint256[] memory craftedCounts
    ) {
        return userStatsSystem.getGlobalStats();
    }
    
    function getGlobalInventoryStats() external view returns (
        uint256 totalMinted,
        uint256 totalBurned,
        uint256 totalMoved,
        IUserStatsSystem.ItemTypeCount[] memory mintedItems,
        IUserStatsSystem.ItemTypeCount[] memory burnedItems,
        uint256[] memory mintedItemTypes,
        uint256[] memory mintedCounts,
        uint256[] memory burnedItemTypes,
        uint256[] memory burnedCounts
    ) {
        return userStatsSystem.getGlobalInventoryStats();
    }
} 