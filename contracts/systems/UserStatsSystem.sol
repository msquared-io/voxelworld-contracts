// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/WorldUtils.sol";
import "../interfaces/IUserStatsSystem.sol";

contract UserStatsSystem is WorldUtils, IUserStatsSystem {
    // Only authorized systems can call state-changing functions
    address public immutable overlaySystem;
    address public immutable movementSystem;
    address public immutable craftingSystem;
    address public immutable inventorySystem;

    // Efficient storage of user stats
    struct UserStats {
        // Total blocks mined and placed
        uint128 totalMined;
        uint128 totalPlaced;
        // Total distance moved (in block units)
        uint256 totalDistance;
        // Total items crafted
        uint256 totalCrafted;
        // Total items minted, burned, and moved
        uint256 totalMinted;
        uint256 totalBurned;
        uint256 totalMoved;
        // Mapping of blockType => count for mining
        mapping(uint8 => uint256) minedBlocks;
        // Mapping of blockType => count for placing
        mapping(uint8 => uint256) placedBlocks;
        // Mapping of itemType => count for crafting
        mapping(uint256 => uint256) craftedItems;
        // Mapping of itemType => count for minting/burning
        mapping(uint256 => uint256) mintedItems;
        mapping(uint256 => uint256) burnedItems;
        // Track unique block types for efficient pagination
        uint8[] minedBlockTypes;
        uint8[] placedBlockTypes;
        // Track unique item types crafted
        uint256[] craftedItemTypes;
        // Track unique item types minted/burned
        uint256[] mintedItemTypes;
        uint256[] burnedItemTypes;
    }

    // Struct to hold block-related arrays to avoid stack too deep
    struct BlockArrays {
        BlockTypeCount[] blockTypeCounts;
        uint256[] types;
        uint256[] counts;
    }

    // Struct to hold item-related arrays to avoid stack too deep
    struct ItemArrays {
        ItemTypeCount[] itemTypeCounts;
        uint256[] types;
        uint256[] counts;
    }

    // Struct to hold stats return data to avoid stack too deep
    struct StatsData {
        uint256 totalMined;
        uint256 totalPlaced;
        uint256 totalDistance;
        uint256 totalCrafted;
        uint256 totalMinted;
        uint256 totalBurned;
        uint256 totalMoved;
        BlockArrays minedBlocks;
        BlockArrays placedBlocks;
        ItemArrays craftedItems;
        ItemArrays mintedItems;
        ItemArrays burnedItems;
    }

    // Global stats tracking
    UserStats private globalStats;

    // Main storage - user address => stats
    mapping(address => UserStats) private userStats;
    // Track all users who have interacted with the system
    address[] private allUsers;
    // Track if a user exists to avoid duplicates in allUsers
    mapping(address => bool) private userExists;

    constructor(
        address sessionManager,
        address _overlaySystem,
        address _movementSystem,
        address _craftingSystem,
        address _inventorySystem
    ) WorldUtils(sessionManager) {
        overlaySystem = _overlaySystem;
        movementSystem = _movementSystem;
        craftingSystem = _craftingSystem;
        inventorySystem = _inventorySystem;
    }

    modifier onlyOverlaySystem() {
        require(msg.sender == overlaySystem, "Only OverlaySystem can call this");
        _;
    }

    modifier onlyMovementSystem() {
        require(msg.sender == movementSystem, "Only MovementSystem can call this");
        _;
    }

    modifier onlyCraftingSystem() {
        require(msg.sender == craftingSystem, "Only CraftingSystem can call this");
        _;
    }

    modifier onlyInventorySystem() {
        require(msg.sender == inventorySystem, "Only InventorySystem can call this");
        _;
    }

    function _addUserIfNew(address user) private {
        if (!userExists[user]) {
            userExists[user] = true;
            allUsers.push(user);
        }
    }

    // Helper function to update block-related stats
    function _updateBlockStats(
        UserStats storage stats,
        uint8 blockType,
        mapping(uint8 => uint256) storage blockCounts,
        uint8[] storage blockTypes,
        bool isMining
    ) private {
        if (isMining) {
            stats.totalMined++;
        } else {
            stats.totalPlaced++;
        }
        
        if (blockCounts[blockType] == 0) {
            blockTypes.push(blockType);
        }
        blockCounts[blockType]++;
    }

    // Helper function to update item-related stats
    function _updateItemStats(
        UserStats storage stats,
        uint256 itemType,
        uint256 amount,
        mapping(uint256 => uint256) storage itemCounts,
        uint256[] storage itemTypes,
        ItemAction action
    ) private {
        if (action == ItemAction.CRAFT) {
            stats.totalCrafted += amount;
        } else if (action == ItemAction.MINT) {
            stats.totalMinted += amount;
        } else if (action == ItemAction.BURN) {
            stats.totalBurned += amount;
        }
        
        if (itemCounts[itemType] == 0) {
            itemTypes.push(itemType);
        }
        itemCounts[itemType] += amount;
    }

    // Helper function to create block type arrays
    function _createBlockArrays(
        uint8[] storage blockTypes,
        mapping(uint8 => uint256) storage blockCounts
    ) private view returns (BlockArrays memory arrays) {
        uint256 length = blockTypes.length;
        arrays.blockTypeCounts = new BlockTypeCount[](length);
        arrays.types = new uint256[](length);
        arrays.counts = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint8 blockType = blockTypes[i];
            arrays.blockTypeCounts[i] = BlockTypeCount({
                blockType: blockType,
                count: blockCounts[blockType]
            });
            arrays.types[i] = blockType;
            arrays.counts[i] = blockCounts[blockType];
        }
    }

    // Helper function to create item type arrays
    function _createItemArrays(
        uint256[] storage itemTypes,
        mapping(uint256 => uint256) storage itemCounts
    ) private view returns (ItemArrays memory arrays) {
        uint256 length = itemTypes.length;
        arrays.itemTypeCounts = new ItemTypeCount[](length);
        arrays.types = new uint256[](length);
        arrays.counts = new uint256[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint256 itemType = itemTypes[i];
            arrays.itemTypeCounts[i] = ItemTypeCount({
                itemType: itemType,
                count: itemCounts[itemType]
            });
            arrays.types[i] = itemType;
            arrays.counts[i] = itemCounts[itemType];
        }
    }

    // Helper function to create stats data
    function _createStatsData(UserStats storage stats) private view returns (StatsData memory data) {
        data.totalMined = stats.totalMined;
        data.totalPlaced = stats.totalPlaced;
        data.totalDistance = stats.totalDistance;
        data.totalCrafted = stats.totalCrafted;
        data.totalMinted = stats.totalMinted;
        data.totalBurned = stats.totalBurned;
        data.totalMoved = stats.totalMoved;
        data.minedBlocks = _createBlockArrays(stats.minedBlockTypes, stats.minedBlocks);
        data.placedBlocks = _createBlockArrays(stats.placedBlockTypes, stats.placedBlocks);
        data.craftedItems = _createItemArrays(stats.craftedItemTypes, stats.craftedItems);
        data.mintedItems = _createItemArrays(stats.mintedItemTypes, stats.mintedItems);
        data.burnedItems = _createItemArrays(stats.burnedItemTypes, stats.burnedItems);
    }

    // Helper enum for item actions
    enum ItemAction { CRAFT, MINT, BURN }

    function recordBlockMined(address user, uint8 blockType) external onlyOverlaySystem {
        _addUserIfNew(user);
        
        // Update user stats
        UserStats storage stats = userStats[user];
        _updateBlockStats(stats, blockType, stats.minedBlocks, stats.minedBlockTypes, true);
        
        // Update global stats
        _updateBlockStats(globalStats, blockType, globalStats.minedBlocks, globalStats.minedBlockTypes, true);
        
        emit BlockMined(user, blockType);
    }

    function recordBlockPlaced(address user, uint8 blockType) external onlyOverlaySystem {
        _addUserIfNew(user);
        
        // Update user stats
        UserStats storage stats = userStats[user];
        _updateBlockStats(stats, blockType, stats.placedBlocks, stats.placedBlockTypes, false);
        
        // Update global stats
        _updateBlockStats(globalStats, blockType, globalStats.placedBlocks, globalStats.placedBlockTypes, false);
        
        emit BlockPlaced(user, blockType);
    }

    function recordDistanceMoved(address user, uint256 distance) external onlyMovementSystem {
        _addUserIfNew(user);
        UserStats storage stats = userStats[user];
        stats.totalDistance += distance;
        globalStats.totalDistance += distance;
        
        emit DistanceMoved(user, distance);
    }

    function recordItemCrafted(address user, uint256 itemType, uint256 amount) external onlyCraftingSystem {
        _addUserIfNew(user);
        
        // Update user stats
        UserStats storage stats = userStats[user];
        _updateItemStats(stats, itemType, amount, stats.craftedItems, stats.craftedItemTypes, ItemAction.CRAFT);
        
        // Update global stats
        _updateItemStats(globalStats, itemType, amount, globalStats.craftedItems, globalStats.craftedItemTypes, ItemAction.CRAFT);
        
        emit ItemCrafted(user, itemType, amount);
    }

    function recordItemMinted(address user, uint256 itemType, uint256 amount) external onlyInventorySystem {
        _addUserIfNew(user);
        
        // Update user stats
        UserStats storage stats = userStats[user];
        _updateItemStats(stats, itemType, amount, stats.mintedItems, stats.mintedItemTypes, ItemAction.MINT);
        
        // Update global stats
        _updateItemStats(globalStats, itemType, amount, globalStats.mintedItems, globalStats.mintedItemTypes, ItemAction.MINT);
        
        emit ItemMinted(user, itemType, amount);
    }

    function recordItemBurned(address user, uint256 itemType, uint256 amount) external onlyInventorySystem {
        _addUserIfNew(user);
        
        // Update user stats
        UserStats storage stats = userStats[user];
        _updateItemStats(stats, itemType, amount, stats.burnedItems, stats.burnedItemTypes, ItemAction.BURN);
        
        // Update global stats
        _updateItemStats(globalStats, itemType, amount, globalStats.burnedItems, globalStats.burnedItemTypes, ItemAction.BURN);
        
        emit ItemBurned(user, itemType, amount);
    }

    function recordItemMoved(address user, uint8 fromSlot, uint8 toSlot, uint256 itemType, uint256 amount) external onlyInventorySystem {
        _addUserIfNew(user);
        UserStats storage stats = userStats[user];
        stats.totalMoved += amount;
        globalStats.totalMoved += amount;
        
        emit ItemMoved(user, fromSlot, toSlot, itemType, amount);
    }

    function _getUserStats(address user) internal view returns (
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
    ) {
        StatsData memory data = _createStatsData(userStats[user]);
        
        return (
            user,
            data.totalMined,
            data.totalPlaced,
            data.totalDistance,
            data.totalCrafted,
            data.minedBlocks.blockTypeCounts,
            data.placedBlocks.blockTypeCounts,
            data.craftedItems.itemTypeCounts,
            data.minedBlocks.types,
            data.minedBlocks.counts,
            data.placedBlocks.types,
            data.placedBlocks.counts,
            data.craftedItems.types,
            data.craftedItems.counts
        );
    }

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
    ) {
        return _getUserStats(user);
    }

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
    ) {
        StatsData memory data = _createStatsData(userStats[user]);
        
        return (
            data.totalMinted,
            data.totalBurned,
            data.totalMoved,
            data.mintedItems.itemTypeCounts,
            data.burnedItems.itemTypeCounts,
            data.mintedItems.types,
            data.mintedItems.counts,
            data.burnedItems.types,
            data.burnedItems.counts
        );
    }

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
    ) {
        StatsData memory data = _createStatsData(globalStats);
        
        return (
            data.totalMined,
            data.totalPlaced,
            data.totalDistance,
            data.totalCrafted,
            data.minedBlocks.blockTypeCounts,
            data.placedBlocks.blockTypeCounts,
            data.craftedItems.itemTypeCounts,
            data.minedBlocks.types,
            data.minedBlocks.counts,
            data.placedBlocks.types,
            data.placedBlocks.counts,
            data.craftedItems.types,
            data.craftedItems.counts
        );
    }

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
    ) {
        StatsData memory data = _createStatsData(globalStats);
        
        return (
            data.totalMinted,
            data.totalBurned,
            data.totalMoved,
            data.mintedItems.itemTypeCounts,
            data.burnedItems.itemTypeCounts,
            data.mintedItems.types,
            data.mintedItems.counts,
            data.burnedItems.types,
            data.burnedItems.counts
        );
    }

    function getAllUsers(uint256 offset, uint256 limit) external view returns (address[] memory users) {
        uint256 totalUsers = allUsers.length;
        if (offset >= totalUsers) {
            return new address[](0);
        }
        
        uint256 end = offset + limit;
        if (end > totalUsers) {
            end = totalUsers;
        }
        uint256 length = end - offset;
        
        users = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            users[i] = allUsers[offset + i];
        }
        
        return users;
    }

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
    ) {
        uint256 totalUsers = allUsers.length;
        if (offset >= totalUsers) {
            return (
                new address[](0),
                new uint256[](0),
                new uint256[](0),
                new uint256[](0),
                new uint256[](0),
                new BlockTypeCount[][](0),
                new BlockTypeCount[][](0),
                new ItemTypeCount[][](0),
                new uint256[][](0),
                new uint256[][](0),
                new uint256[][](0),
                new uint256[][](0),
                new uint256[][](0),
                new uint256[][](0)
            );
        }
        
        uint256 end = offset + limit;
        if (end > totalUsers) {
            end = totalUsers;
        }
        uint256 length = end - offset;
        
        userAddresses = new address[](length);
        totalMined = new uint256[](length);
        totalPlaced = new uint256[](length);
        totalDistance = new uint256[](length);
        totalCrafted = new uint256[](length);
        minedBlocks = new BlockTypeCount[][](length);
        placedBlocks = new BlockTypeCount[][](length);
        craftedItems = new ItemTypeCount[][](length);
        minedBlockTypes = new uint256[][](length);
        minedCounts = new uint256[][](length);
        placedBlockTypes = new uint256[][](length);
        placedCounts = new uint256[][](length);
        craftedItemTypes = new uint256[][](length);
        craftedCounts = new uint256[][](length);
        
        for (uint256 i = 0; i < length; i++) {
            address user = allUsers[offset + i];
            StatsData memory data = _createStatsData(userStats[user]);
            
            userAddresses[i] = user;
            totalMined[i] = data.totalMined;
            totalPlaced[i] = data.totalPlaced;
            totalDistance[i] = data.totalDistance;
            totalCrafted[i] = data.totalCrafted;
            minedBlocks[i] = data.minedBlocks.blockTypeCounts;
            placedBlocks[i] = data.placedBlocks.blockTypeCounts;
            craftedItems[i] = data.craftedItems.itemTypeCounts;
            minedBlockTypes[i] = data.minedBlocks.types;
            minedCounts[i] = data.minedBlocks.counts;
            placedBlockTypes[i] = data.placedBlocks.types;
            placedCounts[i] = data.placedBlocks.counts;
            craftedItemTypes[i] = data.craftedItems.types;
            craftedCounts[i] = data.craftedItems.counts;
        }
    }

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
    ) {
        uint256 totalUsers = allUsers.length;
        if (offset >= totalUsers) {
            return (
                new uint256[](0),
                new uint256[](0),
                new uint256[](0),
                new ItemTypeCount[][](0),
                new ItemTypeCount[][](0),
                new uint256[][](0),
                new uint256[][](0),
                new uint256[][](0),
                new uint256[][](0)
            );
        }
        
        uint256 end = offset + limit;
        if (end > totalUsers) {
            end = totalUsers;
        }
        uint256 length = end - offset;
        
        totalMinted = new uint256[](length);
        totalBurned = new uint256[](length);
        totalMoved = new uint256[](length);
        mintedItems = new ItemTypeCount[][](length);
        burnedItems = new ItemTypeCount[][](length);
        mintedItemTypes = new uint256[][](length);
        mintedCounts = new uint256[][](length);
        burnedItemTypes = new uint256[][](length);
        burnedCounts = new uint256[][](length);
        
        for (uint256 i = 0; i < length; i++) {
            address user = allUsers[offset + i];
            StatsData memory data = _createStatsData(userStats[user]);
            
            totalMinted[i] = data.totalMinted;
            totalBurned[i] = data.totalBurned;
            totalMoved[i] = data.totalMoved;
            mintedItems[i] = data.mintedItems.itemTypeCounts;
            burnedItems[i] = data.burnedItems.itemTypeCounts;
            mintedItemTypes[i] = data.mintedItems.types;
            mintedCounts[i] = data.mintedItems.counts;
            burnedItemTypes[i] = data.burnedItems.types;
            burnedCounts[i] = data.burnedItems.counts;
        }
    }
} 