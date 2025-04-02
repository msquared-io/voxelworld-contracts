// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUserStatsSystem {
    // Events
    event BlockMined(address indexed user, uint8 blockType);
    event BlockPlaced(address indexed user, uint8 blockType);
    event DistanceMoved(address indexed user, uint256 distance);
    event ItemCrafted(address indexed user, uint256 itemType, uint256 amount);
    event ItemMinted(address indexed user, uint256 itemType, uint256 amount);
    event ItemBurned(address indexed user, uint256 itemType, uint256 amount);
    event ItemMoved(address indexed user, uint8 fromSlot, uint8 toSlot, uint256 itemType, uint256 amount);

    // Structs
    struct BlockTypeCount {
        uint8 blockType;
        uint256 count;
    }

    struct ItemTypeCount {
        uint256 itemType;
        uint256 count;
    }

    struct UserStatsView {
        address userAddress;
        uint256 totalMined;
        uint256 totalPlaced;
        uint256 totalDistance;
        uint256 totalCrafted;
        uint256 totalMinted;
        uint256 totalBurned;
        uint256 totalMoved;
        // Arrays for easy iteration over all types
        BlockTypeCount[] minedBlocks;
        BlockTypeCount[] placedBlocks;
        ItemTypeCount[] craftedItems;
        ItemTypeCount[] mintedItems;
        ItemTypeCount[] burnedItems;
        // Full mappings for O(1) lookups
        mapping(uint8 => uint256) minedBlockCounts;
        mapping(uint8 => uint256) placedBlockCounts;
        mapping(uint256 => uint256) craftedItemCounts;
        mapping(uint256 => uint256) mintedItemCounts;
        mapping(uint256 => uint256) burnedItemCounts;
    }

    // Functions
    function recordBlockMined(address user, uint8 blockType) external;
    function recordBlockPlaced(address user, uint8 blockType) external;
    function recordDistanceMoved(address user, uint256 distance) external;
    function recordItemCrafted(address user, uint256 itemType, uint256 amount) external;
    function recordItemMinted(address user, uint256 itemType, uint256 amount) external;
    function recordItemBurned(address user, uint256 itemType, uint256 amount) external;
    function recordItemMoved(address user, uint8 fromSlot, uint8 toSlot, uint256 itemType, uint256 amount) external;
    
    // View functions
    function getUserStats(address user) external view returns (
        address userAddress,
        uint256 totalMined,
        uint256 totalPlaced,
        uint256 totalDistance,
        uint256 totalCrafted,
        BlockTypeCount[] memory minedBlocks,
        BlockTypeCount[] memory placedBlocks,
        ItemTypeCount[] memory craftedItems,
        uint256[] memory minedBlockTypes,
        uint256[] memory minedCounts,
        uint256[] memory placedBlockTypes,
        uint256[] memory placedCounts,
        uint256[] memory craftedItemTypes,
        uint256[] memory craftedCounts
    );

    function getUserInventoryStats(address user) external view returns (
        uint256 totalMinted,
        uint256 totalBurned,
        uint256 totalMoved,
        ItemTypeCount[] memory mintedItems,
        ItemTypeCount[] memory burnedItems,
        uint256[] memory mintedItemTypes,
        uint256[] memory mintedCounts,
        uint256[] memory burnedItemTypes,
        uint256[] memory burnedCounts
    );

    function getAllUsers(uint256 offset, uint256 limit) external view returns (address[] memory users);
    
    function getAllUserStats(uint256 offset, uint256 limit) external view returns (
        address[] memory userAddresses,
        uint256[] memory totalMined,
        uint256[] memory totalPlaced,
        uint256[] memory totalDistance,
        uint256[] memory totalCrafted,
        BlockTypeCount[][] memory minedBlocks,
        BlockTypeCount[][] memory placedBlocks,
        ItemTypeCount[][] memory craftedItems,
        uint256[][] memory minedBlockTypes,
        uint256[][] memory minedCounts,
        uint256[][] memory placedBlockTypes,
        uint256[][] memory placedCounts,
        uint256[][] memory craftedItemTypes,
        uint256[][] memory craftedCounts
    );

    function getAllUserInventoryStats(uint256 offset, uint256 limit) external view returns (
        uint256[] memory totalMinted,
        uint256[] memory totalBurned,
        uint256[] memory totalMoved,
        ItemTypeCount[][] memory mintedItems,
        ItemTypeCount[][] memory burnedItems,
        uint256[][] memory mintedItemTypes,
        uint256[][] memory mintedCounts,
        uint256[][] memory burnedItemTypes,
        uint256[][] memory burnedCounts
    );

    function getGlobalStats() external view returns (
        uint256 totalMined,
        uint256 totalPlaced,
        uint256 totalDistance,
        uint256 totalCrafted,
        BlockTypeCount[] memory minedBlocks,
        BlockTypeCount[] memory placedBlocks,
        ItemTypeCount[] memory craftedItems,
        uint256[] memory minedBlockTypes,
        uint256[] memory minedCounts,
        uint256[] memory placedBlockTypes,
        uint256[] memory placedCounts,
        uint256[] memory craftedItemTypes,
        uint256[] memory craftedCounts
    );

    function getGlobalInventoryStats() external view returns (
        uint256 totalMinted,
        uint256 totalBurned,
        uint256 totalMoved,
        ItemTypeCount[] memory mintedItems,
        ItemTypeCount[] memory burnedItems,
        uint256[] memory mintedItemTypes,
        uint256[] memory mintedCounts,
        uint256[] memory burnedItemTypes,
        uint256[] memory burnedCounts
    );
} 