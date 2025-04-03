// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/WorldUtils.sol";
import "../interfaces/IPlayerSystem.sol";
import "../interfaces/IUserStatsSystem.sol";

contract PlayerSystem is WorldUtils, IPlayerSystem {
    // Player transforms - maps player address to combined position, rotation and timestamp data
    mapping(address => uint256) public playerTransforms;
    
    // Player profiles - maps player address to profile data
    mapping(address => PlayerProfile) public playerProfiles;
    
    // Reference to user stats system for distance tracking
    IUserStatsSystem public userStatsSystem;

    constructor(
        address sessionManager
    ) WorldUtils(sessionManager) {
    }
    
    function setUserStatsSystem(address _userStatsSystem) external onlyOwner {
        if (_userStatsSystem == address(0)) revert("Invalid address");
        userStatsSystem = IUserStatsSystem(_userStatsSystem);
    }

    // Function to decode position from combined transform data
    function decodePosition(uint256 combined) public pure returns (int x, int y, int z) {
        // Position is stored in the upper 96 bits (shifting right by 160 bits)
        uint256 positionPacked = combined >> 160;
        
        // Extract individual coordinates (each 32 bits)
        uint32 xRaw = uint32(positionPacked >> 64);
        uint32 yRaw = uint32(positionPacked >> 32);
        uint32 zRaw = uint32(positionPacked);

        // Convert back from fixed point and remove offset
        // First convert to int32, then widen to int256 to handle arithmetic
        x = (int256(int32(xRaw)) - 1_000_000_000) / 1000;
        y = (int256(int32(yRaw)) - 1_000_000_000) / 1000;
        z = (int256(int32(zRaw)) - 1_000_000_000) / 1000;
        
        return (x, y, z);
    }

    function _decodeChunkId(uint256 combined) internal pure returns (uint32 chunkKey) {
        // Extract the chunk key (32 bits) which is stored at bits 32-63
        return uint32(combined >> 32);
    }

    function updatePlayerTransform(uint256 combined) external override {
        address sender = _msgSender();
        uint256 previousTransform = playerTransforms[sender];
        
        // Store the new transform
        playerTransforms[sender] = combined;

        uint32 chunkKey = _decodeChunkId(combined);

        emit PlayerTransformUpdated(sender, combined, chunkKey);

        userStatsSystem.recordPlayerUpdate(sender);
        
        // Only calculate distance if this isn't the first transform update
        if (previousTransform != 0) {
            // Decode positions
            (int prevX, int prevY, int prevZ) = decodePosition(previousTransform);
            (int newX, int newY, int newZ) = decodePosition(combined);
            
            // Calculate Euclidean distance (in block units)
            uint256 distance = calculateDistance(prevX, prevY, prevZ, newX, newY, newZ);
            
            // Only record non-zero distances
            if (distance > 0) {
                userStatsSystem.recordDistanceMoved(sender, distance);
            }
        }
    }
    
    // Calculate Euclidean distance between two 3D points
    function calculateDistance(
        int x1, int y1, int z1, 
        int x2, int y2, int z2
    ) internal pure returns (uint256) {
        // Calculate squared differences
        int dx = x2 - x1;
        int dy = y2 - y1;
        int dz = z2 - z1;
        
        // Calculate squared distance
        uint256 squaredDistance = uint256(dx * dx + dy * dy + dz * dz);
        
        // Return square root approximation
        // We return the integer part of the distance (floor)
        return sqrt(squaredDistance);
    }
    
    // Square root approximation using Newton's method
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        
        return y;
    }

    function setPlayerProfile(string calldata name, string calldata skinUrl) external override {
        if (bytes(name).length == 0) {
            revert InvalidPlayerName();
        }
        
        address sender = _msgSender();
        playerProfiles[sender] = PlayerProfile({
            name: name,
            skinUrl: skinUrl,
            initialized: true
        });
        
        emit PlayerProfileUpdated(sender, name, skinUrl);
    }

    function getPlayerProfile(address player) external view override returns (
        string memory name,
        string memory skinUrl,
        bool initialized
    ) {
        PlayerProfile memory profile = playerProfiles[player];
        return (profile.name, profile.skinUrl, profile.initialized);
    }
} 