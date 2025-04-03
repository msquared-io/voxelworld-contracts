// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IInventorySystem.sol";
import "../interfaces/IUserStatsSystem.sol";
import "../constants/MinecraftConstants.sol";
import "../SessionSenderContext.sol";

contract InventorySystem is ERC1155, IInventorySystem, SessionSenderContext {
    using MinecraftConstants for uint8;
    using MinecraftConstants for uint16;
    using MinecraftConstants for uint256;
    using Strings for uint256;
    using MinecraftConstants for uint16;

    string public constant name = "Voxel World Items";
    string public constant symbol = "VW";
    uint8 public constant MAX_SLOTS = 36; // 27 main inventory + 9 hotbar
    uint8 public constant MAX_STACK_SIZE = 63; // Maximum items per stack for non-tools
    uint8 public constant SLOTS_PER_WORD = 8; // Number of slots that fit in one storage word (256/32)
    uint8 public constant STORAGE_SLOTS_NEEDED = 5; // Ceiling of MAX_SLOTS/SLOTS_PER_WORD

    // Reference to user stats system for tracking
    IUserStatsSystem public userStatsSystem;
    
    // Reference to authorized systems
    address public craftingSystem;
    address public overlaySystem;

    modifier onlyCraftingOrOverlay() {
        require(
            msg.sender == craftingSystem || msg.sender == overlaySystem,
            "Only CraftingSystem or OverlaySystem can call this"
        );
        _;
    }

    function setSystemAddresses(address _craftingSystem, address _overlaySystem) external onlyOwner {
        craftingSystem = _craftingSystem;
        overlaySystem = _overlaySystem;
    }

    // Override _msgSender to use SessionSenderContext's implementation
    function _msgSender() internal view virtual override(Context, SessionSenderContext) returns (address) {
        return SessionSenderContext._msgSender();
    }

    // Tool type bit masks
    uint256 public constant TOOL_TYPE_MASK = 0xFFFF; // First 16 bits for tool type

    // Mapping from player address to packed inventory data
    // Each uint256 stores 9 inventory slots
    mapping(address => mapping(uint8 => uint256)) private packedInventory;

    // Mapping from unique tool ID to its durability
    mapping(uint256 => uint16) public toolDurability;

    // Mapping from block type to required tool type
    mapping(uint8 => uint256) public requiredTool;
    
    // Mapping from block type to required tool level
    mapping(uint8 => uint8) public requiredToolLevel;

    uint256 public nextTokenId = 1;

    // Mapping from item ID to its name
    mapping(uint256 => string) private _itemNames;
    mapping(uint256 => uint16) private _toolTypeDurability;

    // Selected slot per player
    mapping(address => uint8) public selectedSlots;

    constructor(
        address sessionManager
    ) ERC1155("") SessionSenderContext(sessionManager) {
        // Initialize item names
        _itemNames[MinecraftConstants.WOODEN_PICKAXE] = "Wooden Pickaxe";
        _itemNames[MinecraftConstants.STONE_PICKAXE] = "Stone Pickaxe";
        _itemNames[MinecraftConstants.IRON_PICKAXE] = "Iron Pickaxe";
        _itemNames[MinecraftConstants.DIAMOND_PICKAXE] = "Diamond Pickaxe";
        _itemNames[MinecraftConstants.GOLDEN_PICKAXE] = "Golden Pickaxe";
        _itemNames[MinecraftConstants.SHEARS] = "Shears";

        // Initialize block names
        _itemNames[MinecraftConstants.STONE] = "Stone";
        _itemNames[MinecraftConstants.GRASS] = "Grass";
        _itemNames[MinecraftConstants.DIRT] = "Dirt";
        _itemNames[MinecraftConstants.COAL_ORE] = "Coal Ore";
        _itemNames[MinecraftConstants.IRON_ORE] = "Iron Ore";
        _itemNames[MinecraftConstants.GOLD_ORE] = "Gold Ore";
        _itemNames[MinecraftConstants.DIAMOND_ORE] = "Diamond Ore";
        _itemNames[MinecraftConstants.EMERALD_ORE] = "Emerald Ore";
        _itemNames[MinecraftConstants.REDSTONE_ORE] = "Redstone Ore";
        _itemNames[MinecraftConstants.LAPIS_LAZULI_ORE] = "Lapis Lazuli Ore";
        _itemNames[MinecraftConstants.SAND] = "Sand";
        _itemNames[MinecraftConstants.GRAVEL] = "Gravel";
        _itemNames[MinecraftConstants.COBBLESTONE] = "Cobblestone";
        _itemNames[MinecraftConstants.WOOD] = "Wood";
        _itemNames[MinecraftConstants.LEAVES] = "Leaves";

        // Set required tools for blocks
        requiredTool[MinecraftConstants.STONE] = MinecraftConstants.WOODEN_PICKAXE;
        requiredTool[MinecraftConstants.COAL_ORE] = MinecraftConstants.WOODEN_PICKAXE;
        requiredTool[MinecraftConstants.IRON_ORE] = MinecraftConstants.STONE_PICKAXE;
        requiredTool[MinecraftConstants.GOLD_ORE] = MinecraftConstants.IRON_PICKAXE;
        requiredTool[MinecraftConstants.DIAMOND_ORE] = MinecraftConstants.IRON_PICKAXE;
        requiredTool[MinecraftConstants.EMERALD_ORE] = MinecraftConstants.IRON_PICKAXE;
        requiredTool[MinecraftConstants.REDSTONE_ORE] = MinecraftConstants.IRON_PICKAXE;
        requiredTool[MinecraftConstants.LAPIS_LAZULI_ORE] = MinecraftConstants.STONE_PICKAXE;
        requiredTool[MinecraftConstants.LEAVES] = MinecraftConstants.SHEARS;
        
        // Set required tool levels
        requiredToolLevel[MinecraftConstants.STONE] = MinecraftConstants.TOOL_LEVEL_WOODEN;
        requiredToolLevel[MinecraftConstants.COAL_ORE] = MinecraftConstants.TOOL_LEVEL_WOODEN;
        requiredToolLevel[MinecraftConstants.IRON_ORE] = MinecraftConstants.TOOL_LEVEL_STONE;
        requiredToolLevel[MinecraftConstants.GOLD_ORE] = MinecraftConstants.TOOL_LEVEL_IRON;
        requiredToolLevel[MinecraftConstants.DIAMOND_ORE] = MinecraftConstants.TOOL_LEVEL_IRON;
        requiredToolLevel[MinecraftConstants.EMERALD_ORE] = MinecraftConstants.TOOL_LEVEL_IRON;
        requiredToolLevel[MinecraftConstants.REDSTONE_ORE] = MinecraftConstants.TOOL_LEVEL_IRON;
        requiredToolLevel[MinecraftConstants.LAPIS_LAZULI_ORE] = MinecraftConstants.TOOL_LEVEL_STONE;
        requiredToolLevel[MinecraftConstants.LEAVES] = MinecraftConstants.TOOL_LEVEL_NONE;

        _toolTypeDurability[MinecraftConstants.WOODEN_PICKAXE] = MinecraftConstants.WOODEN_PICKAXE_DURABILITY;
        _toolTypeDurability[MinecraftConstants.STONE_PICKAXE] = MinecraftConstants.STONE_PICKAXE_DURABILITY;
        _toolTypeDurability[MinecraftConstants.IRON_PICKAXE] = MinecraftConstants.IRON_PICKAXE_DURABILITY;
        _toolTypeDurability[MinecraftConstants.DIAMOND_PICKAXE] = MinecraftConstants.DIAMOND_PICKAXE_DURABILITY;
        _toolTypeDurability[MinecraftConstants.GOLDEN_PICKAXE] = MinecraftConstants.GOLDEN_PICKAXE_DURABILITY;
        _toolTypeDurability[MinecraftConstants.SHEARS] = MinecraftConstants.SHEARS_DURABILITY;
    }

    function _isToolItem(uint256 id) internal pure returns (bool) {
        // First check if it's a tool instance (has tool type in first 16 bits)
        uint256 typeId = id & TOOL_TYPE_MASK;

        return (
            typeId == MinecraftConstants.WOODEN_PICKAXE ||
            typeId == MinecraftConstants.STONE_PICKAXE ||
            typeId == MinecraftConstants.IRON_PICKAXE ||
            typeId == MinecraftConstants.DIAMOND_PICKAXE ||
            typeId == MinecraftConstants.GOLDEN_PICKAXE ||
            typeId == MinecraftConstants.SHEARS
        );
    }

    // Helper functions for packing/unpacking inventory data
    function _packSlot(uint256 itemId, uint256 amount) internal pure returns (uint32) {
        require(itemId < (1 << 26), "Item ID too large"); // 26 bits
        require(amount < 64, "Amount too large"); // 6 bits (0-63)
        return uint32((itemId << 6) | amount);
    }

    function _unpackSlot(uint32 packedSlot) internal pure returns (uint256 itemId, uint256 amount) {
        amount = uint256(packedSlot & 0x3F); // 6 bits for amount (0-63)
        itemId = uint256((packedSlot >> 6) & 0x3FFFFFF); // 26 bits for itemId
    }

    function _getPackedSlotIndex(uint8 slot) internal pure returns (uint8 storageIndex, uint8 offset) {
        storageIndex = slot / SLOTS_PER_WORD;
        offset = (slot % SLOTS_PER_WORD) * 32; // 32 bits per slot (26 + 6)
    }

    // Read specified range of inventory slots into memory
    function _loadInventoryToMemory(address player, uint8 startSlot, uint8 slotCount) internal view returns (uint256[] memory inventory) {
        if (startSlot + slotCount > MAX_SLOTS) {
            slotCount = MAX_SLOTS - startSlot;
        }
        
        require(startSlot < MAX_SLOTS, "Start slot out of range");
        require(slotCount > 0 && startSlot + slotCount <= MAX_SLOTS, "Invalid slot count");

        // Calculate which storage slots we need to read
        uint8 startStorageSlot = startSlot / SLOTS_PER_WORD;
        uint8 endStorageSlot = (startSlot + slotCount - 1) / SLOTS_PER_WORD;
        uint8 storageSlotCount = endStorageSlot - startStorageSlot + 1;

        inventory = new uint256[](storageSlotCount);
        for (uint8 i = 0; i < storageSlotCount; i++) {
            inventory[i] = packedInventory[player][startStorageSlot + i];
        }
        return inventory;
    }

    // Get slot data from memory
    function getSlotDataFromMemory(uint256[] memory inventory, uint8 slot, uint8 startSlot) public pure returns (uint256 itemId, uint256 amount) {
        uint8 storageIndex = slot / SLOTS_PER_WORD;
        uint8 position = slot % SLOTS_PER_WORD;
        uint8 relativeStorageIndex = storageIndex - (startSlot / SLOTS_PER_WORD);
        require(relativeStorageIndex < inventory.length, "Invalid slot access");
        uint256 offset = position * 32;
        uint32 slotData = uint32((inventory[relativeStorageIndex] >> offset) & 0xFFFFFFFF);
        return _unpackSlot(slotData);
    }

    // Function to get all items in a player's inventory
    function getInventoryContents(address player) external view returns (InventoryItem[] memory items) {
        uint256[] memory inventory = _loadInventoryToMemory(player, 0, MAX_SLOTS);
        uint256 count = 0;
        
        // Count non-empty slots
        for (uint8 i = 0; i < MAX_SLOTS; i++) {
            (uint256 itemId, uint256 amount) = getSlotDataFromMemory(inventory, i, 0);
            if (itemId != 0 && amount != 0) count++;
        }

        // Initialize return array
        items = new InventoryItem[](count);
        uint256 index = 0;

        // Fill array with inventory data
        for (uint8 i = 0; i < MAX_SLOTS; i++) {
            (uint256 itemId, uint256 amount) = getSlotDataFromMemory(inventory, i, 0);

            if (itemId != 0 && amount != 0) {
                items[index] = InventoryItem({
                    slot: i,
                    itemId: itemId,
                    amount: amount,
                    name: _itemNames[itemId],
                    durability: toolDurability[itemId]
                });
                index++;
            }
        }

        return items;
    }

    // Set slot data in storage
    function _setSlotData(address player, uint8 slot, uint256 itemId, uint256 amount) internal {
        uint8 storageIndex = slot / SLOTS_PER_WORD;
        uint8 position = slot % SLOTS_PER_WORD;
        uint256 offset = position * 32;
        uint256 packed = packedInventory[player][storageIndex];
        
        // Clear the bits for this slot
        uint256 mask = ~(uint256(0xFFFFFFFF) << offset);
        if (offset + 32 < 256) {
            mask = mask | (~uint256(0) << (offset + 32));
        }
        
        // Pack the new data and set it
        uint32 slotData = _packSlot(itemId, amount);
        packed = (packed & mask) | (uint256(slotData) << offset);
        packedInventory[player][storageIndex] = packed;
    }

    // Function to add item to a specific slot
    function addToSlot(address player, uint8 slot, uint256 itemId, uint256 amount) external onlyCraftingOrOverlay {
        require(slot < MAX_SLOTS, "Invalid slot number");
        require(amount > 0, "Amount must be positive");
        
        // Only read the storage word containing this slot
        uint8 storageSlot = slot / SLOTS_PER_WORD;
        uint256[] memory inventory = _loadInventoryToMemory(player, storageSlot * SLOTS_PER_WORD, SLOTS_PER_WORD);
        (uint256 existingItemId, uint256 existingAmount) = getSlotDataFromMemory(inventory, slot, storageSlot * SLOTS_PER_WORD);
        bool isTool = _isToolItem(itemId);
        
        // If slot is empty or has same item type
        require(
            existingItemId == 0 || existingItemId == itemId,
            "Slot contains different item type"
        );

        // Check stack size limit for non-tools
        if (!isTool) {
            require(existingAmount + amount <= MAX_STACK_SIZE, "Stack size limit exceeded");
        } else {
            require(existingAmount + amount <= 1, "Tools cannot stack");
        }

        // Update slot
        _setSlotData(player, slot, itemId, existingAmount + amount);

        // Mint the tokens to update ERC1155 balance
        _mint(player, itemId, amount, "");

        emit ItemAdded(player, slot, itemId, amount);
    }

    // Function to remove item from a specific slot
    function removeFromSlot(address player, uint8 slot, uint256 amount) external onlyCraftingOrOverlay {
        require(slot < MAX_SLOTS, "Invalid slot number");
        require(amount > 0, "Amount must be positive");
        
        // Only read the storage word containing this slot
        uint8 storageSlot = slot / SLOTS_PER_WORD;
        uint256[] memory inventory = _loadInventoryToMemory(player, storageSlot * SLOTS_PER_WORD, SLOTS_PER_WORD);
        (uint256 itemId, uint256 existingAmount) = getSlotDataFromMemory(inventory, slot, storageSlot * SLOTS_PER_WORD);
        require(itemId != 0, "Slot is empty");
        require(existingAmount >= amount, "Insufficient items in slot");

        uint256 newAmount = existingAmount - amount;
        if (newAmount == 0) {
            _setSlotData(player, slot, 0, 0);
        } else {
            _setSlotData(player, slot, itemId, newAmount);
        }

        emit ItemRemoved(player, slot, itemId, amount);
    }

    // Function to move items between slots
    function moveItems(address player, uint8 fromSlot, uint8 toSlot, uint256 amount) external {
        require(fromSlot < MAX_SLOTS && toSlot < MAX_SLOTS, "Invalid slot number");
        require(fromSlot != toSlot, "Cannot move to same slot");
        require(amount > 0, "Amount must be positive");

        // Calculate which storage slots we need to read
        uint8 fromStorageSlot = fromSlot / SLOTS_PER_WORD;
        uint8 toStorageSlot = toSlot / SLOTS_PER_WORD;
        
        uint256[] memory fromInventory;
        uint256[] memory toInventory;
        
        if (fromStorageSlot == toStorageSlot) {
            // If both slots are in the same storage word, only read once
            fromInventory = _loadInventoryToMemory(player, fromStorageSlot * SLOTS_PER_WORD, SLOTS_PER_WORD);
            toInventory = fromInventory;
        } else {
            // Read both storage words separately
            fromInventory = _loadInventoryToMemory(player, fromStorageSlot * SLOTS_PER_WORD, SLOTS_PER_WORD);
            toInventory = _loadInventoryToMemory(player, toStorageSlot * SLOTS_PER_WORD, SLOTS_PER_WORD);
        }

        (uint256 fromItemId, uint256 fromAmount) = getSlotDataFromMemory(fromInventory, fromSlot, fromStorageSlot * SLOTS_PER_WORD);
        (uint256 toItemId, uint256 toAmount) = getSlotDataFromMemory(toInventory, toSlot, toStorageSlot * SLOTS_PER_WORD);

        require(fromItemId != 0, "Source slot is empty");
        require(fromAmount >= amount, "Insufficient items in source slot");

        bool isFromTool = _isToolItem(fromItemId);

        // Case 1: Moving to empty slot (can be partial or full amount)
        if (toItemId == 0) {
            // For tools, must move the entire tool
            if (isFromTool) {
                require(amount == 1 && fromAmount == 1, "Tools must be moved as a single unit");
            } else {
                require(amount <= MAX_STACK_SIZE, "Cannot exceed max stack size");
            }

            // Move items to empty slot
            _setSlotData(player, toSlot, fromItemId, amount);
            
            // Update source slot
            uint256 newFromAmount = fromAmount - amount;
            if (newFromAmount == 0) {
                _setSlotData(player, fromSlot, 0, 0);
            } else {
                _setSlotData(player, fromSlot, fromItemId, newFromAmount);
            }

            // Record item movement in stats
            if (address(userStatsSystem) != address(0)) {
                userStatsSystem.recordItemMoved(player, fromSlot, toSlot, fromItemId, amount);
            }

            emit ItemMoved(player, fromSlot, toSlot, fromItemId, amount);
        }
        // Case 2: Moving to a slot with the same item type
        else if (fromItemId == toItemId && !isFromTool) {
            require(toAmount + amount <= MAX_STACK_SIZE, "Stack size limit exceeded");

            // Move items to target slot
            _setSlotData(player, toSlot, toItemId, toAmount + amount);
            
            // Update source slot
            uint256 newFromAmount = fromAmount - amount;
            if (newFromAmount == 0) {
                _setSlotData(player, fromSlot, 0, 0);
            } else {
                _setSlotData(player, fromSlot, fromItemId, newFromAmount);
            }

            // Record item movement in stats
            if (address(userStatsSystem) != address(0)) {
                userStatsSystem.recordItemMoved(player, fromSlot, toSlot, fromItemId, amount);
            }

            emit ItemMoved(player, fromSlot, toSlot, fromItemId, amount);
        }
        // Case 3: Swapping entire slots
        else {
            // Must move entire stack when swapping different items
            require(amount == fromAmount, "Must swap entire slot contents");

            // Perform the swap
            _setSlotData(player, fromSlot, toItemId, toAmount);
            _setSlotData(player, toSlot, fromItemId, fromAmount);

            // Record both item movements in stats
            if (address(userStatsSystem) != address(0)) {
                userStatsSystem.recordItemMoved(player, fromSlot, toSlot, fromItemId, fromAmount);
                userStatsSystem.recordItemMoved(player, toSlot, fromSlot, toItemId, toAmount);
            }

            emit ItemMoved(player, fromSlot, toSlot, fromItemId, amount);
            emit ItemMoved(player, toSlot, fromSlot, toItemId, fromAmount);
        }
    }

    // Override mint function
    function mint(address to, uint256 id, uint256 amount) external override onlyCraftingOrOverlay {
        require(amount > 0, "Amount must be positive");

        uint256 tokenId = id;
        if (_isToolItem(id)) {
            require(amount == 1, "Tools must be minted one at a time");
            
            // Create a new unique token ID with tool type in first 16 bits and nonce in remaining bits
            tokenId = (nextTokenId++ << 16) | (id & TOOL_TYPE_MASK);
            
            toolDurability[tokenId] = _toolTypeDurability[id];
            
            // Set the name for the new tool ID
            _itemNames[tokenId] = _itemNames[id];
        }

        // Mint the tokens first
        _mint(to, tokenId, amount, "");

        // Record minting in stats
        if (address(userStatsSystem) != address(0)) {
            userStatsSystem.recordItemMinted(to, tokenId, amount);
        }

        // First try to find an existing stack of the same item type that has space
        bool slotFound = false;
        uint256[] memory inventory = _loadInventoryToMemory(to, 0, MAX_SLOTS);
        uint256 remainingAmount = amount;
        
        // First pass: look for existing stacks with space
        if (!_isToolItem(tokenId)) {
            for (uint8 i = 0; i < MAX_SLOTS && remainingAmount > 0; i++) {
                (uint256 slotItemId, uint256 slotAmount) = getSlotDataFromMemory(inventory, i, 0);
                if (slotItemId == tokenId && slotAmount < MAX_STACK_SIZE) {
                    uint256 spaceInStack = MAX_STACK_SIZE - slotAmount;
                    uint256 amountToAdd = spaceInStack >= remainingAmount ? remainingAmount : spaceInStack;
                    _setSlotData(to, i, tokenId, slotAmount + amountToAdd);
                    emit ItemAdded(to, i, tokenId, amountToAdd);
                    remainingAmount -= amountToAdd;
                    slotFound = true;
                }
            }
        }
        
        // Second pass: look for slots that have never been used (itemId == 0)
        if (remainingAmount > 0) {
            for (uint8 i = 0; i < MAX_SLOTS && remainingAmount > 0; i++) {
                (uint256 slotItemId, ) = getSlotDataFromMemory(inventory, i, 0);
                if (slotItemId == 0) {
                    uint256 amountToAdd = remainingAmount > MAX_STACK_SIZE ? MAX_STACK_SIZE : remainingAmount;
                    _setSlotData(to, i, tokenId, amountToAdd);
                    emit ItemAdded(to, i, tokenId, amountToAdd);
                    remainingAmount -= amountToAdd;
                    slotFound = true;
                }
            }
        }

        // Third pass: look for slots that were just emptied (itemId == 0 and slotAmount == 0)
        if (remainingAmount > 0) {
            for (uint8 i = 0; i < MAX_SLOTS && remainingAmount > 0; i++) {
                (uint256 slotItemId, uint256 slotAmount) = getSlotDataFromMemory(inventory, i, 0);
                if (slotItemId == 0 && slotAmount == 0) {
                    uint256 amountToAdd = remainingAmount > MAX_STACK_SIZE ? MAX_STACK_SIZE : remainingAmount;
                    _setSlotData(to, i, tokenId, amountToAdd);
                    emit ItemAdded(to, i, tokenId, amountToAdd);
                    remainingAmount -= amountToAdd;
                    slotFound = true;
                }
            }
        }
        
        if (!slotFound || remainingAmount > 0) {
            revert("No empty slots available");
        }
    }

    // Override burn function
    function burn(address from, uint256 id, uint256 amount) external override onlyCraftingOrOverlay {
        require(amount > 0, "Amount must be positive");
        
        if (_isToolItem(id)) {
            require(amount == 1, "Tools must be burned one at a time");
        }

        // Record burning in stats
        if (address(userStatsSystem) != address(0)) {
            userStatsSystem.recordItemBurned(from, id, amount);
        }

        // Get all inventory contents in one read
        InventoryItem[] memory contents = this.getInventoryContents(from);
        
        // First pass: count total available
        uint256 totalFound = 0;
        for (uint256 i = 0; i < contents.length; i++) {
            if (contents[i].itemId == id) {
                totalFound += contents[i].amount;
            }
        }
        
        require(totalFound >= amount, string.concat("Insufficient items in inventory. Found: ", totalFound.toString(), ", Required: ", amount.toString(), " for ", id.toString()));
        
        // Burn the tokens first
        _burn(from, id, amount);

        // Second pass: update inventory slots
        uint256 remainingAmount = amount;
        for (uint256 i = 0; i < contents.length && remainingAmount > 0; i++) {
            if (contents[i].itemId == id) {
                uint256 amountToBurn = remainingAmount > contents[i].amount ? contents[i].amount : remainingAmount;
                uint256 newAmount = contents[i].amount - amountToBurn;
                
                if (newAmount == 0) {
                    _setSlotData(from, contents[i].slot, 0, 0);
                } else {
                    _setSlotData(from, contents[i].slot, id, newAmount);
                }

                emit ItemRemoved(from, contents[i].slot, id, amountToBurn);
                remainingAmount -= amountToBurn;
            }
        }
    }

    // View functions
    function balanceOf(address account, uint256 id) public view virtual override(ERC1155, IInventorySystem) returns (uint256) {
        return super.balanceOf(account, id);
    }

    function inventorySlots(address player, uint8 slot) external view returns (uint256) {
        uint8 storageSlot = slot / SLOTS_PER_WORD;
        uint256[] memory inventory = _loadInventoryToMemory(player, storageSlot * SLOTS_PER_WORD, SLOTS_PER_WORD);
        (uint256 itemId,) = getSlotDataFromMemory(inventory, slot, storageSlot * SLOTS_PER_WORD);
        return itemId;
    }

    function slotCounts(address player, uint8 slot) external view returns (uint256) {
        uint8 storageSlot = slot / SLOTS_PER_WORD;
        uint256[] memory inventory = _loadInventoryToMemory(player, storageSlot * SLOTS_PER_WORD, SLOTS_PER_WORD);
        (, uint256 amount) = getSlotDataFromMemory(inventory, slot, storageSlot * SLOTS_PER_WORD);
        return amount;
    }

    function isValidToolForBlock(uint256 toolId, uint8 blockType) public view override returns (bool) {
        uint256 requiredToolId = requiredTool[blockType];
        if (requiredToolId == 0) return true; // No tool required
        
        uint256 toolTypeId = toolId & TOOL_TYPE_MASK;
        
        uint8 required = requiredToolLevel[blockType];
        if (required == 0) {
            // For blocks that need a specific tool but don't care about level (like shears for leaves)
            return toolTypeId == requiredToolId;
        }
        
        // Check if the tool has sufficient level
        if (toolTypeId == MinecraftConstants.DIAMOND_PICKAXE && MinecraftConstants.TOOL_LEVEL_DIAMOND >= required) return true;
        if (toolTypeId == MinecraftConstants.IRON_PICKAXE && MinecraftConstants.TOOL_LEVEL_IRON >= required) return true;
        if (toolTypeId == MinecraftConstants.STONE_PICKAXE && MinecraftConstants.TOOL_LEVEL_STONE >= required) return true;
        if (toolTypeId == MinecraftConstants.WOODEN_PICKAXE && MinecraftConstants.TOOL_LEVEL_WOODEN >= required) return true;
        
        return false;
    }

    function useToolFromSlot(address player, uint8 slot, uint8 blockType) external override onlyCraftingOrOverlay returns (bool) {
        require(slot < MAX_SLOTS, "Invalid slot number");
        
        // Read the slot data
        uint8 storageSlot = slot / SLOTS_PER_WORD;
        uint256[] memory inventory = _loadInventoryToMemory(player, storageSlot * SLOTS_PER_WORD, SLOTS_PER_WORD);
        (uint256 itemId, uint256 amount) = getSlotDataFromMemory(inventory, slot, storageSlot * SLOTS_PER_WORD);
        
        // Check if there's a tool in the slot
        if (amount == 0 || !_isToolItem(itemId)) {
            return false;
        }
        
        // Check if it's a valid tool for the block
        if (!isValidToolForBlock(itemId, blockType)) {
            return false;
        }
        
        // Get and update the durability
        uint16 durability = toolDurability[itemId];
        require(durability > 0, "Tool has no durability");
        
        uint16 newDurability = durability - 1;
        if (newDurability == 0) {
            _burn(player, itemId, 1);
            _setSlotData(player, slot, 0, 0);
        } else {
            toolDurability[itemId] = newDurability;
        }

        return true;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory _itemName = _itemNames[tokenId];

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"', 
                        _itemName,
                        '","id":"',
                        tokenId.toString(),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function loadInventoryToMemory(address player, uint8 startSlot, uint8 slotCount) public view returns (uint256[] memory inventory) {
        return _loadInventoryToMemory(player, startSlot, slotCount);
    }

    // Function to read a specific slot's data
    function getSlotData(address player, uint8 slot) external view returns (uint256 itemId, uint256 amount) {
        require(slot < MAX_SLOTS, "Invalid slot number");
        uint256[] memory inventory = _loadInventoryToMemory(player, slot, 1);
        return getSlotDataFromMemory(inventory, slot, slot);
    }

    function setSelectedSlot(uint8 slot) external override {
        require(slot < MAX_SLOTS, "Invalid slot number");
        address sender = _msgSender();
        selectedSlots[sender] = slot;
        emit SelectedSlotChanged(sender, slot);
    }

    function getSelectedSlot(address player) external view override returns (uint8) {
        return selectedSlots[player];
    }

    function getSelectedSlotItemId(address player) external view returns (uint256) {
        uint8 slot = this.getSelectedSlot(player);
        return this.inventorySlots(player, slot);
    }

    function setUserStatsSystem(address _userStatsSystem) external onlyOwner {
        if (_userStatsSystem == address(0)) revert("Invalid address");
        userStatsSystem = IUserStatsSystem(_userStatsSystem);
    }
}