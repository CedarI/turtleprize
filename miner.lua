---------------------------------------------------------------------
-- SECTION 1: CONFIGURATION
---------------------------------------------------------------------

-- JUNK ITEMS: Any item in this list will be dropped.
local JUNK_ITEMS = {
  -- Overworld junk
  ["minecraft:stone"] = true, ["minecraft:cobblestone"] = true, ["minecraft:dirt"] = true,
  ["minecraft:gravel"] = true, ["minecraft:sand"] = true, ["minecraft:andesite"] = true,
  ["minecraft:diorite"] = true, ["minecraft:granite"] = true, ["minecraft:deepslate"] = true,
  ["minecraft:cobbled_deepslate"] = true, ["minecraft:tuff"] = true, ["minecraft:calcite"] = true,
  ["minecraft:flint"] = true,
  
  -- Nether junk (comprehensive list)
  ["minecraft:netherrack"] = true, ["minecraft:soul_sand"] = true, ["minecraft:soul_soil"] = true,
  ["minecraft:blackstone"] = true, ["minecraft:basalt"] = true, ["minecraft:smooth_basalt"] = true,
  ["minecraft:polished_blackstone"] = true, ["minecraft:warped_nylium"] = true, ["minecraft:crimson_nylium"] = true,
  ["minecraft:magma_block"] = true, ["minecraft:nether_bricks"] = true, ["minecraft:red_nether_bricks"] = true,
  ["minecraft:warped_stem"] = true, ["minecraft:crimson_stem"] = true, ["minecraft:warped_hyphae"] = true,
  ["minecraft:crimson_hyphae"] = true, ["minecraft:shroomlight"] = true, ["minecraft:nether_wart_block"] = true,
  ["minecraft:warped_wart_block"] = true, ["minecraft:bone_block"] = true, ["minecraft:glowstone"] = true,
  
  -- Additional nether variations and modded equivalents
  ["minecraft:polished_basalt"] = true, ["minecraft:chiseled_nether_bricks"] = true,
  ["minecraft:cracked_nether_bricks"] = true, ["minecraft:nether_brick"] = true,
}

-- ORE PRIORITY: This list defines valuable ores worth mining
local ORE_PRIORITY = {
  -- ATM10 Special Ores (Highest Priority)
  ["allthemodium:allthemodium_ore"] = true, ["allthemodium:vibranium_ore"] = true, ["allthemodium:unobtainium_ore"] = true,
  
  -- Vanilla High-Value Ores
  ["minecraft:diamond_ore"] = true, ["minecraft:deepslate_diamond_ore"] = true, ["minecraft:ancient_debris"] = true,
  ["minecraft:emerald_ore"] = true, ["minecraft:deepslate_emerald_ore"] = true,
  
  -- Nether Ores (Vanilla)
  ["minecraft:nether_gold_ore"] = true, ["minecraft:nether_quartz_ore"] = true, 
  ["minecraft:gilded_blackstone"] = true,
  
  -- Standard Valuable Ores
  ["minecraft:lapis_ore"] = true, ["minecraft:deepslate_lapis_ore"] = true, 
  ["minecraft:gold_ore"] = true, ["minecraft:deepslate_gold_ore"] = true,
  ["minecraft:iron_ore"] = true, ["minecraft:deepslate_iron_ore"] = true, 
  ["minecraft:copper_ore"] = true, ["minecraft:deepslate_copper_ore"] = true, 
  ["minecraft:redstone_ore"] = true, ["minecraft:deepslate_redstone_ore"] = true,
  ["minecraft:coal_ore"] = true, ["minecraft:deepslate_coal_ore"] = true,
  
  -- Mekanism Ores (Overworld + Nether variants)
  ["mekanism:osmium_ore"] = true, ["mekanism:deepslate_osmium_ore"] = true, 
  ["mekanism:uranium_ore"] = true, ["mekanism:deepslate_uranium_ore"] = true, 
  ["mekanism:fluorite_ore"] = true, ["mekanism:deepslate_fluorite_ore"] = true,
  ["mekanism:tin_ore"] = true, ["mekanism:deepslate_tin_ore"] = true, 
  ["mekanism:lead_ore"] = true, ["mekanism:deepslate_lead_ore"] = true,
  
  -- Thermal Expansion Ores
  ["thermal:tin_ore"] = true, ["thermal:deepslate_tin_ore"] = true,
  ["thermal:lead_ore"] = true, ["thermal:deepslate_lead_ore"] = true,
  ["thermal:silver_ore"] = true, ["thermal:deepslate_silver_ore"] = true,
  ["thermal:nickel_ore"] = true, ["thermal:deepslate_nickel_ore"] = true,
  ["thermal:cinnabar_ore"] = true, ["thermal:deepslate_cinnabar_ore"] = true, 
  ["thermal:niter_ore"] = true, ["thermal:deepslate_niter_ore"] = true, 
  ["thermal:sulfur_ore"] = true, ["thermal:deepslate_sulfur_ore"] = true,
  ["thermal:apatite_ore"] = true, ["thermal:deepslate_apatite_ore"] = true,
  
  -- Create Ores
  ["create:zinc_ore"] = true, ["create:deepslate_zinc_ore"] = true,
  
  -- Applied Energistics Ores
  ["ae2:certus_quartz_ore"] = true, ["ae2:deepslate_certus_quartz_ore"] = true,
  
  -- AllTheOres Mod Ores
  ["alltheores:tin_ore"] = true, ["alltheores:lead_ore"] = true, ["alltheores:silver_ore"] = true,
  ["alltheores:nickel_ore"] = true, ["alltheores:aluminum_ore"] = true, ["alltheores:zinc_ore"] = true,
  
  -- Potential Nether variants (if they exist in ATM10)
  ["thermal:nether_tin_ore"] = true, ["thermal:nether_lead_ore"] = true, ["thermal:nether_silver_ore"] = true,
  ["thermal:nether_nickel_ore"] = true, ["thermal:nether_cinnabar_ore"] = true, ["thermal:nether_sulfur_ore"] = true,
  ["thermal:nether_apatite_ore"] = true, ["thermal:nether_niter_ore"] = true,
  ["mekanism:nether_osmium_ore"] = true, ["mekanism:nether_uranium_ore"] = true, ["mekanism:nether_fluorite_ore"] = true,
  ["mekanism:nether_tin_ore"] = true, ["mekanism:nether_lead_ore"] = true,
  ["alltheores:nether_tin_ore"] = true, ["alltheores:nether_lead_ore"] = true, ["alltheores:nether_silver_ore"] = true,
  ["alltheores:nether_nickel_ore"] = true, ["alltheores:nether_aluminum_ore"] = true, ["alltheores:nether_zinc_ore"] = true,
  ["create:nether_zinc_ore"] = true, ["ae2:nether_certus_quartz_ore"] = true,
}

