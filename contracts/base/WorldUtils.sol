// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../SessionSenderContext.sol";

abstract contract WorldUtils is SessionSenderContext {
    uint8 public constant AIR = 0;

    constructor(address sessionManager) SessionSenderContext(sessionManager) {}

    /**
     * @dev Convert world coordinates to chunk coordinates and local block coordinates
     */
    function _worldToChunkCoordinates(int32 x, int32 y, int32 z) internal pure returns (
        int32 chunkX, int32 chunkY, int32 chunkZ, uint8 blockX, uint8 blockY, uint8 blockZ
    ) {
        // Calculate chunk coordinates (floor division)
        chunkX = x >= 0 ? x / 16 : (x - 15) / 16;
        chunkY = y >= 0 ? y / 16 : (y - 15) / 16;
        chunkZ = z >= 0 ? z / 16 : (z - 15) / 16;
        
        // Calculate local block coordinates
        blockX = uint8(uint32(x >= 0 ? uint32(x % 16) : uint32(16 + (x % 16)) % 16));
        blockY = uint8(uint32(y >= 0 ? uint32(y % 16) : uint32(16 + (y % 16)) % 16));
        blockZ = uint8(uint32(z >= 0 ? uint32(z % 16) : uint32(16 + (z % 16)) % 16));
    }

    /**
     * @dev Calculate the flat array index for a block position
     */
    function _blockToIndex(uint8 x, uint8 y, uint8 z) internal pure returns (uint16) {
        return uint16(x) + (uint16(z) * 16) + (uint16(y) * 256);
    }

    /**
     * @dev Convert flat array index to XYZ coordinates
     */
    function _indexToBlock(uint16 index) internal pure returns (uint8 x, uint8 y, uint8 z) {
        y = uint8((index / 256) % 16);
        z = uint8((index / 16) % 16);
        x = uint8(index % 16);
    }

    /**
     * @dev Count trailing zeros - helper function
     */
    function _ctz(uint256 x) internal pure returns (uint256 r) {
        if (x == 0) return 256;
        
        uint256 n = 0;
        
        if (x & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) { n += 128; x >>= 128; }
        if (x & 0x000000000000000000000000FFFFFFFF == 0) { n += 64; x >>= 64; }
        if (x & 0x00000000FFFFFFFF == 0) { n += 32; x >>= 32; }
        if (x & 0x0000FFFF == 0) { n += 16; x >>= 16; }
        if (x & 0x00FF == 0) { n += 8; x >>= 8; }
        if (x & 0x0F == 0) { n += 4; x >>= 4; }
        if (x & 0x3 == 0) { n += 2; x >>= 2; }
        if (x & 0x1 == 0) { n += 1; }
        
        return n;
    }
} 