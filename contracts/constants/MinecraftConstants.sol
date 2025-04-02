// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Constants for Minecraft block and item IDs
library MinecraftConstants {
    // Block IDs
    uint8 constant AIR = 0;
    uint8 constant STONE = 1;
    uint8 constant GRASS = 2;
    uint8 constant DIRT = 3;
    uint8 constant COBBLESTONE = 4;
    uint8 constant WOOD_PLANKS = 5;
    uint8 constant BEDROCK = 7;
    uint8 constant FLOWING_WATER = 8;
    uint8 constant STILL_WATER = 9;
    uint8 constant FLOWING_LAVA = 10;
    uint8 constant STILL_LAVA = 11;
    uint8 constant SAND = 12;
    uint8 constant GRAVEL = 13;
    uint8 constant GOLD_ORE = 14;
    uint8 constant IRON_ORE = 15;
    uint8 constant COAL_ORE = 16;
    uint8 constant WOOD = 17;
    uint8 constant LEAVES = 18;
    uint8 constant SPONGE = 19;
    uint8 constant GLASS = 20;
    uint8 constant LAPIS_LAZULI_ORE = 21;

    
    uint8 constant DIAMOND_ORE = 56;
    uint8 constant REDSTONE_ORE = 73;
    uint8 constant SNOW = 78;
    uint8 constant ICE = 79;
    uint8 constant CLAY = 82;
    uint8 constant EMERALD_ORE = 129;

    // Basic Materials
    uint16 constant STICK = 280;
    uint16 constant IRON_INGOT = 265;
    uint16 constant GOLD_INGOT = 266;
    uint16 constant DIAMOND = 264;
    uint16 constant COAL = 263;

    // Tool IDs (from Minecraft data values)
    uint16 constant WOODEN_PICKAXE = 270;
    uint16 constant STONE_PICKAXE = 274;
    uint16 constant IRON_PICKAXE = 257;
    uint16 constant DIAMOND_PICKAXE = 278;
    uint16 constant GOLDEN_PICKAXE = 285;
    uint16 constant SHEARS = 359;

    // Tool durability values
    uint16 constant WOODEN_PICKAXE_DURABILITY = 10; // 59
    uint16 constant STONE_PICKAXE_DURABILITY = 131;
    uint16 constant IRON_PICKAXE_DURABILITY = 250;
    uint16 constant DIAMOND_PICKAXE_DURABILITY = 1561;
    uint16 constant GOLDEN_PICKAXE_DURABILITY = 32;
    uint16 constant SHEARS_DURABILITY = 238;

    // Tool levels (0 = no tool, 1 = wooden, 2 = stone, 3 = iron, 4 = diamond)
    uint8 constant TOOL_LEVEL_NONE = 0;
    uint8 constant TOOL_LEVEL_WOODEN = 1;
    uint8 constant TOOL_LEVEL_STONE = 2;
    uint8 constant TOOL_LEVEL_IRON = 3;
    uint8 constant TOOL_LEVEL_DIAMOND = 4;
} 