export const MinecraftConstants = {
  // Block Types
  STONE: 1,
  GRASS: 2,
  DIRT: 3,
  IRON_ORE: 15,
  LEAVES: 18,
  WOOD: 17,
  COBBLESTONE: 4,

  // Crafting Items
  WOOD_PLANKS: 5,
  STICK: 280,
  IRON_INGOT: 265,
  GOLD_INGOT: 266,
  DIAMOND: 264,

  // Tools
  WOODEN_PICKAXE: 270,
  STONE_PICKAXE: 274,
  IRON_PICKAXE: 257,
  DIAMOND_PICKAXE: 278,
  GOLDEN_PICKAXE: 285,
  SHEARS: 359,

  // Tool Durability
  WOODEN_PICKAXE_DURABILITY: 59,
  STONE_PICKAXE_DURABILITY: 131,
  IRON_PICKAXE_DURABILITY: 250,
  DIAMOND_PICKAXE_DURABILITY: 1561,
  GOLDEN_PICKAXE_DURABILITY: 32,

  // Tool Levels
  TOOL_LEVEL_NONE: 0,
  TOOL_LEVEL_WOODEN: 1,
  TOOL_LEVEL_STONE: 2,
  TOOL_LEVEL_IRON: 3,
  TOOL_LEVEL_DIAMOND: 4,
  TOOL_LEVEL_GOLDEN: 5,
} as const;

// Export types for TypeScript
export type BlockType = typeof MinecraftConstants[keyof typeof MinecraftConstants];
export type ToolType = typeof MinecraftConstants.WOODEN_PICKAXE | 
                      typeof MinecraftConstants.STONE_PICKAXE | 
                      typeof MinecraftConstants.IRON_PICKAXE | 
                      typeof MinecraftConstants.DIAMOND_PICKAXE | 
                      typeof MinecraftConstants.GOLDEN_PICKAXE; 