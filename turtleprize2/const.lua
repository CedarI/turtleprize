-- Constants and configuration for turtleprize2
-- Shared by turtle, central computer, and pocket programs

local M = {}

-- Valuable ores table: true for ores we want to mine
M.valuableOres = {
  ["allthemodium:allthemodium_ore"] = true,
  ["allthemodium:vibranium_ore"] = true,
  ["allthemodium:unobtainium_ore"] = true,
  ["minecraft:diamond_ore"] = true,
  ["minecraft:deepslate_diamond_ore"] = true,
  ["minecraft:emerald_ore"] = true,
  ["minecraft:ancient_debris"] = true,
  ["minecraft:nether_quartz_ore"] = true,
}

-- Network protocol name
M.protocol = "turtleprize2"

-- Rednet message types
M.msg = {
  status = "status",      -- turtle -> controller, inventory and position
  recall = "recall",      -- controller -> turtle, return to base
}

return M
