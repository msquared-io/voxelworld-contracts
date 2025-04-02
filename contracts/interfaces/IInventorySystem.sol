// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Struct for inventory items
struct InventoryItem {
    uint8 slot;          // Slot number where item is stored
    uint256 itemId;      // ID of the item
    uint256 amount;      // Quantity of the item
    string name;         // Name of the item
    uint16 durability;   // Durability of the item - only set for tools
}

interface IInventorySystem {
    // Events
    event ItemMoved(address indexed player, uint8 fromSlot, uint8 toSlot, uint256 itemId, uint256 amount);
    event ItemAdded(address indexed player, uint8 slot, uint256 itemId, uint256 amount);
    event ItemRemoved(address indexed player, uint8 slot, uint256 itemId, uint256 amount);
    event SelectedSlotChanged(address indexed player, uint8 slot);

    // View functions
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isValidToolForBlock(uint256 toolId, uint8 blockType) external view returns (bool);
    function inventorySlots(address player, uint8 slot) external view returns (uint256);
    function slotCounts(address player, uint8 slot) external view returns (uint256);
    function loadInventoryToMemory(address player, uint8 startSlot, uint8 slotCount) external view returns (uint256[] memory inventory);
    function getSlotDataFromMemory(uint256[] memory inventory, uint8 slot, uint8 startSlot) external pure returns (uint256 itemId, uint256 amount);
    function getInventoryContents(address player) external view returns (InventoryItem[] memory items);
    function getSlotData(address player, uint8 slot) external view returns (uint256 itemId, uint256 amount);
    function setSelectedSlot(uint8 slot) external;
    function getSelectedSlot(address player) external view returns (uint8);
    
    // State-changing functions
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function useToolFromSlot(address player, uint8 slot, uint8 blockType) external returns (bool);
    function addToSlot(address player, uint8 slot, uint256 itemId, uint256 amount) external;
    
    // Custom errors
    error InsufficientTools();
    error InsufficientBlocks();
} 