// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/WorldUtils.sol";
import "../interfaces/IChunkSystem.sol";

contract ChunkSystem is WorldUtils, IChunkSystem {    
    // Maps from chunk coordinates to chunk data
    mapping(int => mapping(int => mapping(int => Chunk))) public chunks;

    // Cache structure for RLE ranges
    // Key: chunkX | chunkY | chunkZ | rangeIndex
    // Value: startIndex | endIndex | blockType (packed into uint256)
    mapping(uint256 => uint256) private rleRangeCache;
    
    // Track number of ranges per chunk
    // Key: chunkX | chunkY | chunkZ
    // Value: number of ranges
    mapping(uint256 => uint16) private rangeCounts;

    constructor(address sessionManager) WorldUtils(sessionManager) {
    }

    function _packChunkKey(int32 chunkX, int32 chunkY, int32 chunkZ) internal pure returns (uint256) {
        // Pack chunk coordinates into a single key
        // Each coordinate gets 64 bits to handle negative values
        return (uint256(uint64(int64(chunkX))) << 128) | 
               (uint256(uint64(int64(chunkY))) << 64) | 
               uint256(uint64(int64(chunkZ)));
    }

    function _packRangeKey(uint256 chunkKey, uint16 rangeIndex) internal pure returns (uint256) {
        return (chunkKey << 16) | uint256(rangeIndex);
    }

    function _packRangeValue(uint16 startIndex, uint16 endIndex, uint8 blockType) internal pure returns (uint256) {
        return (uint256(startIndex) << 32) | (uint256(endIndex) << 16) | uint256(blockType);
    }

    function _unpackRangeValue(uint256 value) internal pure returns (uint16 startIndex, uint16 endIndex, uint8 blockType) {
        startIndex = uint16(value >> 32);
        endIndex = uint16(value >> 16);
        blockType = uint8(value);
    }

    function _buildRangeCache(int32 chunkX, int32 chunkY, int32 chunkZ, bytes memory rleData) internal {
        uint256 chunkKey = _packChunkKey(chunkX, chunkY, chunkZ);
        uint16 currentIndex = 0;
        uint16 rangeIndex = 0;
        
        for (uint256 i = 0; i < rleData.length; i += 3) {
            uint16 count = uint16(uint8(rleData[i])) << 8 | uint16(uint8(rleData[i+1]));
            uint8 blockType = uint8(rleData[i+2]);
            
            uint256 rangeKey = _packRangeKey(chunkKey, rangeIndex);
            uint256 rangeValue = _packRangeValue(currentIndex, currentIndex + count - 1, blockType);
            rleRangeCache[rangeKey] = rangeValue;
            
            currentIndex += count;
            rangeIndex++;
        }
        
        rangeCounts[chunkKey] = rangeIndex;
    }

    function _decodeRLEAtIndex(bytes memory rleData, uint16 targetIndex, int32 chunkX, int32 chunkY, int32 chunkZ) internal view returns (uint8) {
        uint256 chunkKey = _packChunkKey(chunkX, chunkY, chunkZ);
        uint16 rangeCount = rangeCounts[chunkKey];
        
        // If cache doesn't exist, fall back to direct RLE decoding
        if (rangeCount == 0) {
            return _decodeRLEDirect(rleData, targetIndex);
        }
        
        // Binary search through the ranges
        uint16 left = 0;
        uint16 right = rangeCount - 1;
        
        while (left <= right) {
            uint16 mid = (left + right) / 2;
            uint256 rangeKey = _packRangeKey(chunkKey, mid);
            (uint16 startIndex, uint16 endIndex, uint8 blockType) = _unpackRangeValue(rleRangeCache[rangeKey]);
            
            if (targetIndex >= startIndex && targetIndex <= endIndex) {
                return blockType;
            }
            
            if (targetIndex < startIndex) {
                if (mid == 0) break;
                right = mid - 1;
            } else {
                left = mid + 1;
            }
        }
        
        revert InvalidRLEData();
    }

    function _decodeRLEDirect(bytes memory rleData, uint16 targetIndex) internal pure returns (uint8) {
        uint16 currentIndex = 0;
        uint256 i = 0;
        
        while (i < rleData.length) {
            uint16 count = uint16(uint8(rleData[i])) << 8 | uint16(uint8(rleData[i+1]));
            uint8 blockType = uint8(rleData[i+2]);
            
            if (targetIndex >= currentIndex && targetIndex < currentIndex + count) {
                return blockType;
            }
            
            currentIndex += count;
            if (currentIndex > targetIndex) {
                break;
            }
            
            i += 3;
        }
        
        revert InvalidRLEData();
    }

    function createChunk(int32 chunkX, int32 chunkY, int32 chunkZ) external override onlyOwner {
        if (chunks[chunkX][chunkY][chunkZ].exists) {
            revert ChunkAlreadyExists();
        }
        
        chunks[chunkX][chunkY][chunkZ].exists = true;
        // Initialize with empty RLE data (just air)
        chunks[chunkX][chunkY][chunkZ].rleData = abi.encodePacked(uint16(4096), uint8(AIR));
        
        emit ChunkCreated(chunkX, chunkY, chunkZ);
    }

    function chunkExists(int32 chunkX, int32 chunkY, int32 chunkZ) public view override returns (bool) {
        return chunks[chunkX][chunkY][chunkZ].exists;
    }

    function getChunkData(int32 chunkX, int32 chunkY, int32 chunkZ) public view override returns (bytes memory) {
        return chunks[chunkX][chunkY][chunkZ].rleData;
    }

    function setChunkData(int32 chunkX, int32 chunkY, int32 chunkZ, bytes calldata rleData) external override onlyOwner {
        if (rleData.length % 3 != 0) {
            revert InvalidRLEData();
        }
        
        if (!chunks[chunkX][chunkY][chunkZ].exists) {
            chunks[chunkX][chunkY][chunkZ].exists = true;
            emit ChunkCreated(chunkX, chunkY, chunkZ);
        }
        
        // Clear existing cache for this chunk
        uint256 chunkKey = _packChunkKey(chunkX, chunkY, chunkZ);
        uint16 oldRangeCount = rangeCounts[chunkKey];
        for (uint16 i = 0; i < oldRangeCount; i++) {
            delete rleRangeCache[_packRangeKey(chunkKey, i)];
        }
        delete rangeCounts[chunkKey];
        
        chunks[chunkX][chunkY][chunkZ].rleData = rleData;
        
        // Build the range cache immediately
        _buildRangeCache(chunkX, chunkY, chunkZ, rleData);
    }

    function getBlock(int32 x, int32 y, int32 z) external view override returns (uint8) {
        (int32 chunkX, int32 chunkY, int32 chunkZ, uint8 blockX, uint8 blockY, uint8 blockZ) = _worldToChunkCoordinates(x, y, z);
        
        if (!chunks[chunkX][chunkY][chunkZ].exists) {
            revert ChunkDoesNotExist();
        }
        
        uint16 blockIndex = _blockToIndex(blockX, blockY, blockZ);
        return _decodeRLEAtIndex(chunks[chunkX][chunkY][chunkZ].rleData, blockIndex, chunkX, chunkY, chunkZ);
    }
} 