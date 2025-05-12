// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/WorldUtils.sol";
import "../interfaces/IUserStatsSystem.sol";

// Base contract for common functionality
abstract contract StatsBase is WorldUtils {
    constructor(address sessionManager) WorldUtils(sessionManager) {}

    function _addUserIfNew(
        address user,
        mapping(address => bool) storage userExists,
        address[] storage allUsers
    ) internal {
        if (!userExists[user]) {
            userExists[user] = true;
            allUsers.push(user);
        }
    }
}

// Main contract that implements all functionality
contract UserStatsSystem is StatsBase, IUserStatsSystem {
    address public overlaySystem;
    address public craftingSystem;
    address public inventorySystem;
    address public playerSystem;

    // Global counter struct
    struct GlobalCounter {
        uint256 totalCount;
        uint256 lastUpdateTimestamp;
    }
    
    GlobalCounter private globalCounter;

    // Track all users who have interacted with the system
    address[] private allUsers;
    mapping(address => bool) private userExists;
    
    // Track player-specific stats
    struct PlayerData {
        uint256 totalDistance;
        uint256 totalPlayerUpdates;
    }
    mapping(address => PlayerData) private playerData;
    PlayerData private globalPlayerData;

    // Block-related stats
    struct BlockData {
        uint128 totalMined;
        uint128 totalPlaced;
        mapping(uint8 => uint256) minedBlocks;
        mapping(uint8 => uint256) placedBlocks;
        uint8[] minedBlockTypes;
        uint8[] placedBlockTypes;
    }

    mapping(address => BlockData) private blockData;
    BlockData private globalBlockData;

    // Item-related stats
    struct ItemData {
        uint256 totalCrafted;
        uint256 totalMinted;
        uint256 totalBurned;
        uint256 totalMoved;
        uint256 totalSwapped;
        uint256 totalTransferredOut;
        uint256 totalTransferredIn;
        mapping(uint256 => uint256) craftedItems;
        mapping(uint256 => uint256) mintedItems;
        mapping(uint256 => uint256) burnedItems;
        mapping(uint256 => uint256) swappedItems;
        mapping(uint256 => uint256) transferredOutItems;
        mapping(uint256 => uint256) transferredInItems;
        uint256[] craftedItemTypes;
        uint256[] mintedItemTypes;
        uint256[] burnedItemTypes;
        uint256[] swappedItemTypes;
        uint256[] transferredOutItemTypes;
        uint256[] transferredInItemTypes;
    }

    mapping(address => ItemData) private itemData;
    ItemData private globalItemData;

    constructor(
        address sessionManager,
        address _overlaySystem,
        address _craftingSystem,
        address _inventorySystem,
        address _playerSystem
    ) StatsBase(sessionManager) {
        overlaySystem = _overlaySystem;
        craftingSystem = _craftingSystem;
        inventorySystem = _inventorySystem;
        playerSystem = _playerSystem;
    }

    function setOverlaySystem(address _overlaySystem) external onlyOwner {
        overlaySystem = _overlaySystem;
    }

    function setCraftingSystem(address _craftingSystem) external onlyOwner {
        craftingSystem = _craftingSystem;
    }

    function setInventorySystem(address _inventorySystem) external onlyOwner {
        inventorySystem = _inventorySystem;
    }

    function setPlayerSystem(address _playerSystem) external onlyOwner {
        playerSystem = _playerSystem;
    }

    modifier onlyOverlaySystem() {
        require(msg.sender == overlaySystem, "Only OverlaySystem can call this");
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

    modifier onlyPlayerSystem() {
        require(msg.sender == playerSystem, "Only PlayerSystem can call this");
        _;
    }

    function _processBlockStats(
        BlockData storage data,
        uint8 blockType,
        bool isMining
    ) private {
        if (isMining) {
            data.totalMined++;
            if (data.minedBlocks[blockType] == 0) {
                data.minedBlockTypes.push(blockType);
            }
            data.minedBlocks[blockType]++;
        } else {
            data.totalPlaced++;
            if (data.placedBlocks[blockType] == 0) {
                data.placedBlockTypes.push(blockType);
            }
            data.placedBlocks[blockType]++;
        }
    }

    function _processItemStats(
        ItemData storage data,
        uint256 itemType,
        uint256 amount,
        IUserStatsSystem.ItemAction action
    ) private {
        if (action == IUserStatsSystem.ItemAction.CRAFT) {
            data.totalCrafted += amount;
            if (data.craftedItems[itemType] == 0) {
                data.craftedItemTypes.push(itemType);
            }
            data.craftedItems[itemType] += amount;
        } else if (action == IUserStatsSystem.ItemAction.MINT) {
            data.totalMinted += amount;
            if (data.mintedItems[itemType] == 0) {
                data.mintedItemTypes.push(itemType);
            }
            data.mintedItems[itemType] += amount;
        } else if (action == IUserStatsSystem.ItemAction.BURN) {
            data.totalBurned += amount;
            if (data.burnedItems[itemType] == 0) {
                data.burnedItemTypes.push(itemType);
            }
            data.burnedItems[itemType] += amount;
        } else if (action == IUserStatsSystem.ItemAction.MOVE) {
            data.totalMoved += amount;
        } else if (action == IUserStatsSystem.ItemAction.SWAP) {
            data.totalSwapped += amount;
            if (data.swappedItems[itemType] == 0) {
                data.swappedItemTypes.push(itemType);
            }
            data.swappedItems[itemType] += amount;
        } else if (action == IUserStatsSystem.ItemAction.TRANSFER_OUT) {
            data.totalTransferredOut += amount;
            if (data.transferredOutItems[itemType] == 0) {
                data.transferredOutItemTypes.push(itemType);
            }
            data.transferredOutItems[itemType] += amount;
        } else if (action == IUserStatsSystem.ItemAction.TRANSFER_IN) {
            data.totalTransferredIn += amount;
            if (data.transferredInItems[itemType] == 0) {
                data.transferredInItemTypes.push(itemType);
            }
            data.transferredInItems[itemType] += amount;
        }
    }

    event GlobalCounterUpdated(uint256 totalCount, uint256 lastUpdateTimestamp);

    function _incrementGlobalCounter(uint256 amount) private {
        globalCounter.totalCount += amount;
        globalCounter.lastUpdateTimestamp = block.timestamp;
        emit GlobalCounterUpdated(globalCounter.totalCount, globalCounter.lastUpdateTimestamp);
    }

    function recordBlockMined(address user, uint8 blockType) external onlyOverlaySystem {
        _addUserIfNew(user, userExists, allUsers);
        _processBlockStats(blockData[user], blockType, true);
        _processBlockStats(globalBlockData, blockType, true);
        _incrementGlobalCounter(1);
        emit BlockMined(user, blockType);
    }

    function recordBlockPlaced(address user, uint8 blockType) external onlyOverlaySystem {
        _addUserIfNew(user, userExists, allUsers);
        _processBlockStats(blockData[user], blockType, false);
        _processBlockStats(globalBlockData, blockType, false);
        _incrementGlobalCounter(1);
        emit BlockPlaced(user, blockType);
    }

    function recordDistanceMoved(address user, uint256 distance) external onlyPlayerSystem {
        _addUserIfNew(user, userExists, allUsers);
        playerData[user].totalDistance += distance;
        globalPlayerData.totalDistance += distance;
    }

    function recordItemCrafted(address user, uint256 itemType, uint256 amount) external onlyCraftingSystem {
        _addUserIfNew(user, userExists, allUsers);
        _processItemStats(itemData[user], itemType, amount, IUserStatsSystem.ItemAction.CRAFT);
        _processItemStats(globalItemData, itemType, amount, IUserStatsSystem.ItemAction.CRAFT);
        _incrementGlobalCounter(1);
        emit ItemCrafted(user, itemType, amount);
    }

    function recordItemMinted(address user, uint256 itemType, uint256 amount) external onlyInventorySystem {
        _addUserIfNew(user, userExists, allUsers);
        _processItemStats(itemData[user], itemType, amount, IUserStatsSystem.ItemAction.MINT);
        _processItemStats(globalItemData, itemType, amount, IUserStatsSystem.ItemAction.MINT);
        _incrementGlobalCounter(1);
        emit ItemMinted(user, itemType, amount);
    }

    function recordItemBurned(address user, uint256 itemType, uint256 amount) external onlyInventorySystem {
        _addUserIfNew(user, userExists, allUsers);
        _processItemStats(itemData[user], itemType, amount, IUserStatsSystem.ItemAction.BURN);
        _processItemStats(globalItemData, itemType, amount, IUserStatsSystem.ItemAction.BURN);
        _incrementGlobalCounter(1);
        emit ItemBurned(user, itemType, amount);
    }

    function recordItemMoved(address user, uint8 fromSlot, uint8 toSlot, uint256 itemType, uint256 amount) external onlyInventorySystem {
        _addUserIfNew(user, userExists, allUsers);
        _processItemStats(itemData[user], itemType, amount, IUserStatsSystem.ItemAction.MOVE);
        _processItemStats(globalItemData, itemType, amount, IUserStatsSystem.ItemAction.MOVE);
        _incrementGlobalCounter(1);
        emit ItemMoved(user, fromSlot, toSlot, itemType, amount);
    }

    function recordPlayerUpdate(address user) external onlyPlayerSystem {
        _addUserIfNew(user, userExists, allUsers);
        playerData[user].totalPlayerUpdates++;
        globalPlayerData.totalPlayerUpdates++;
        _incrementGlobalCounter(1);
        emit PlayerUpdated(user);
    }

    function recordItemSwapped(
        address user,
        uint256[] calldata inputTypes,
        uint256[] calldata inputAmounts,
        uint256 outputType,
        uint256 outputAmount
    ) external onlyInventorySystem {
        _addUserIfNew(user, userExists, allUsers);
        _processItemStats(itemData[user], outputType, outputAmount, IUserStatsSystem.ItemAction.SWAP);
        _processItemStats(globalItemData, outputType, outputAmount, IUserStatsSystem.ItemAction.SWAP);
        _incrementGlobalCounter(1);
        emit ItemSwapped(user, inputTypes, inputAmounts, outputType, outputAmount);
    }

    function recordItemTransferred(
        address from,
        address to,
        uint256 itemType,
        uint256 amount
    ) external onlyInventorySystem {
        _addUserIfNew(from, userExists, allUsers);
        _addUserIfNew(to, userExists, allUsers);
        
        _processItemStats(itemData[from], itemType, amount, IUserStatsSystem.ItemAction.TRANSFER_OUT);
        _processItemStats(globalItemData, itemType, amount, IUserStatsSystem.ItemAction.TRANSFER_OUT);
        
        _processItemStats(itemData[to], itemType, amount, IUserStatsSystem.ItemAction.TRANSFER_IN);
        _processItemStats(globalItemData, itemType, amount, IUserStatsSystem.ItemAction.TRANSFER_IN);
        
        _incrementGlobalCounter(2);
        emit ItemTransferred(from, to, itemType, amount);
    }

    // Internal functions
    function _getBlockStatsData(BlockData storage data) private view returns (
        uint256 totalMined,
        uint256 totalPlaced,
        IUserStatsSystem.BlockTypeCount[] memory minedBlocks,
        IUserStatsSystem.BlockTypeCount[] memory placedBlocks
    ) {
        totalMined = data.totalMined;
        totalPlaced = data.totalPlaced;

        uint256 minedLength = data.minedBlockTypes.length;
        uint256 placedLength = data.placedBlockTypes.length;

        minedBlocks = new IUserStatsSystem.BlockTypeCount[](minedLength);
        placedBlocks = new IUserStatsSystem.BlockTypeCount[](placedLength);

        for (uint256 i = 0; i < minedLength;) {
            uint8 blockType = data.minedBlockTypes[i];
            minedBlocks[i] = IUserStatsSystem.BlockTypeCount(blockType, data.minedBlocks[blockType]);
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < placedLength;) {
            uint8 blockType = data.placedBlockTypes[i];
            placedBlocks[i] = IUserStatsSystem.BlockTypeCount(blockType, data.placedBlocks[blockType]);
            unchecked { ++i; }
        }
    }

    function _getItemStatsData(ItemData storage data) private view returns (
        uint256 totalCrafted,
        uint256 totalMinted,
        uint256 totalBurned,
        uint256 totalMoved,
        uint256 totalSwapped,
        uint256 totalTransferredOut,
        uint256 totalTransferredIn,
        IUserStatsSystem.ItemTypeCount[] memory craftedItems,
        IUserStatsSystem.ItemTypeCount[] memory mintedItems,
        IUserStatsSystem.ItemTypeCount[] memory burnedItems,
        IUserStatsSystem.ItemTypeCount[] memory swappedItems,
        IUserStatsSystem.ItemTypeCount[] memory transferredOutItems,
        IUserStatsSystem.ItemTypeCount[] memory transferredInItems
    ) {
        totalCrafted = data.totalCrafted;
        totalMinted = data.totalMinted;
        totalBurned = data.totalBurned;
        totalMoved = data.totalMoved;
        totalSwapped = data.totalSwapped;
        totalTransferredOut = data.totalTransferredOut;
        totalTransferredIn = data.totalTransferredIn;

        uint256 craftedLength = data.craftedItemTypes.length;
        uint256 mintedLength = data.mintedItemTypes.length;
        uint256 burnedLength = data.burnedItemTypes.length;
        uint256 swappedLength = data.swappedItemTypes.length;
        uint256 transferredOutLength = data.transferredOutItemTypes.length;
        uint256 transferredInLength = data.transferredInItemTypes.length;

        craftedItems = new IUserStatsSystem.ItemTypeCount[](craftedLength);
        mintedItems = new IUserStatsSystem.ItemTypeCount[](mintedLength);
        burnedItems = new IUserStatsSystem.ItemTypeCount[](burnedLength);
        swappedItems = new IUserStatsSystem.ItemTypeCount[](swappedLength);
        transferredOutItems = new IUserStatsSystem.ItemTypeCount[](transferredOutLength);
        transferredInItems = new IUserStatsSystem.ItemTypeCount[](transferredInLength);

        for (uint256 i = 0; i < craftedLength;) {
            uint256 itemType = data.craftedItemTypes[i];
            craftedItems[i] = IUserStatsSystem.ItemTypeCount(itemType, data.craftedItems[itemType]);
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < mintedLength;) {
            uint256 itemType = data.mintedItemTypes[i];
            mintedItems[i] = IUserStatsSystem.ItemTypeCount(itemType, data.mintedItems[itemType]);
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < burnedLength;) {
            uint256 itemType = data.burnedItemTypes[i];
            burnedItems[i] = IUserStatsSystem.ItemTypeCount(itemType, data.burnedItems[itemType]);
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < swappedLength;) {
            uint256 itemType = data.swappedItemTypes[i];
            swappedItems[i] = IUserStatsSystem.ItemTypeCount(itemType, data.swappedItems[itemType]);
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < transferredOutLength;) {
            uint256 itemType = data.transferredOutItemTypes[i];
            transferredOutItems[i] = IUserStatsSystem.ItemTypeCount(itemType, data.transferredOutItems[itemType]);
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < transferredInLength;) {
            uint256 itemType = data.transferredInItemTypes[i];
            transferredInItems[i] = IUserStatsSystem.ItemTypeCount(itemType, data.transferredInItems[itemType]);
            unchecked { ++i; }
        }
    }

    function _getAllUsers(uint256 offset, uint256 limit) internal view returns (address[] memory users) {
        uint256 totalUsers = allUsers.length;
        if (offset >= totalUsers) {
            return new address[](0);
        }
        
        uint256 end = offset + limit > totalUsers ? totalUsers : offset + limit;
        uint256 length = end - offset;
        
        users = new address[](length);
        for (uint256 i = 0; i < length;) {
            users[i] = allUsers[offset + i];
            unchecked { ++i; }
        }
    }

    function _getUserStats(address user) internal view returns (
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
        (totalMined, totalPlaced, minedBlocks, placedBlocks) = _getBlockStatsData(blockData[user]);
        
        // Get item stats and only use what we need
        uint256 totalSwapped;
        uint256 totalTransferredOut;
        uint256 totalTransferredIn;
        IUserStatsSystem.ItemTypeCount[] memory mintedItems;
        IUserStatsSystem.ItemTypeCount[] memory burnedItems;
        IUserStatsSystem.ItemTypeCount[] memory swappedItems;
        IUserStatsSystem.ItemTypeCount[] memory transferredOutItems;
        IUserStatsSystem.ItemTypeCount[] memory transferredInItems;
        
        (totalCrafted,,,,,,, craftedItems, mintedItems, burnedItems, swappedItems, transferredOutItems, transferredInItems) = _getItemStatsData(itemData[user]);
        
        uint256 minedLength = minedBlocks.length;
        uint256 placedLength = placedBlocks.length;
        uint256 craftedLength = craftedItems.length;
        
        minedBlockTypes = new uint256[](minedLength);
        minedCounts = new uint256[](minedLength);
        placedBlockTypes = new uint256[](placedLength);
        placedCounts = new uint256[](placedLength);
        craftedItemTypes = new uint256[](craftedLength);
        craftedCounts = new uint256[](craftedLength);
        
        for (uint256 i = 0; i < minedLength;) {
            minedBlockTypes[i] = minedBlocks[i].blockType;
            minedCounts[i] = minedBlocks[i].count;
            unchecked { ++i; }
        }
        
        for (uint256 i = 0; i < placedLength;) {
            placedBlockTypes[i] = placedBlocks[i].blockType;
            placedCounts[i] = placedBlocks[i].count;
            unchecked { ++i; }
        }
        
        for (uint256 i = 0; i < craftedLength;) {
            craftedItemTypes[i] = craftedItems[i].itemType;
            craftedCounts[i] = craftedItems[i].count;
            unchecked { ++i; }
        }
        
        return (
            user,
            totalMined,
            totalPlaced,
            playerData[user].totalDistance,
            totalCrafted,
            playerData[user].totalPlayerUpdates,
            minedBlocks,
            placedBlocks,
            craftedItems,
            minedBlockTypes,
            minedCounts,
            placedBlockTypes,
            placedCounts,
            craftedItemTypes,
            craftedCounts
        );
    }

    function _getUserInventoryStats(address user) internal view returns (
        uint256 totalMinted,
        uint256 totalBurned,
        uint256 totalMoved,
        uint256 totalSwapped,
        uint256 totalTransferredOut,
        uint256 totalTransferredIn,
        IUserStatsSystem.ItemTypeCount[] memory mintedItems,
        IUserStatsSystem.ItemTypeCount[] memory burnedItems,
        uint256[] memory mintedItemTypes,
        uint256[] memory mintedCounts,
        uint256[] memory burnedItemTypes,
        uint256[] memory burnedCounts
    ) {
        // Get item stats and only use what we need
        uint256 totalSwappedItems;
        uint256 totalTransferredOutItems;
        uint256 totalTransferredInItems;
        IUserStatsSystem.ItemTypeCount[] memory swappedItems;
        IUserStatsSystem.ItemTypeCount[] memory transferredOutItems;
        IUserStatsSystem.ItemTypeCount[] memory transferredInItems;
        
        (,totalMinted, totalBurned, totalMoved, totalSwappedItems, totalTransferredOutItems, totalTransferredInItems,, mintedItems, burnedItems, swappedItems, transferredOutItems, transferredInItems) = _getItemStatsData(itemData[user]);
        
        uint256 mintedLength = mintedItems.length;
        uint256 burnedLength = burnedItems.length;
        
        mintedItemTypes = new uint256[](mintedLength);
        mintedCounts = new uint256[](mintedLength);
        burnedItemTypes = new uint256[](burnedLength);
        burnedCounts = new uint256[](burnedLength);
        
        for (uint256 i = 0; i < mintedLength;) {
            mintedItemTypes[i] = mintedItems[i].itemType;
            mintedCounts[i] = mintedItems[i].count;
            unchecked { ++i; }
        }
        
        for (uint256 i = 0; i < burnedLength;) {
            burnedItemTypes[i] = burnedItems[i].itemType;
            burnedCounts[i] = burnedItems[i].count;
            unchecked { ++i; }
        }
        
        totalSwapped = totalSwappedItems;
        totalTransferredOut = totalTransferredOutItems;
        totalTransferredIn = totalTransferredInItems;
    }

    function getAllUsers(uint256 offset, uint256 limit) external view returns (address[] memory users) {
        return _getAllUsers(offset, limit);
    }

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
        return _getUserStats(user);
    }

    function getUserInventoryStats(address user) external view returns (
        uint256 totalMinted,
        uint256 totalBurned,
        uint256 totalMoved,
        uint256 totalSwapped,
        uint256 totalTransferredOut,
        uint256 totalTransferredIn,
        IUserStatsSystem.ItemTypeCount[] memory mintedItems,
        IUserStatsSystem.ItemTypeCount[] memory burnedItems,
        uint256[] memory mintedItemTypes,
        uint256[] memory mintedCounts,
        uint256[] memory burnedItemTypes,
        uint256[] memory burnedCounts
    ) {
        uint256 totalSwappedItems;
        uint256 totalTransferredOutItems;
        uint256 totalTransferredInItems;
        (totalMinted, totalBurned, totalMoved, totalSwappedItems, totalTransferredOutItems, totalTransferredInItems, mintedItems, burnedItems, mintedItemTypes, mintedCounts, burnedItemTypes, burnedCounts) = _getUserInventoryStats(user);
        totalSwapped = totalSwappedItems;
        totalTransferredOut = totalTransferredOutItems;
        totalTransferredIn = totalTransferredInItems;
    }

    function getAllUserStats(uint256 offset, uint256 limit) external view returns (
        address[] memory userAddresses,
        uint256[] memory totalMined,
        uint256[] memory totalPlaced,
        uint256[] memory totalDistance,
        uint256[] memory totalCrafted,
        uint256[] memory totalPlayerUpdates,
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
        userAddresses = _getAllUsers(offset, limit);
        uint256 length = userAddresses.length;

        totalMined = new uint256[](length);
        totalPlaced = new uint256[](length);
        totalDistance = new uint256[](length);
        totalCrafted = new uint256[](length);
        totalPlayerUpdates = new uint256[](length);
        minedBlocks = new BlockTypeCount[][](length);
        placedBlocks = new BlockTypeCount[][](length);
        craftedItems = new ItemTypeCount[][](length);
        minedBlockTypes = new uint256[][](length);
        minedCounts = new uint256[][](length);
        placedBlockTypes = new uint256[][](length);
        placedCounts = new uint256[][](length);
        craftedItemTypes = new uint256[][](length);
        craftedCounts = new uint256[][](length);

        for (uint256 i = 0; i < length;) {
            address user;
            (
                user,
                totalMined[i],
                totalPlaced[i],
                totalDistance[i],
                totalCrafted[i],
                totalPlayerUpdates[i],
                minedBlocks[i],
                placedBlocks[i],
                craftedItems[i],
                minedBlockTypes[i],
                minedCounts[i],
                placedBlockTypes[i],
                placedCounts[i],
                craftedItemTypes[i],
                craftedCounts[i]
            ) = _getUserStats(userAddresses[i]);
            unchecked { ++i; }
        }
    }

    function getAllUserInventoryStats(uint256 offset, uint256 limit) external view returns (
        uint256[] memory totalMinted,
        uint256[] memory totalBurned,
        uint256[] memory totalMoved,
        uint256[] memory totalSwapped,
        uint256[] memory totalTransferredOut,
        uint256[] memory totalTransferredIn,
        ItemTypeCount[][] memory mintedItems,
        ItemTypeCount[][] memory burnedItems,
        uint256[][] memory mintedItemTypes,
        uint256[][] memory mintedCounts,
        uint256[][] memory burnedItemTypes,
        uint256[][] memory burnedCounts
    ) {
        address[] memory users = _getAllUsers(offset, limit);
        uint256 length = users.length;

        totalMinted = new uint256[](length);
        totalBurned = new uint256[](length);
        totalMoved = new uint256[](length);
        totalSwapped = new uint256[](length);
        totalTransferredOut = new uint256[](length);
        totalTransferredIn = new uint256[](length);
        mintedItems = new ItemTypeCount[][](length);
        burnedItems = new ItemTypeCount[][](length);
        mintedItemTypes = new uint256[][](length);
        mintedCounts = new uint256[][](length);
        burnedItemTypes = new uint256[][](length);
        burnedCounts = new uint256[][](length);

        for (uint256 i = 0; i < length;) {
            (
                totalMinted[i],
                totalBurned[i],
                totalMoved[i],
                totalSwapped[i],
                totalTransferredOut[i],
                totalTransferredIn[i],
                mintedItems[i],
                burnedItems[i],
                mintedItemTypes[i],
                mintedCounts[i],
                burnedItemTypes[i],
                burnedCounts[i]
            ) = _getUserInventoryStats(users[i]);
            unchecked { ++i; }
        }
    }

    function getGlobalStats() external view returns (
        uint256 totalMined,
        uint256 totalPlaced,
        uint256 totalDistance,
        uint256 totalCrafted,
        uint256 totalPlayerUpdates,
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
        (totalMined, totalPlaced, minedBlocks, placedBlocks) = _getBlockStatsData(globalBlockData);
        
        // Get item stats and only use what we need
        uint256 totalSwapped;
        uint256 totalTransferredOut;
        uint256 totalTransferredIn;
        IUserStatsSystem.ItemTypeCount[] memory mintedItems;
        IUserStatsSystem.ItemTypeCount[] memory burnedItems;
        IUserStatsSystem.ItemTypeCount[] memory swappedItems;
        IUserStatsSystem.ItemTypeCount[] memory transferredOutItems;
        IUserStatsSystem.ItemTypeCount[] memory transferredInItems;
        
        (totalCrafted,,,,,,, craftedItems, mintedItems, burnedItems, swappedItems, transferredOutItems, transferredInItems) = _getItemStatsData(globalItemData);
        
        totalDistance = globalPlayerData.totalDistance;
        totalPlayerUpdates = globalPlayerData.totalPlayerUpdates;

        uint256 minedLength = minedBlocks.length;
        uint256 placedLength = placedBlocks.length;
        uint256 craftedLength = craftedItems.length;

        minedBlockTypes = new uint256[](minedLength);
        minedCounts = new uint256[](minedLength);
        placedBlockTypes = new uint256[](placedLength);
        placedCounts = new uint256[](placedLength);
        craftedItemTypes = new uint256[](craftedLength);
        craftedCounts = new uint256[](craftedLength);

        for (uint256 i = 0; i < minedLength;) {
            minedBlockTypes[i] = minedBlocks[i].blockType;
            minedCounts[i] = minedBlocks[i].count;
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < placedLength;) {
            placedBlockTypes[i] = placedBlocks[i].blockType;
            placedCounts[i] = placedBlocks[i].count;
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < craftedLength;) {
            craftedItemTypes[i] = craftedItems[i].itemType;
            craftedCounts[i] = craftedItems[i].count;
            unchecked { ++i; }
        }
    }

    function getGlobalInventoryStats() external view returns (
        uint256 totalMinted,
        uint256 totalBurned,
        uint256 totalMoved,
        uint256 totalSwapped,
        uint256 totalTransferredOut,
        uint256 totalTransferredIn,
        ItemTypeCount[] memory mintedItems,
        ItemTypeCount[] memory burnedItems,
        uint256[] memory mintedItemTypes,
        uint256[] memory mintedCounts,
        uint256[] memory burnedItemTypes,
        uint256[] memory burnedCounts
    ) {
        uint256 totalSwappedItems;
        uint256 totalTransferredOutItems;
        uint256 totalTransferredInItems;
        ItemTypeCount[] memory swappedItems;
        ItemTypeCount[] memory transferredOutItems;
        ItemTypeCount[] memory transferredInItems;
        
        (,totalMinted, totalBurned, totalMoved, totalSwappedItems, totalTransferredOutItems, totalTransferredInItems,, mintedItems, burnedItems, swappedItems, transferredOutItems, transferredInItems) = _getItemStatsData(globalItemData);

        uint256 mintedLength = mintedItems.length;
        uint256 burnedLength = burnedItems.length;

        mintedItemTypes = new uint256[](mintedLength);
        mintedCounts = new uint256[](mintedLength);
        burnedItemTypes = new uint256[](burnedLength);
        burnedCounts = new uint256[](burnedLength);

        for (uint256 i = 0; i < mintedLength;) {
            mintedItemTypes[i] = mintedItems[i].itemType;
            mintedCounts[i] = mintedItems[i].count;
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < burnedLength;) {
            burnedItemTypes[i] = burnedItems[i].itemType;
            burnedCounts[i] = burnedItems[i].count;
            unchecked { ++i; }
        }
        
        totalSwapped = totalSwappedItems;
        totalTransferredOut = totalTransferredOutItems;
        totalTransferredIn = totalTransferredInItems;
    }

    // New getter function for global counter
    function getGlobalCount() external view returns (uint256 totalCount, uint256 lastUpdateTimestamp) {
        return (globalCounter.totalCount, globalCounter.lastUpdateTimestamp);
    }
} 