-- BEHAVIOR SETTINGS
local HOME_BASE_ID = 2 -- IMPORTANT: SET THIS TO YOUR MONITOR COMPUTER'S ID
local COMMAND_PROTOCOL = "turtle_command"
local FUEL_LOW_THRESHOLD = 500
local STATE_FILE = "miner_state.json"
local FUEL_SLOT = 1
local SAFE_SLOT = 16

-- NEW: Mining strategy settings
local MINING_STRATEGY = "branch" -- Options: "shaft", "branch", "hybrid"
-- Overworld levels (for diamond, deepslate ores, etc.)
local OVERWORLD_BRANCH_LEVELS = {-54, -50, -46, -42, -38, -34, -30, -26, -22, -18, -14, -10, -6}
-- Nether levels (for ancient debris, nether gold, quartz, etc.)
local NETHER_BRANCH_LEVELS = {8, 10, 12, 14, 16, 18, 20, 22, 32, 48, 64, 80, 96}
local BRANCH_LEVELS = OVERWORLD_BRANCH_LEVELS -- Default to overworld (can be changed in-game)
local TUNNEL_SPACING = 3 -- Spacing between parallel tunnels
local VEIN_FOLLOW_DEPTH = 3 -- How far to follow ore veins

-- ESSENTIAL ITEMS: Items the turtle must keep
local ESSENTIAL_ITEMS = {
  ["minecraft:bucket"] = true,
  ["minecraft:lava_bucket"] = true,
  ["minecraft:ender_chest"] = true,
}

-- FUEL TYPES: Valid fuel items the turtle can use
local FUEL_TYPES = {
  ["minecraft:coal"] = 80,
  ["minecraft:charcoal"] = 80,
  ["minecraft:coal_block"] = 800,
  ["minecraft:blaze_rod"] = 120,
  ["minecraft:lava_bucket"] = 1000,
  ["minecraft:stick"] = 5,
  ["minecraft:wooden_planks"] = 15,
  ["minecraft:oak_planks"] = 15,
  ["minecraft:spruce_planks"] = 15,
  ["minecraft:birch_planks"] = 15,
  ["minecraft:jungle_planks"] = 15,
  ["minecraft:acacia_planks"] = 15,
  ["minecraft:dark_oak_planks"] = 15,
  ["minecraft:crimson_planks"] = 15,
  ["minecraft:warped_planks"] = 15,
}

