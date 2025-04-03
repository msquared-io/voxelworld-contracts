// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/WorldUtils.sol";
import "../interfaces/IOverlaySystem.sol";
import "../interfaces/IChunkSystem.sol";
import "../interfaces/IInventorySystem.sol";
import "../interfaces/IUserStatsSystem.sol";
import "../constants/MinecraftConstants.sol";

contract OverlaySystem is WorldUtils, IOverlaySystem {
    using MinecraftConstants for uint8;
    using MinecraftConstants for uint256;

    IChunkSystem public immutable chunkSystem;
    IInventorySystem public immutable inventorySystem;
    IUserStatsSystem public userStatsSystem;
    
    // Overlay mapping to store delta updates
    // The key is: (chunkX, chunkY, chunkZ) packed into a uint256
    // Each storage slot contains 32 block values (each 8 bits)
    // Each value is blockType+1 (0 means no change)
    mapping(uint256 => uint256) public overlay;
    
    // Tracking which slots have been modified
    // Each bit represents whether a slot has been modified (1) or not (0)
    // 128 slots are packed into 4 uint256 (32 bits each)
    // The key is: (chunkX, chunkY, chunkZ, trackerIndex) packed into a uint256
    mapping(uint256 => uint256) public modifiedSlotTracker;

    // Block modification history
    // Key is packed world coordinates
    mapping(uint256 => BlockModification) public blockModifications;

    constructor(
        address sessionManager,
        address _chunkSystem,
        address _inventorySystem
    ) WorldUtils(sessionManager) {
        chunkSystem = IChunkSystem(_chunkSystem);
        inventorySystem = IInventorySystem(_inventorySystem);
    }

    function setUserStatsSystem(address _userStatsSystem) external onlyOwner {
        if (_userStatsSystem == address(0)) revert("Invalid address");
        userStatsSystem = IUserStatsSystem(_userStatsSystem);
    }

    function _packChunkStorageKey(
        int chunkX, int chunkY, int chunkZ,
        uint8 slotIndex
    ) internal pure returns (uint256) {
        uint256 uChunkX = uint256(int256(chunkX) + 2**31);
        uint256 uChunkY = uint256(int256(chunkY) + 2**31);
        uint256 uChunkZ = uint256(int256(chunkZ) + 2**31);
        
        return (uChunkX << 72) | (uChunkY << 40) | (uChunkZ << 8) | uint256(slotIndex);
    }

    function _packTrackerKey(
        int chunkX, int chunkY, int chunkZ,
        uint8 trackerIndex
    ) internal pure returns (uint256) {
        uint256 uChunkX = uint256(int256(chunkX) + 2**31);
        uint256 uChunkY = uint256(int256(chunkY) + 2**31);
        uint256 uChunkZ = uint256(int256(chunkZ) + 2**31);
        
        return (uChunkX << 72) | (uChunkY << 40) | (uChunkZ << 8) | uint256(trackerIndex);
    }

    function _getBlockFromSlot(uint256 slotValue, uint8 position) internal pure returns (uint8) {
        return uint8((slotValue >> (position * 8)) & 0xFF);
    }

    function _setBlockInSlot(uint256 slotValue, uint8 position, uint8 blockType) internal pure returns (uint256) {
        uint256 mask = ~(uint256(0xFF) << (position * 8));
        slotValue = slotValue & mask;
        return slotValue | (uint256(blockType) << (position * 8));
    }

    function _markSlotModified(
        int chunkX, int chunkY, int chunkZ,
        uint8 slotIndex
    ) internal {
        uint8 trackerIndex = slotIndex / 32;
        uint8 bitPosition = slotIndex % 32;
        
        uint256 key = _packTrackerKey(chunkX, chunkY, chunkZ, trackerIndex);
        uint256 trackerValue = modifiedSlotTracker[key];
        
        trackerValue = trackerValue | (1 << bitPosition);
        modifiedSlotTracker[key] = trackerValue;
    }

    function _packWorldCoordinates(int x, int y, int z) internal pure returns (uint256) {
        uint256 ux = uint256(int256(x) + 2**31);
        uint256 uy = uint256(int256(y) + 2**31);
        uint256 uz = uint256(int256(z) + 2**31);
        
        return (ux << 64) | (uy << 32) | uz;
    }

    function placeBlock(int32 x, int32 y, int32 z, uint8 blockType) external override {
        if (blockType == MinecraftConstants.AIR) {
            revert CannotPlaceAir();
        }

        address sender = _msgSender();
        
        // Check if player has the block in their inventory
        if (inventorySystem.balanceOf(sender, blockType) == 0) {
            revert InsufficientBlocks();
        }

        (int32 chunkX, int32 chunkY, int32 chunkZ, uint8 blockX, uint8 blockY, uint8 blockZ) = _worldToChunkCoordinates(x, y, z);
        
        if (!chunkSystem.chunkExists(chunkX, chunkY, chunkZ)) {
            revert ChunkDoesNotExist();
        }
        
        uint16 blockIndex = _blockToIndex(blockX, blockY, blockZ);
        (uint8 slotIndex, uint8 position) = _getSlotAndPosition(blockIndex);
        uint256 key = _packChunkStorageKey(chunkX, chunkY, chunkZ, slotIndex);
        
        uint256 slotValue = overlay[key];
        slotValue = _setBlockInSlot(slotValue, position, blockType + 1);
        overlay[key] = slotValue;
        
        _markSlotModified(chunkX, chunkY, chunkZ, slotIndex);

        // Record modification
        uint256 worldKey = _packWorldCoordinates(x, y, z);
        blockModifications[worldKey] = BlockModification({
            modifierAddress: sender,
            timestamp: block.timestamp,
            blockType: blockType
        });
        
        // Record block placement in stats
        userStatsSystem.recordBlockPlaced(sender, blockType);
        
        // Remove block from player's inventory
        inventorySystem.burn(sender, blockType, 1);
        
        emit BlockPlaced(sender, x, y, z, blockType);
    }

    function removeBlock(int32 x, int32 y, int32 z) external override {
        address sender = _msgSender();
        uint8 selectedSlot = inventorySystem.getSelectedSlot(sender);
        (int32 chunkX, int32 chunkY, int32 chunkZ, uint8 blockX, uint8 blockY, uint8 blockZ) = _worldToChunkCoordinates(x, y, z);
        
        if (!chunkSystem.chunkExists(chunkX, chunkY, chunkZ)) {
            revert ChunkDoesNotExist();
        }
        
        uint16 blockIndex = _blockToIndex(blockX, blockY, blockZ);
        (uint8 slotIndex, uint8 position) = _getSlotAndPosition(blockIndex);
        uint256 key = _packChunkStorageKey(chunkX, chunkY, chunkZ, slotIndex);
        
        // Get current block type
        uint256 slotValue = overlay[key];
        uint8 currentBlockType = _getBlockFromSlot(slotValue, position);
        if (currentBlockType == 0) {
            // No overlay data exists, read from chunk RLE data
            currentBlockType = chunkSystem.getBlock(x, y, z);
        } else {
            currentBlockType = currentBlockType - 1;
        }
        
        // Get the selected tool
        (uint256 toolId,) = inventorySystem.getSlotData(sender, selectedSlot);
        bool hasRequiredTool = inventorySystem.isValidToolForBlock(toolId, currentBlockType);
        
        // Use tool durability if player has the required tool
        if (hasRequiredTool) {
            inventorySystem.useToolFromSlot(sender, selectedSlot, currentBlockType);
        }
        
        slotValue = _setBlockInSlot(slotValue, position, MinecraftConstants.AIR + 1);
        overlay[key] = slotValue;
        
        _markSlotModified(chunkX, chunkY, chunkZ, slotIndex);

        // Record modification
        uint256 worldKey = _packWorldCoordinates(x, y, z);
        blockModifications[worldKey] = BlockModification({
            modifierAddress: sender,
            timestamp: block.timestamp,
            blockType: MinecraftConstants.AIR
        });
        
        // Record block mining in stats if block was actually mined (not air and had proper tool)
        if (currentBlockType != MinecraftConstants.AIR && hasRequiredTool) {
            userStatsSystem.recordBlockMined(sender, currentBlockType);
        }
        
        // Add block to player's inventory only if they used the proper tool
        bool minted = false;
        if (currentBlockType != MinecraftConstants.AIR && hasRequiredTool) {
            // Prevent mining water blocks
            if (currentBlockType == MinecraftConstants.FLOWING_WATER || currentBlockType == MinecraftConstants.STILL_WATER) {
                revert("Cannot mine water blocks");
            }

            // If mining stone, give cobblestone instead
            if (currentBlockType == MinecraftConstants.STONE) {
                inventorySystem.mint(sender, MinecraftConstants.COBBLESTONE, 1);
            }
            // If mining coal ore, give coal instead
            else if (currentBlockType == MinecraftConstants.COAL_ORE) {
                inventorySystem.mint(sender, MinecraftConstants.COAL, 1);
            }
            else {
                inventorySystem.mint(sender, currentBlockType, 1);
            }
            minted = true;
        }
        
        emit BlockRemoved(sender, x, y, z, currentBlockType, minted);
    }

    function _getSlotAndPosition(uint16 blockIndex) internal pure returns (uint8 slotIndex, uint8 position) {
        slotIndex = uint8(blockIndex / 32);
        position = uint8(blockIndex % 32);
    }

    function getChunkOverlay(int32 chunkX, int32 chunkY, int32 chunkZ) external view override returns (
        uint16[] memory positions,
        uint8[] memory blockTypes
    ) {
        if (!chunkSystem.chunkExists(chunkX, chunkY, chunkZ)) {
            return (new uint16[](0), new uint8[](0));
        }
        
        uint256 count = 0;
        uint256[4] memory trackerValues;
        bool hasModifications = false;
        
        // First scan to count modified blocks
        for (uint8 trackerIndex = 0; trackerIndex < 4; trackerIndex++) {
            uint256 trackerKey = _packTrackerKey(chunkX, chunkY, chunkZ, trackerIndex);
            uint256 trackerValue = modifiedSlotTracker[trackerKey];
            trackerValues[trackerIndex] = trackerValue;
            
            if (trackerValue == 0) continue;
            hasModifications = true;
            
            uint256 tv = trackerValue;
            while (tv != 0) {
                uint8 bitPos = uint8(_ctz(tv));
                uint8 slotIndex = (trackerIndex * 32) + bitPos;
                uint256 key = _packChunkStorageKey(chunkX, chunkY, chunkZ, slotIndex);
                uint256 slotValue = overlay[key];
                
                for (uint8 position = 0; position < 32; position++) {
                    if (_getBlockFromSlot(slotValue, position) != 0) {
                        count++;
                    }
                }
                
                tv &= ~(uint256(1) << bitPos);
            }
        }
        
        if (!hasModifications || count == 0) {
            return (new uint16[](0), new uint8[](0));
        }
        
        positions = new uint16[](count);
        blockTypes = new uint8[](count);
        uint256 index = 0;
        
        for (uint8 trackerIndex = 0; trackerIndex < 4; trackerIndex++) {
            uint256 trackerValue = trackerValues[trackerIndex];
            if (trackerValue == 0) continue;
            
            uint256 tv = trackerValue;
            while (tv != 0) {
                uint8 bitPos = uint8(_ctz(tv));
                uint8 slotIndex = (trackerIndex * 32) + bitPos;
                uint256 key = _packChunkStorageKey(chunkX, chunkY, chunkZ, slotIndex);
                uint256 slotValue = overlay[key];
                
                for (uint8 position = 0; position < 32; position++) {
                    uint8 value = _getBlockFromSlot(slotValue, position);
                    if (value != 0) {
                        uint16 blockIndex = uint16(slotIndex) * 32 + uint16(position);
                        positions[index] = blockIndex;
                        blockTypes[index] = value - 1;
                        index++;
                    }
                }
                
                tv &= ~(uint256(1) << bitPos);
            }
        }
        
        return (positions, blockTypes);
    }

    function getBlockModification(int32 x, int32 y, int32 z) external view override returns (
        address modifierAddress,
        uint256 timestamp,
        uint8 blockType
    ) {
        uint256 worldKey = _packWorldCoordinates(x, y, z);
        BlockModification memory mod = blockModifications[worldKey];
        return (mod.modifierAddress, mod.timestamp, mod.blockType);
    }

    function wipeChunkOverlay(int32 chunkX, int32 chunkY, int32 chunkZ) external override onlyOwner {
        if (!chunkSystem.chunkExists(chunkX, chunkY, chunkZ)) {
            revert ChunkDoesNotExist();
        }

        // Clear all slots in the chunk's overlay
        for (uint8 trackerIndex = 0; trackerIndex < 4; trackerIndex++) {
            uint256 trackerKey = _packTrackerKey(chunkX, chunkY, chunkZ, trackerIndex);
            uint256 trackerValue = modifiedSlotTracker[trackerKey];
            
            if (trackerValue == 0) continue;
            
            uint256 tv = trackerValue;
            while (tv != 0) {
                uint8 bitPos = uint8(_ctz(tv));
                uint8 slotIndex = (trackerIndex * 32) + bitPos;
                uint256 key = _packChunkStorageKey(chunkX, chunkY, chunkZ, slotIndex);
                
                // Clear the slot
                overlay[key] = 0;
                
                tv &= ~(uint256(1) << bitPos);
            }
            
            // Clear the tracker
            modifiedSlotTracker[trackerKey] = 0;
        }

        emit ChunkOverlayWiped(chunkX, chunkY, chunkZ);
    }
} 