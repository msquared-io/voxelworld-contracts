// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/systems/InventorySystem.sol";
import "../../contracts/systems/CraftingSystem.sol";
import "../../contracts/SessionsManager.sol";
import "../../contracts/interfaces/ICraftingSystem.sol";
import "../../contracts/systems/OverlaySystem.sol";
import "../../contracts/systems/ChunkSystem.sol";
import "../../contracts/systems/UserStatsSystem.sol";
import "../../contracts/systems/PlayerSystem.sol";
import "../../contracts/constants/MinecraftConstants.sol";

contract TestHelper is Test {
    using MinecraftConstants for uint8;
    using MinecraftConstants for uint16;

    // Events from ICraftingSystem
    event ItemCrafted(
        address indexed player,
        uint256 outputItemId,
        uint256[] inputItemIds,
        uint256[] inputAmounts
    );

    // Constants from MinecraftConstants.ts
    uint256 constant STONE = 1;
    uint256 constant GRASS = 2;
    uint256 constant DIRT = 3;
    uint256 constant IRON_ORE = 15;
    uint256 constant DIAMOND_ORE = 56;
    uint256 constant LEAVES = 18;
    uint256 constant WOOD = 17;
    uint256 constant COBBLESTONE = 4;

    // Crafting Items
    uint256 constant WOOD_PLANKS = 5;
    uint256 constant STICK = 280;
    uint256 constant IRON_INGOT = 265;
    uint256 constant GOLD_INGOT = 266;
    uint256 constant DIAMOND = 264;

    // Tools
    uint256 constant WOODEN_PICKAXE = 270;
    uint256 constant STONE_PICKAXE = 274;
    uint256 constant IRON_PICKAXE = 257;
    uint256 constant DIAMOND_PICKAXE = 278;
    uint256 constant GOLDEN_PICKAXE = 285;
    uint256 constant SHEARS = 359;

    // Tool Levels
    uint8 constant TOOL_LEVEL_NONE = 0;
    uint8 constant TOOL_LEVEL_WOODEN = 1;
    uint8 constant TOOL_LEVEL_STONE = 2;
    uint8 constant TOOL_LEVEL_IRON = 3;
    uint8 constant TOOL_LEVEL_DIAMOND = 4;
    uint8 constant TOOL_LEVEL_GOLDEN = 5;

    // Test accounts
    address constant OWNER = address(0x1);
    address constant PLAYER = address(0x2);

    // Contract instances
    SessionsManager internal sessionManager;
    InventorySystem internal inventorySystem;
    CraftingSystem internal craftingSystem;
    ChunkSystem internal chunkSystem;
    OverlaySystem internal overlaySystem;
    UserStatsSystem internal userStatsSystem;
    PlayerSystem internal playerSystem;

    function setUp() public virtual {
        vm.startPrank(OWNER);
        
        // Deploy session manager
        sessionManager = new SessionsManager();
        
        // Deploy inventory system
        inventorySystem = new InventorySystem(address(sessionManager));
        
        // Deploy crafting system
        craftingSystem = new CraftingSystem(address(sessionManager), address(inventorySystem));
        
        // Deploy chunk system
        chunkSystem = new ChunkSystem(address(sessionManager));
        
        // Deploy overlay system
        overlaySystem = new OverlaySystem(address(sessionManager), address(chunkSystem), address(inventorySystem));
        
        // Deploy player system
        playerSystem = new PlayerSystem(address(sessionManager));
        
        // Deploy user stats system with all required systems
        userStatsSystem = new UserStatsSystem(
            address(sessionManager),
            address(overlaySystem),
            address(playerSystem),
            address(craftingSystem),
            address(inventorySystem),
            address(playerSystem)
        );
        
        // Set up system references
        overlaySystem.setUserStatsSystem(address(userStatsSystem));
        playerSystem.setUserStatsSystem(address(userStatsSystem));
        craftingSystem.setUserStatsSystem(address(userStatsSystem));
        
        // Set up user stats system in inventory system
        inventorySystem.setUserStatsSystem(address(userStatsSystem));
        
        vm.stopPrank();
    }
} 