---------------------------------------------------------------------
-- COLLECT COMMAND LINE ARGUMENTS (MOVED TO TOP)
---------------------------------------------------------------------

-- Safely collect command line arguments 
local args = {...}
if not args then args = {} end

-- Safety check for turtle environment
if not turtle then
  print("ERROR: This program requires a turtle!")
  print("Please run this on a ComputerCraft turtle.")
  return
end

---------------------------------------------------------------------
-- DEBUG COMMANDS (now that args is defined)
---------------------------------------------------------------------

-- DEBUG: Inventory inspection command
if args[1] == "inventory" then
  print("=== INVENTORY INSPECTION ===")
  print("Current inventory contents:")
  
  local total_items = 0
  local junk_items = 0
  local valuable_items = 0
  
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if item then
      local is_junk = JUNK_ITEMS[item.name] or false
      local is_essential = ESSENTIAL_ITEMS[item.name] or false
      local is_fuel = FUEL_TYPES[item.name] or false
      local is_ore = ORE_PRIORITY[item.name] or false
      
      local item_type = "unknown"
      if is_essential then
        item_type = "ESSENTIAL"
      elseif is_fuel then
        item_type = "FUEL"
      elseif is_ore then
        item_type = "ORE"
        valuable_items = valuable_items + item.count
      elseif is_junk then
        item_type = "JUNK"
        junk_items = junk_items + item.count
      else
        item_type = "OTHER"
        valuable_items = valuable_items + item.count
      end
      
      print(string.format("Slot %2d: %3dx %-30s [%s]", i, item.count, item.name, item_type))
      total_items = total_items + item.count
    else
      print(string.format("Slot %2d: empty", i))
    end
  end
  
  print("========================")
  print("Summary:")
  print("  Total items: " .. total_items)
  print("  Junk items: " .. junk_items .. " (should be dropped!)")
  print("  Valuable items: " .. valuable_items)
  print("  Empty slots: " .. (16 - turtle.getItemCount()))
  
  if junk_items > 0 then
    print("")
    print("PROBLEM: Junk items detected!")
    print("Running junk cleanup now...")
    -- manageJunk() -- We'll need to define this function later
    print("Junk cleanup would run here.")
  else
    print("✓ No junk items found")
  end
  
  print("=== INSPECTION COMPLETE ===")
  return
end

-- DEBUG: Dimension switch command
if args[1] == "dimension" then
  if not args[2] or (args[2] ~= "nether" and args[2] ~= "overworld") then
    print("Usage: miner dimension <nether|overworld>")
    return
  end
  
  local new_dimension = args[2]
  print("Dimension switch command received: " .. new_dimension)
  print("This would switch mining mode to " .. new_dimension)
  return
end

-- DEBUG: Recall system test command
if args[1] == "recalltest" then
  print("=== RECALL SYSTEM TEST ===")
  print("Computer ID: " .. os.getComputerID())
  print("Home base ID: " .. HOME_BASE_ID)
  print("Command protocol: " .. COMMAND_PROTOCOL)
  print("This would test the recall system.")
  print("=== RECALL TEST COMPLETE ===")
  return
end

---------------------------------------------------------------------
-- SECTION 2: STATE, POSITIONING, & COMMS
---------------------------------------------------------------------

local state = {}
local comms = {}
local recall_activated = false

-- Enhanced inventory summary
local function getInventorySummary()
  local summary = {}
  for i = 2, 16 do
    local item = turtle.getItemDetail(i)
    if item and not JUNK_ITEMS[item.name] and not ESSENTIAL_ITEMS[item.name] then
      local simple_name = string.gsub(item.name, "minecraft:", "")
      simple_name = string.gsub(simple_name, "allthemodium:", "")
      simple_name = string.gsub(simple_name, "mekanism:", "")
      simple_name = string.gsub(simple_name, "thermal:", "")
      simple_name = string.gsub(simple_name, "create:", "")
      simple_name = string.gsub(simple_name, "ae2:", "")
      simple_name = string.gsub(simple_name, "alltheores:", "")
      summary[simple_name] = (summary[simple_name] or 0) + item.count
    end
  end
  return summary
end

-- Rest of the code would continue here...
-- (I'm showing just the key fix - the args definition moved to the top)

---------------------------------------------------------------------
-- MAIN PROGRAM ENTRY POINT
---------------------------------------------------------------------

function main(args)
  -- The main function now receives args that are already defined
  print("Starting main program with args...")
  -- Rest of main function implementation
end

-- Now call main with the already-defined args
main(args)