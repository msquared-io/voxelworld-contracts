// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IOverlaySystem {
    // Events
    event BlockPlaced(address indexed player, int32 x, int32 y, int32 z, uint8 blockType);
    event BlockRemoved(address indexed player, int32 x, int32 y, int32 z, uint8 blockType, bool minted);

    // Structs
    struct BlockModification {
        address modifierAddress;
        uint256 timestamp;
        uint8 blockType;
    }

    // Functions
    function placeBlock(int32 x, int32 y, int32 z, uint8 blockType) external;
    function removeBlock(int32 x, int32 y, int32 z) external;
    function getChunkOverlay(int32 chunkX, int32 chunkY, int32 chunkZ) external view returns (uint16[] memory positions, uint8[] memory blockTypes);
    function getBlockModification(int32 x, int32 y, int32 z) external view returns (address modifierAddress, uint256 timestamp, uint8 blockType);

    // Custom errors
    error CannotPlaceAir();
    error CannotRemoveAir();
    error BlockAlreadyExists();
    error ChunkDoesNotExist();
    error InsufficientTools();
    error InsufficientBlocks();
} 