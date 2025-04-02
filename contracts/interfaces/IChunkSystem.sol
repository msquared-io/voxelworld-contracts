// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IChunkSystem {
    // Events
    event ChunkCreated(int32 chunkX, int32 chunkY, int32 chunkZ);

    // Structs
    struct RLEEntry {
        uint16 count;
        uint8 blockType;
    }

    struct Chunk {
        bool exists;
        bytes rleData;
    }

    // Functions
    function createChunk(int32 chunkX, int32 chunkY, int32 chunkZ) external;
    function chunkExists(int32 chunkX, int32 chunkY, int32 chunkZ) external view returns (bool);
    function getChunkData(int32 chunkX, int32 chunkY, int32 chunkZ) external view returns (bytes memory);
    function setChunkData(int32 chunkX, int32 chunkY, int32 chunkZ, bytes calldata rleData) external;
    function getBlock(int32 x, int32 y, int32 z) external view returns (uint8);

    // Custom errors
    error NotOwner();
    error ChunkAlreadyExists();
    error ChunkDoesNotExist();
    error InvalidRLEData();
} 