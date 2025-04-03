// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPlayerSystem {
    // Events
    event PlayerTransformUpdated(address indexed player, uint256 combined, uint32 chunkKey);
    event PlayerProfileUpdated(address indexed player, string name, string skinUrl);

    // Structs
    struct PlayerProfile {
        string name;
        string skinUrl;
        bool initialized;
    }

    // Functions
    function updatePlayerTransform(uint256 combined) external;
    function setPlayerProfile(string calldata name, string calldata skinUrl) external;
    function getPlayerProfile(address player) external view returns (string memory name, string memory skinUrl, bool initialized);

    // Custom errors
    error InvalidPlayerName();
} 