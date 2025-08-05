-- SAFE BASE APPROACH: Always approach base from underground to avoid destroying structures
local function safeGoToBase(status_msg)
  local msg = status_msg or "Returning to base safely"
  comms.sendStatus(msg .. " (underground approach)")
  
  -- Step 1: Go down to safe underground level first (Y=-5 or lower)
  local safe_underground_y = -5
  
  comms.sendStatus("Descending to safe underground level...")
  while state.y > safe_underground_y and not recall_activated do
    if not digAndDown() then 
      state.task = "STUCK"
      return false 
    end
    if state.statistics.distance_traveled % 10 == 0 then 
      comms.sendStatus("Descending safely: Y=" .. state.y) 
    end
  end
  
  -- Step 2: Navigate to base underground (0, safe_y, 0)
  comms.sendStatus("Navigating to base underground...")
  
  -- Z movement underground
  if state.z > 0 then
    if not pos_lib.turnTo(0) then state.task = "STUCK"; return false end
    while state.z > 0 and not recall_activated do
      if not digAndMoveForward() then state.task = "STUCK"; return false end
      if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus("Underground navigation: Z=" .. state.z) end
    end
  elseif state.z < 0 then
    if not pos_lib.turnTo(2) then state.task = "STUCK"; return false end
    while state.z < 0 and not recall_activated do
      if not digAndMoveForward() then state.task = "STUCK"; return false end
      if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus("Underground navigation: Z=" .. state.z) end
    end
  end
  
  -- X movement underground
  if state.x < 0 then
    if not pos_lib.turnTo(1) then state.task = "STUCK"; return false end
    while state.x < 0 and not recall_activated do
      if not digAndMoveForward() then state.task = "STUCK"; return false end
      if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus("Underground navigation: X=" .. state.x) end
    end
  elseif state.x > 0 then
    if not pos_lib.turnTo(3) then state.task = "STUCK"; return false end
    while state.x > 0 and not recall_activated do
      if not digAndMoveForward() then state.task = "STUCK"; return false end
      if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus("Underground navigation: X=" .. state.x) end
    end
  end
  
  -- Step 3: Now we're at (0, safe_y, 0) - safely ascend to surface
  comms.sendStatus("Safely ascending to base surface...")
  while state.y < 0 and not recall_activated do
    if not digAndUp() then state.task = "STUCK"; return false end
    if state.statistics.distance_traveled % 5 == 0 then 
      comms.sendStatus("Ascending safely: Y=" .. state.y) 
    end
  end
  
  comms.sendStatus("Safely arrived at base!")
  return not recall_activated
end

-- SAFE BASE DEPARTURE: Always leave base by going underground first
local function safeLeaveBase(target_x, target_y, target_z, status_msg)
  local msg = status_msg or "Leaving base safely"
  comms.sendStatus(msg .. " (underground departure)")
  
  -- Step 1: Go down to safe underground level (Y=-5 or lower)
  local safe_underground_y = -5
  
  comms.sendStatus("Descending from base to safe level...")
  while state.y > safe_underground_y and not recall_activated do
    if not digAndDown() then 
      state.task = "STUCK"
      return false 
    end
    if state.statistics.distance_traveled % 10 == 0 then 
      comms.sendStatus("Safe descent: Y=" .. state.y) 
    end
  end
  
  -- Step 2: Use normal pathfinding once safely underground
  comms.sendStatus("Navigating safely to destination...")
  return pos_lib.goTo(target_x, target_y, target_z, status_msg)
end  -- DEBUG: Inventory inspection command
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
      manageJunk()
      print("Junk cleanup complete.")
    else
      print("✓ No junk items found")
    end
    
    print("=== INSPECTION COMPLETE ===")
    return
  end  -- DEBUG: Dimension switch command
  if args[1] == "dimension" then
    if not args[2] or (args[2] ~= "nether" and args[2] ~= "overworld") then
      print("Usage: miner dimension <nether|overworld>")
      print("Current dimension: " .. (state.dimension or "unknown"))
      return
    end
    
    -- Load current state
    loadState()
    
    local new_dimension = args[2]
    local old_dimension = state.dimension or "unknown"
    
    -- Update dimension and branch levels
    state.dimension = new_dimension
    if new_dimension == "nether" then
      BRANCH_LEVELS = NETHER_BRANCH_LEVELS
    else
      BRANCH_LEVELS = OVERWORLD_BRANCH_LEVELS
    end
    
    -- Clear surface data to force re-detection
    state.surfaceY = nil
    
    saveState()
    
    print("Dimension switched: " .. old_dimension .. " -> " .. new_dimension)
    print("Branch levels updated for " .. new_dimension .. " mining")
    print("Surface level will be re-detected on next run")
    
    return
  end-- NEW: Auto-detect dimension based on surrounding blocks
local function detectDimension()
  local nether_blocks = 0
  local overworld_blocks = 0
  
  -- Check blocks in multiple directions
  local check_directions = {
    function() return turtle.inspect() end,
    function() return turtle.inspectUp() end,
    function() return turtle.inspectDown() end
  }
  
  for _, check_func in ipairs(check_directions) do
    local success, data = check_func()
    if success and data and data.name then
      if data.name == "minecraft:netherrack" or data.name == "minecraft:basalt" or 
         data.name == "minecraft:blackstone" or data.name == "minecraft:soul_sand" or
         data.name == "minecraft:soul_soil" or data.name:find("nether") then
        nether_blocks = nether_blocks + 1
      elseif data.name == "minecraft:stone" or data.name == "minecraft:deepslate" or
             data.name == "minecraft:dirt" or data.name == "minecraft:andesite" or
             data.name == "minecraft:diorite" or data.name == "minecraft:granite" then
        overworld_blocks = overworld_blocks + 1
      end
    end
  end
  
  -- Turn around to check more directions
  for turn = 1, 4 do
    turtle.turnRight()
    local success, data = turtle.inspect()
    if success and data and data.name then
      if data.name == "minecraft:netherrack" or data.name == "minecraft:basalt" or 
         data.name == "minecraft:blackstone" or data.name:find("nether") then
        nether_blocks = nether_blocks + 1
      elseif data.name == "minecraft:stone" or data.name == "minecraft:deepslate" or
             data.name == "minecraft:dirt" then
        overworld_blocks = overworld_blocks + 1
      end
    end
  end
  
  if nether_blocks > overworld_blocks then
    return "nether"
  else
    return "overworld"
  end
end  -- DEBUG: Recall system test command
  if args[1] == "recalltest" then
    print("=== RECALL SYSTEM TEST ===")
    print("Computer ID: " .. os.getComputerID())
    print("Home base ID: " .. HOME_BASE_ID)
    print("Command protocol: " .. COMMAND_PROTOCOL)
    
    comms.init()
    
    print("Starting recall listener test...")
    print("Send recall command from monitor to test")
    print("Waiting 10 seconds for recall command...")
    
    local test_timer = os.startTimer(10)
    
    while true do
      local event, p1, p2, p3 = os.pullEvent()
      
      if event == "rednet_message" then
        local sender_id, message, protocol = p1, p2, p3
        print("Received message:")
        print("  From: " .. sender_id)
        print("  Protocol: " .. (protocol or "none"))
        print("  Message: " .. (message or "none"))
        
        if protocol == COMMAND_PROTOCOL and message == "recall" then
          print("SUCCESS: Recall command received correctly!")
          recall_activated = true
          break
        else
          print("Not a recall command, continuing to listen...")
        end
      elseif event == "timer" and p1 == test_timer then
        print("TIMEOUT: No recall command received in 10 seconds")
        print("Check:")
        print("1. Is monitor computer running and sending to ID " .. os.getComputerID() .. "?")
        print("2. Are both computers within wireless range?")
        print("3. Is HOME_BASE_ID set correctly in miner.lua?")
        break
      end
    end
    
    if recall_activated then
      print("Recall flag set successfully!")
      print("Turtle would now stop mining and return home.")
    end
    
    print("=== RECALL TEST COMPLETE ===")
    return
  end---------------------------------------------------------------------
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

-- Enhanced fuel management functions (moved up to fix call order)

-- Find fuel in inventory and move it to fuel slot
local function consolidateFuel()
  local fuel_slot_item = turtle.getItemDetail(FUEL_SLOT)
  
  -- If fuel slot is empty, find fuel elsewhere
  if not fuel_slot_item then
    for i = 2, 16 do
      local item = turtle.getItemDetail(i)
      if item and FUEL_TYPES[item.name] and not ESSENTIAL_ITEMS[item.name] then
        turtle.select(i)
        turtle.transferTo(FUEL_SLOT, item.count)
        print("Moved " .. item.name .. " to fuel slot")
        break
      end
    end
  else
    -- If fuel slot has fuel, consolidate more of the same type
    for i = 2, 16 do
      local item = turtle.getItemDetail(i)
      if item and item.name == fuel_slot_item.name and not ESSENTIAL_ITEMS[item.name] then
        turtle.select(i)
        turtle.transferTo(FUEL_SLOT, item.count)
      end
    end
  end
  
  turtle.select(SAFE_SLOT)
end

-- NEW: Check if turtle has essential equipment for autostart
local function hasEssentialEquipment()
  -- Check for bucket (absolutely required)
  local has_bucket = false
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if item and (item.name == "minecraft:bucket" or item.name == "minecraft:lava_bucket") then
      has_bucket = true
      break
    end
  end
  
  -- Check for any fuel
  local has_fuel = false
  for i = 1, 16 do
    local item = turtle.getItemDetail(i)
    if item and FUEL_TYPES[item.name] then
      has_fuel = true
      break
    end
  end
  
  -- Check if inventory is completely empty
  local inventory_empty = true
  for i = 1, 16 do
    if turtle.getItemCount(i) > 0 then
      inventory_empty = false
      break
    end
  end
  
  return has_bucket, has_fuel, inventory_empty
end

-- Enhanced pre-flight check with strict essential equipment requirements
local function preFlightCheck(allow_autostart)
  local issues = {}
  local warnings = {}
  local fuel_level = turtle.getFuelLevel()
  
  -- Check essential equipment first
  local has_bucket, has_fuel, inventory_empty = hasEssentialEquipment()
  
  -- CRITICAL: Bucket is absolutely required
  if not has_bucket then
    table.insert(issues, "CRITICAL: No bucket found! Bucket is required for lava refueling.")
  end
  
  -- If autostarting, be more strict about equipment
  if allow_autostart then
    if inventory_empty then
      table.insert(issues, "AUTOSTART BLOCKED: Inventory is empty. Turtle needs proper equipment.")
    end
    
    if not has_fuel then
      table.insert(issues, "AUTOSTART BLOCKED: No fuel found in inventory.")
    end
    
    -- More strict fuel level check for autostart
    if type(fuel_level) == "number" and fuel_level < 1000 then
      table.insert(issues, "AUTOSTART BLOCKED: Fuel too low (" .. fuel_level .. "). Need 1000+ for autostart.")
    end
  else
    -- Manual start - more lenient checks
    if type(fuel_level) == "number" and fuel_level < 1000 then
      table.insert(warnings, "Low fuel: " .. fuel_level .. " (recommend 1000+)")
    end
    
    if not has_fuel then
      table.insert(warnings, "No fuel found in inventory")
    end
  end
  
  -- Show fuel inventory if available
  if has_fuel then
    local total_fuel_items = 0
    local fuel_types_found = {}
    for i = 1, 16 do
      local item = turtle.getItemDetail(i)
      if item and FUEL_TYPES[item.name] then
        total_fuel_items = total_fuel_items + item.count
        fuel_types_found[item.name] = (fuel_types_found[item.name] or 0) + item.count
      end
    end
    
    if total_fuel_items > 0 then
      print("Fuel inventory:")
      for fuel_name, count in pairs(fuel_types_found) do
        local simple_name = string.gsub(fuel_name, "minecraft:", "")
        local fuel_value = FUEL_TYPES[fuel_name] * count
        print("  " .. count .. "x " .. simple_name .. " (" .. fuel_value .. " fuel units)")
      end
    end
  end
  
  -- Report issues and warnings
  if #issues > 0 then
    print("EQUIPMENT CHECK FAILED:")
    for _, issue in ipairs(issues) do
      print("- " .. issue)
    end
    
    if allow_autostart then
      print("\nAUTOSTART PREVENTED!")
      print("This prevents accidental startup when turtle is improperly equipped.")
      print("To fix:")
      print("1. Add a bucket (empty or lava bucket)")
      print("2. Add fuel (coal, charcoal, coal blocks, etc.)")
      print("3. Ensure fuel level is 1000+")
      print("\nThen restart the program.")
      return false
    end
  end
  
  if #warnings > 0 then
    print("PRE-FLIGHT CHECK WARNINGS:")
    for _, warning in ipairs(warnings) do
      print("- " .. warning)
    end
  end
  
  if (#issues > 0 or #warnings > 0) and not allow_autostart then
    print("\nFuel Info: Coal and charcoal work equally well!")
    print("Valid fuel types: coal, charcoal, coal blocks, lava buckets, wood items")
    if #issues > 0 then
      print("Continue anyway? (y/n)")
      local input = read()
      if string.lower(input) ~= "y" and string.lower(input) ~= "yes" then
        print("Mission aborted. Please address issues and restart.")
        return false
      end
    end
  elseif #issues == 0 and #warnings == 0 then
    print("Pre-flight check passed!")
  end
  
  -- Consolidate fuel before starting
  if has_fuel then
    consolidateFuel()
  end
  
  return true
end

function comms.init()
  if HOME_BASE_ID > 0 then
    local modem = peripheral.find("modem", function(_, p) return p.isWireless() end)
    if modem then
      rednet.open(peripheral.getName(modem))
      print("Comms online.")
    else
      print("Warning: No wireless modem found for monitoring.")
      HOME_BASE_ID = 0
    end
  end
end

function comms.sendStatus(status_msg)
  if HOME_BASE_ID > 0 then
    state.statusMessage = status_msg
    state.inventory = getInventorySummary()
    state.fuelLevel = turtle.getFuelLevel()
    local payload = textutils.serializeJSON(state)
    rednet.send(HOME_BASE_ID, payload, "turtle_status")
  end
end

local function saveState()
  local file = fs.open(STATE_FILE, "w")
  if file then file.write(textutils.serializeJSON(state)); file.close() end
end

local function loadState()
  if fs.exists(STATE_FILE) then
    local file = fs.open(STATE_FILE, "r")
    if file then
      local data = file.readAll(); file.close()
      local success, loaded = pcall(textutils.unserializeJSON, data)
      if success and type(loaded) == "table" then state = loaded; return true end
    end
  end
  return false
end

-- Enhanced initialization with strategy selection and dimension detection
local function init(args)
  local surface_override = nil
  local dimension = "overworld" -- Default dimension
  
  if args[4] and tonumber(args[4]) then
    surface_override = tonumber(args[4])
  elseif args[4] and (args[4] == "nether" or args[4] == "overworld") then
    dimension = args[4]
  end
  
  if args[5] and (args[5] == "nether" or args[5] == "overworld") then
    dimension = args[5]
  end
  
  -- Set appropriate branch levels based on dimension
  if dimension == "nether" then
    BRANCH_LEVELS = NETHER_BRANCH_LEVELS
    print("Nether mining mode activated!")
    print("Optimized for: Ancient Debris (Y=8-22), Nether Gold, Quartz")
  else
    BRANCH_LEVELS = OVERWORLD_BRANCH_LEVELS
    print("Overworld mining mode activated!")
    print("Optimized for: Diamonds, Deepslate ores, standard minerals")
  end
  
  state = {
    x = 0, y = 0, z = 0, facing = 0, task = "STARTING",
    width = tonumber(args[1]) or 32, length = tonumber(args[2]) or 64,
    strategy = args[3] or MINING_STRATEGY,
    dimension = dimension,
    progress = { x = 0, z = 0, level_index = 1 },
    surfaceY = surface_override,
    inventory = {},
    statistics = { blocks_mined = 0, ores_found = 0, distance_traveled = 0 }
  }
  saveState()
end

---------------------------------------------------------------------
-- SECTION 3: ENHANCED POSITIONING & MOVEMENT
---------------------------------------------------------------------

local pos_lib = {}

-- Basic movement functions (same as before but with distance tracking)
function pos_lib.forward()
  saveState(); local s, r = turtle.forward()
  if s then
    if state.facing == 0 then state.z = state.z - 1
    elseif state.facing == 1 then state.x = state.x + 1
    elseif state.facing == 2 then state.z = state.z + 1
    elseif state.facing == 3 then state.x = state.x - 1 end
    state.statistics.distance_traveled = state.statistics.distance_traveled + 1
  end; return s, r
end

function pos_lib.back()
  saveState(); local s, r = turtle.back()
  if s then
    if state.facing == 0 then state.z = state.z + 1
    elseif state.facing == 1 then state.x = state.x - 1
    elseif state.facing == 2 then state.z = state.z - 1
    elseif state.facing == 3 then state.x = state.x + 1 end
    state.statistics.distance_traveled = state.statistics.distance_traveled + 1
  end; return s, r
end

function pos_lib.up()
  saveState(); local s, r = turtle.up()
  if s then 
    state.y = state.y + 1
    state.statistics.distance_traveled = state.statistics.distance_traveled + 1
  end; return s, r
end

function pos_lib.down()
  saveState(); local s, r = turtle.down()
  if s then 
    state.y = state.y - 1
    state.statistics.distance_traveled = state.statistics.distance_traveled + 1
  end; return s, r
end

function pos_lib.turnLeft()
  saveState()
  if turtle.turnLeft() then
    state.facing = (state.facing - 1 + 4) % 4
    return true
  end
  return false
end

function pos_lib.turnRight()
  saveState()
  if turtle.turnRight() then
    state.facing = (state.facing + 1) % 4
    return true
  end
  return false
end

function pos_lib.turnTo(target)
  local attempts = 0
  while state.facing ~= target do
    if attempts > 4 then return false end
    if not pos_lib.turnRight() then os.sleep(0.5) end
    attempts = attempts + 1
  end
  return true
end

-- Enhanced pathfinding with underground navigation
function pos_lib.goTo(tx, ty, tz, status_msg)
  local msg = status_msg or "Traveling"
  
  -- Y movement first
  while state.y < ty and not recall_activated do
    if not digAndUp() then state.task = "STUCK"; return false end
    if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus(msg) end
  end
  while state.y > ty and not recall_activated do
    if not digAndDown() then state.task = "STUCK"; return false end
    if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus(msg) end
  end
  
  -- Z movement
  if state.z > tz then
    if not pos_lib.turnTo(0) then state.task = "STUCK"; return false end
    while state.z > tz and not recall_activated do
      if not digAndMoveForward() then state.task = "STUCK"; return false end
      if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus(msg) end
    end
  elseif state.z < tz then
    if not pos_lib.turnTo(2) then state.task = "STUCK"; return false end
    while state.z < tz and not recall_activated do
      if not digAndMoveForward() then state.task = "STUCK"; return false end
      if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus(msg) end
    end
  end
  
  -- X movement
  if state.x < tx then
    if not pos_lib.turnTo(1) then state.task = "STUCK"; return false end
    while state.x < tx and not recall_activated do
      if not digAndMoveForward() then state.task = "STUCK"; return false end
      if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus(msg) end
    end
  elseif state.x > tx then
    if not pos_lib.turnTo(3) then state.task = "STUCK"; return false end
    while state.x > tx and not recall_activated do
      if not digAndMoveForward() then state.task = "STUCK"; return false end
      if state.statistics.distance_traveled % 10 == 0 then comms.sendStatus(msg) end
    end
  end
  
  return not recall_activated
end

---------------------------------------------------------------------
-- SECTION 4: ENHANCED MINING & UTILITY FUNCTIONS
---------------------------------------------------------------------

local function digRobust(digFunc, detectFunc)
  local attempts = 0
  while turtle[detectFunc]() and not recall_activated do
    if attempts > 5 then return false end
    if not turtle[digFunc]() then return false end
    attempts = attempts + 1
    os.sleep(0.1)
  end
  return not recall_activated
end

-- Enhanced inventory management
local function consolidateInventory()
    for i = 2, 15 do
        local itemA = turtle.getItemDetail(i)
        if itemA then
            for j = i + 1, 16 do
                local itemB = turtle.getItemDetail(j)
                if itemB and itemA.name == itemB.name and itemA.damage == itemB.damage then
                    turtle.select(j)
                    turtle.transferTo(i, itemB.count)
                end
            end
        end
    end
    turtle.select(SAFE_SLOT)
end

local function manageJunk()
  consolidateInventory()
  local junk_dropped = 0
  
  for i = 2, 16 do
    if i ~= FUEL_SLOT then
      local item = turtle.getItemDetail(i)
      if item and JUNK_ITEMS[item.name] then
        turtle.select(i)
        turtle.drop()
        junk_dropped = junk_dropped + item.count
        print("Dropped " .. item.count .. "x " .. item.name)
      end
    end
  end
  
  turtle.select(SAFE_SLOT)
  
  if junk_dropped > 0 then
    print("Total junk dropped: " .. junk_dropped .. " items")
  end
end

-- NEW: Immediate junk dropping for common waste blocks
local function dropJunkImmediately()
  local current_slot = turtle.getSelectedSlot()
  
  for i = 2, 16 do
    if i ~= FUEL_SLOT then
      local item = turtle.getItemDetail(i)
      if item and JUNK_ITEMS[item.name] then
        turtle.select(i)
        turtle.drop() -- Drop immediately
      end
    end
  end
  
  turtle.select(current_slot) -- Restore previous selection
end

-- Enhanced fuel management functions (continued)

-- Try to refuel from base fuel chest
local function refuelFromBase()
  local current_x, current_y, current_z = state.x, state.y, state.z
  
  comms.sendStatus("Low fuel. Returning to base for fuel and inventory dropoff.")
  
  -- Go to base safely (from underground)
  if not safeGoToBase("Returning to base for fuel") then return false end
  
  -- FIRST: Drop off inventory in main chest (south/behind)
  pos_lib.turnTo(2) -- Face south toward main chest
  for i = 2, 16 do
    local item = turtle.getItemDetail(i)
    if item and not ESSENTIAL_ITEMS[item.name] and i ~= FUEL_SLOT then
      turtle.select(i); turtle.drop()
    end
  end
  comms.sendStatus("Inventory deposited. Getting fuel...")
  
  -- SECOND: Get fuel from fuel chest (west/left)
  pos_lib.turnTo(3) -- Face west toward fuel chest
  
  -- Try to get multiple fuel items until we have enough
  local fuel_attempts = 0
  local fuel_target = FUEL_LOW_THRESHOLD * 3 -- Target 3x the low threshold
  
  while turtle.getFuelLevel() < fuel_target and fuel_attempts < 10 do
    turtle.select(FUEL_SLOT)
    
    -- Check if fuel slot has room and is the right type
    local fuel_slot_item = turtle.getItemDetail(FUEL_SLOT)
    local slot_has_space = not fuel_slot_item or fuel_slot_item.count < 64
    
    if slot_has_space and turtle.suck() then
      local item = turtle.getItemDetail(FUEL_SLOT)
      if item and FUEL_TYPES[item.name] then
        -- Refuel as much as we can from this stack
        local fuel_value = FUEL_TYPES[item.name]
        local items_needed = math.ceil((fuel_target - turtle.getFuelLevel()) / fuel_value)
        local items_to_use = math.min(items_needed, item.count)
        
        turtle.refuel(items_to_use)
        print("Used " .. items_to_use .. "x " .. item.name .. " for fuel. Level: " .. turtle.getFuelLevel())
        
        fuel_attempts = fuel_attempts + 1
      else
        -- Not fuel, put it back
        turtle.drop()
        break -- Stop trying if we're getting non-fuel items
      end
    else
      break -- Can't get more fuel
    end
  end
  
  turtle.select(SAFE_SLOT)
  
  local final_fuel = turtle.getFuelLevel()
  if final_fuel >= FUEL_LOW_THRESHOLD then
    comms.sendStatus("Refueled successfully! Level: " .. final_fuel .. ". Returning to work.")
  else
    comms.sendStatus("Refueling incomplete. Level: " .. final_fuel .. ". Returning anyway.")
  end
  
  -- Return to previous position safely
  if not safeLeaveBase(current_x, current_y, current_z, "Returning to work area") then
    return false
  end
  
  return final_fuel >= FUEL_LOW_THRESHOLD
end

local function findEmptyBucket()
  for i = 1, 16 do
    if turtle.getItemDetail(i) and turtle.getItemDetail(i).name == "minecraft:bucket" then return i end
  end
  return nil
end

local function refuelFromLava()
  local bucket_slot = findEmptyBucket()
  if not bucket_slot then return false end
  local directions = { "inspect", "inspectUp", "inspectDown" }
  for _, i_cmd in ipairs(directions) do
    local s, data = turtle[i_cmd]()
    if s and type(data) == "table" and data.name == "minecraft:lava" then
      turtle.select(bucket_slot)
      if turtle[string.gsub(i_cmd, "inspect", "place")]() then
        if turtle.refuel(1) then 
          print("Refueled from lava."); turtle.select(SAFE_SLOT); return true
        else turtle[string.gsub(i_cmd, "inspect", "place")]() end
      end
    end
  end
  turtle.select(SAFE_SLOT)
  return false
end

local function ensureFuel()
  state.fuelLevel = turtle.getFuelLevel()
  
  if type(state.fuelLevel) == "number" and state.fuelLevel < FUEL_LOW_THRESHOLD then
    comms.sendStatus("Fuel low (" .. state.fuelLevel .. "), attempting to refuel.")
    
    -- Check recall before fuel operations
    if recall_activated then 
      comms.sendStatus("Recall activated during fuel check. Aborting fuel operations.")
      return false 
    end
    
    -- First, try to consolidate any fuel in inventory
    consolidateFuel()
    
    -- Try to refuel from fuel slot
    turtle.select(FUEL_SLOT)
    local fuel_item = turtle.getItemDetail(FUEL_SLOT)
    if fuel_item and FUEL_TYPES[fuel_item.name] then
      local fuel_value = FUEL_TYPES[fuel_item.name]
      local fuel_target = FUEL_LOW_THRESHOLD * 2 -- Target 2x the low threshold
      local fuel_needed = math.ceil((fuel_target - state.fuelLevel) / fuel_value)
      local fuel_to_use = math.min(fuel_needed, fuel_item.count)
      turtle.refuel(fuel_to_use)
      print("Used " .. fuel_to_use .. "x " .. fuel_item.name .. " for fuel. Level: " .. turtle.getFuelLevel())
    end
    turtle.select(SAFE_SLOT)
    
    -- Check recall again before trying other fuel sources
    if recall_activated then 
      comms.sendStatus("Recall activated during refueling. Stopping fuel operations.")
      return false 
    end
    
    -- If still low, try lava
    if type(turtle.getFuelLevel()) == "number" and turtle.getFuelLevel() < FUEL_LOW_THRESHOLD then
      if not refuelFromLava() then
        -- If still low, try base (but only if not recalled)
        if not recall_activated and not refuelFromBase() then
          print("WARNING: No fuel source found.")
        end
      end
    end
    
    comms.sendStatus("Refueling attempt finished. Fuel: " .. turtle.getFuelLevel())
  end
  
  -- CRITICAL FUEL HANDLING - Stay at base and wait (but respect recall)
  if type(turtle.getFuelLevel()) == "number" and turtle.getFuelLevel() < 100 then
    comms.sendStatus("CRITICAL FUEL (" .. turtle.getFuelLevel() .. "). Returning to base.")
    
    -- Go to base safely if not already there
    if state.x ~= 0 or state.y ~= 0 or state.z ~= 0 then
      if not safeGoToBase("Emergency fuel return") then
        state.task = "STUCK"
        return false
      end
    end
    
    -- Check recall before entering fuel wait loop
    if recall_activated then
      comms.sendStatus("Recall activated during critical fuel handling.")
      return false
    end
    
    -- Drop off inventory first
    pos_lib.turnTo(2) -- Face south toward main chest
    for i = 2, 16 do
      local item = turtle.getItemDetail(i)
      if item and not ESSENTIAL_ITEMS[item.name] and i ~= FUEL_SLOT then
        turtle.select(i); turtle.drop()
      end
    end
    
    -- Wait at base until fuel is available (but check recall frequently)
    comms.sendStatus("WAITING FOR FUEL. Please add fuel to the fuel chest (to the left).")
    print("CRITICAL FUEL - Waiting at base for fuel to be added to fuel chest...")
    print("Current fuel level: " .. turtle.getFuelLevel())
    print("Press 'r' on monitor to recall if needed.")
    
    while type(turtle.getFuelLevel()) == "number" and turtle.getFuelLevel() < 500 do
      -- CRITICAL: Check recall at the start of every fuel wait loop
      if recall_activated then 
        comms.sendStatus("Recall activated while waiting for fuel. Stopping.")
        return false 
      end
      
      -- Check fuel chest periodically
      pos_lib.turnTo(3) -- Face west toward fuel chest
      
      -- Clear fuel slot first to make room
      turtle.select(FUEL_SLOT)
      local existing_fuel = turtle.getItemDetail(FUEL_SLOT)
      if existing_fuel then
        print("Fuel slot has: " .. existing_fuel.count .. "x " .. existing_fuel.name)
      else
        print("Fuel slot is empty")
      end
      
      local fuel_added = false
      local attempts = 0
      
      -- Try multiple times to get fuel and refuel
      while turtle.getFuelLevel() < 500 and attempts < 5 and not recall_activated do
        attempts = attempts + 1
        print("Fuel attempt " .. attempts .. "/5")
        
        -- Try to get fuel from chest
        if turtle.suck() then
          local item = turtle.getItemDetail(FUEL_SLOT)
          if item then
            print("Got from chest: " .. item.count .. "x " .. item.name)
            
            if FUEL_TYPES[item.name] then
              print("This is valid fuel! Refueling...")
              
              -- Refuel the entire stack
              local fuel_before = turtle.getFuelLevel()
              local fuel_consumed = turtle.refuel(item.count)
              local fuel_after = turtle.getFuelLevel()
              
              print("Fuel before: " .. fuel_before)
              print("Items consumed: " .. fuel_consumed)
              print("Fuel after: " .. fuel_after)
              print("Fuel gained: " .. (fuel_after - fuel_before))
              
              if fuel_after > fuel_before then
                fuel_added = true
                comms.sendStatus("Refueled! Fuel level: " .. fuel_after)
              else
                print("WARNING: No fuel gained despite consuming items!")
              end
            else
              print("Not fuel: " .. item.name .. " - putting back")
              turtle.drop() -- Put back non-fuel items
            end
          else
            print("Got nothing from chest or fuel slot is full")
            break -- Stop trying if we can't get anything
          end
        else
          print("Cannot suck from fuel chest - might be empty")
          break -- Stop if chest is empty
        end
        
        -- Check recall between fuel attempts
        if recall_activated then
          print("Recall activated during fuel attempts. Stopping.")
          break
        end
        
        -- Small delay between attempts
        os.sleep(0.5)
      end
      
      turtle.select(SAFE_SLOT)
      
      if recall_activated then
        comms.sendStatus("Recall activated while refueling. Stopping fuel wait.")
        return false
      end
      
      if not fuel_added then
        -- Still no fuel, wait and try again (but check recall more frequently)
        local current_fuel = turtle.getFuelLevel()
        comms.sendStatus("Still waiting for fuel. Current: " .. current_fuel .. "/500 needed")
        print("Still need fuel. Current: " .. current_fuel .. "/500")
        
        -- Wait in smaller chunks so we can check recall more often
        for wait_chunk = 1, 10 do
          if recall_activated then return false end
          os.sleep(0.5) -- Total 5 second wait, but check recall every 0.5s
        end
      end
    end
    
    if recall_activated then
      comms.sendStatus("Recall activated during fuel wait. Stopping operations.")
      return false
    end
    
    if type(turtle.getFuelLevel()) == "number" and turtle.getFuelLevel() >= 500 then
      comms.sendStatus("Fuel restored! Level: " .. turtle.getFuelLevel() .. ". Resuming operations.")
      print("Fuel restored! Level: " .. turtle.getFuelLevel() .. ". Resuming mining operations.")
      return true
    else
      print("Still low fuel after attempts: " .. turtle.getFuelLevel())
    end
  end
  
  return true
end

-- Enhanced digging functions (with recall checks and immediate junk dropping)
function digAndMoveForward()
  if recall_activated then return false end
  local success, data = turtle.inspect()
  if success and data and data.name and ORE_PRIORITY[data.name] then
    state.statistics.ores_found = state.statistics.ores_found + 1
  end
  if not digRobust("dig", "detect") then return false end
  state.statistics.blocks_mined = state.statistics.blocks_mined + 1
  
  -- Immediately drop any junk that was just mined
  dropJunkImmediately()
  
  return pos_lib.forward()
end

function digAndUp()
  if recall_activated then return false end
  local success, data = turtle.inspectUp()
  if success and data and data.name and ORE_PRIORITY[data.name] then
    state.statistics.ores_found = state.statistics.ores_found + 1
  end
  if not digRobust("digUp", "detectUp") then return false end
  state.statistics.blocks_mined = state.statistics.blocks_mined + 1
  
  -- Immediately drop any junk that was just mined
  dropJunkImmediately()
  
  return pos_lib.up()
end

function digAndDown()
  if recall_activated then return false end
  local success, data = turtle.inspectDown()
  if success and data and data.name and ORE_PRIORITY[data.name] then
    state.statistics.ores_found = state.statistics.ores_found + 1
  end
  if not digRobust("digDown", "detectDown") then return false end
  state.statistics.blocks_mined = state.statistics.blocks_mined + 1
  
  -- Immediately drop any junk that was just mined
  dropJunkImmediately()
  
  return pos_lib.down()
end

-- NEW: Advanced ore vein following
local function followVein(start_x, start_y, start_z, max_depth)
  local visited = {}
  local to_check = {{start_x, start_y, start_z, 0}}
  local ores_mined = 0
  
  while #to_check > 0 and ores_mined < 20 do -- Limit to prevent infinite loops
    if recall_activated then break end
    
    local current = table.remove(to_check, 1)
    local cx, cy, cz, depth = current[1], current[2], current[3], current[4]
    
    if depth > max_depth then goto continue end
    
    local key = cx .. "," .. cy .. "," .. cz
    if visited[key] then goto continue end
    visited[key] = true
    
    -- Move to the block
    if not pos_lib.goTo(cx, cy, cz, "Following ore vein") then break end
    
    -- Check all 6 directions for more ore
    local directions = {
      {0, 0, 1}, {0, 0, -1}, {1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}
    }
    
    for _, dir in ipairs(directions) do
      local nx, ny, nz = cx + dir[1], cy + dir[2], cz + dir[3]
      local check_key = nx .. "," .. ny .. "," .. nz
      
      if not visited[check_key] then
        -- Move to check the block
        if pos_lib.goTo(nx, ny, nz, "Checking for ore") then
          local success, data = turtle.inspect()
          if success and data and data.name and ORE_PRIORITY[data.name] then
            table.insert(to_check, {nx, ny, nz, depth + 1})
            if digRobust("dig", "detect") then
              ores_mined = ores_mined + 1
              state.statistics.ores_found = state.statistics.ores_found + 1
              state.statistics.blocks_mined = state.statistics.blocks_mined + 1
            end
          end
        end
      end
    end
    
    ::continue::
  end
  
  return ores_mined
end

-- NEW: Enhanced ore detection and mining
local function mineOreVein()
  comms.sendStatus("Found ore vein. Mining thoroughly.")
  local start_x, start_y, start_z = state.x, state.y, state.z
  
  -- Mine the current block
  if not digRobust("dig", "detect") then return false end
  if not digRobust("digUp", "detectUp") then return false end  
  if not digRobust("digDown", "detectDown") then return false end
  
  -- Follow the vein
  local ores_found = followVein(start_x, start_y, start_z, VEIN_FOLLOW_DEPTH)
  
  comms.sendStatus("Vein mining complete. Found " .. ores_found .. " ore blocks.")
  return true
end

-- Enhanced inspection function
local function inspectAllDirections()
  local ore_found = false
  
  -- Check all 6 directions
  local checks = {
    {"inspect", "dig", pos_lib.forward},
    {"inspectUp", "digUp", pos_lib.up},
    {"inspectDown", "digDown", pos_lib.down}
  }
  
  for _, check in ipairs(checks) do
    local success, data = turtle[check[1]]()
    if success and type(data) == "table" and data.name and ORE_PRIORITY[data.name] then
      ore_found = true
      if not mineOreVein() then return false end
      break -- Mine one vein at a time
    end
  end
  
  -- Check horizontal directions
  for i = 1, 4 do
    if recall_activated then break end
    local success, data = turtle.inspect()
    if success and type(data) == "table" and data.name and ORE_PRIORITY[data.name] then
      ore_found = true
      if not mineOreVein() then return false end
      break
    end
    if not pos_lib.turnRight() then return false end
  end
  
  return true
end

-- Inventory management
local function isInventoryFull()
  consolidateInventory()
  local empty_slots = 0
  for i = 2, 16 do 
    if turtle.getItemCount(i) == 0 then 
      empty_slots = empty_slots + 1
    end
  end
  -- Consider inventory full if we have less than 2 empty slots (keep some buffer)
  return empty_slots < 2
end

-- Enhanced return to base with ender chest support (if available)
local function returnToBase()
  local current_x, current_y, current_z = state.x, state.y, state.z
  
  -- Try to use ender chest first (only if not already at surface)
  if state.y < (state.surfaceY - 5) then -- Only use ender chest if deep underground
    for i = 2, 16 do
      local item = turtle.getItemDetail(i)
      if item and item.name == "minecraft:ender_chest" then
        turtle.select(i)
        turtle.placeDown()
        
        -- Dump valuable items (but keep essential items)
        for j = 2, 16 do
          local dump_item = turtle.getItemDetail(j)
          if dump_item and not JUNK_ITEMS[dump_item.name] and not ESSENTIAL_ITEMS[dump_item.name] and j ~= FUEL_SLOT then
            turtle.select(j)
            turtle.dropDown()
          end
        end
        
        turtle.select(i)
        turtle.digDown()
        turtle.select(SAFE_SLOT)
        comms.sendStatus("Used ender chest for remote storage. Continuing mining.")
        return current_x, current_y, current_z -- Return current position
      end
    end
  end
  
  -- Fallback: return to base safely and use refuelFromBase which handles both inventory and fuel
  comms.sendStatus("Inventory full. Returning to base for dropoff and refuel check.")
  if not safeGoToBase("Returning to base for inventory dropoff") then return nil end
  
  -- Face south (behind starting position) toward main chest
  pos_lib.turnTo(2)
  for i = 2, 16 do
    local item = turtle.getItemDetail(i)
    if item and not ESSENTIAL_ITEMS[item.name] and i ~= FUEL_SLOT then
      turtle.select(i); turtle.drop()
    end
  end
  turtle.select(SAFE_SLOT)
  
  -- Also check fuel while we're here
  if turtle.getFuelLevel() < FUEL_LOW_THRESHOLD * 1.5 then
    comms.sendStatus("Also topping off fuel while at base...")
    
    pos_lib.turnTo(3) -- Face west toward fuel chest
    turtle.select(FUEL_SLOT)
    
    if turtle.suck() then
      local item = turtle.getItemDetail(FUEL_SLOT)
      if item and FUEL_TYPES[item.name] and not ESSENTIAL_ITEMS[item.name] then
        turtle.refuel(math.min(16, item.count)) -- Refuel some but not all
        print("Topped off fuel: " .. turtle.getFuelLevel())
      else
        turtle.drop() -- Put back non-fuel
      end
    end
    turtle.select(SAFE_SLOT)
  end
  
  return current_x, current_y, current_z
end

---------------------------------------------------------------------
-- SECTION 5: MINING STRATEGIES
---------------------------------------------------------------------

-- Branch mining strategy - much more efficient for ore finding
local function branchMiningStrategy()
  state.task = "BRANCH_MINING"
  
  for level_idx = state.progress.level_index, #BRANCH_LEVELS do
    if recall_activated then return end
    
    local target_y = BRANCH_LEVELS[level_idx]
    state.progress.level_index = level_idx
    
    comms.sendStatus("Starting branch mining at Y=" .. target_y)
    
    -- Go to the starting position for this level
    if not pos_lib.goTo(0, target_y, 0, "Moving to mining level Y=" .. target_y) then
      state.task = "STUCK"; return
    end
    
    -- Create the main tunnel network
    for z = 0, state.length, TUNNEL_SPACING do
      if recall_activated then return end
      
      -- Create tunnel along X axis
      if not pos_lib.goTo(0, target_y, z, "Creating tunnel at Z=" .. z) then
        state.task = "STUCK"; return
      end
      
      pos_lib.turnTo(1) -- Face east
      
      for x = 0, state.width do
        if recall_activated then return end
        
        -- More frequent junk management in Nether
        if x % 3 == 0 then  -- Every 3 blocks instead of 5
          manageJunk()
        end
        
        -- Check for inventory management
        if isInventoryFull() then
          local return_x, return_y, return_z = returnToBase()
          if not return_x then state.task = "STUCK"; return end
          if not safeLeaveBase(return_x, return_y, return_z, "Returning to tunnel") then
            state.task = "STUCK"; return
          end
        end
        
        if not ensureFuel() then state.task = "AWAITING_FUEL"; return end
        
        -- Mine current position thoroughly
        if not inspectAllDirections() then state.task = "STUCK"; return end
        
        -- Move forward if not at the end
        if x < state.width then
          if not digAndMoveForward() then state.task = "STUCK"; return end
        end
        
        -- Periodic status update
        if x % 5 == 0 then
          local progress_pct = ((level_idx - 1) * state.length * state.width + z * state.width + x) / 
                              (#BRANCH_LEVELS * state.length * state.width) * 100
          comms.sendStatus(string.format("Branch mining: %.1f%% complete", progress_pct))
        end
      end
    end
    
    state.progress.level_index = level_idx + 1
    saveState()
  end
  
  state.task = "DONE"
end

-- Hybrid strategy - combines shaft mining with horizontal branches
local function hybridMiningStrategy()
  state.task = "HYBRID_MINING"
  
  -- Create vertical shafts at key points, then branch horizontally
  local shaft_spacing = 8
  
  for z = 0, state.length, shaft_spacing do
    for x = 0, state.width, shaft_spacing do
      if recall_activated then return end
      
      -- Create main shaft
      comms.sendStatus("Creating shaft at (" .. x .. ", " .. z .. ")")
      if not pos_lib.goTo(x, state.surfaceY, z, "Moving to shaft location") then
        state.task = "STUCK"; return
      end
      
      -- Descend and create branches at key levels
      for _, branch_y in ipairs(BRANCH_LEVELS) do
        if recall_activated then return end
        
        if not pos_lib.goTo(x, branch_y, z, "Descending to Y=" .. branch_y) then
          state.task = "STUCK"; return
        end
        
        -- Create short branches in all 4 directions
        for dir = 0, 3 do
          if recall_activated then return end
          
          pos_lib.turnTo(dir)
          local start_x, start_z = state.x, state.z
          
          -- Mine branch
          for i = 1, 6 do -- 6 block branches
            if not ensureFuel() then state.task = "AWAITING_FUEL"; return end
            if isInventoryFull() then
              local return_x, return_y, return_z = returnToBase()
              if not return_x then state.task = "STUCK"; return end
              if not safeLeaveBase(return_x, return_y, return_z, "Returning to branch") then
                state.task = "STUCK"; return
              end
            end
            
            if not inspectAllDirections() then state.task = "STUCK"; return end
            if not digAndMoveForward() then break end
          end
          
          -- Return to shaft center
          if not pos_lib.goTo(start_x, branch_y, start_z, "Returning to shaft") then
            state.task = "STUCK"; return
          end
        end
      end
    end
  end
  
  state.task = "DONE"
end

-- Original shaft mining (improved)
local function shaftMiningStrategy()
  state.task = "SHAFT_MINING"
  
  for z_coord = state.progress.z, state.length do
    -- Better spacing pattern - covers more area
    for x_coord = state.progress.x, state.width do
      if recall_activated or state.task == "STUCK" then return end
      
      state.progress.x = x_coord; state.progress.z = z_coord; saveState()

      if not pos_lib.goTo(x_coord, state.surfaceY, z_coord, "Moving to shaft") then 
        state.task = "STUCK"; return 
      end

      comms.sendStatus("Mining shaft (" .. x_coord .. ", " .. z_coord .. ")")
      
      while not recall_activated do
        if isInventoryFull() then
          local return_x, return_y, return_z = returnToBase()
          if not return_x then state.task = "STUCK"; return end
          if not safeLeaveBase(return_x, return_y, return_z, "Returning to shaft") then
            state.task = "STUCK"; return
          end
        end
        
        if not ensureFuel() then state.task = "AWAITING_FUEL"; return end
        manageJunk()

        local s, d = turtle.inspectDown()
        if s and d and d.name and d.name:find("bedrock") then break end

        if not inspectAllDirections() then state.task = "STUCK"; break end
        if not digAndDown() then break end
        
        os.sleep(0.05) -- Slight delay for stability
      end
      
      if recall_activated or state.task == "STUCK" then return end
    end
    state.progress.x = 0
    state.progress.z = z_coord + 1
  end
  
  state.task = "DONE"
end

---------------------------------------------------------------------
-- SECTION 6: MAIN PROGRAM LOGIC
---------------------------------------------------------------------

function listenForCommands()
  while true do
    local sender, message = rednet.receive(COMMAND_PROTOCOL)
    if message == "recall" then
      recall_activated = true
    end
  end
end

function runMining(args)
  local is_autostart = false
  local state_loaded = false
  
  if not loadState() or #args > 0 then
    if #args == 0 then 
      print("Usage: miner <width> <length> [strategy] [surface_y/dimension] [dimension]")
      print("       miner reset")
      print("       miner fueltest")
      print("       miner recalltest")
      print("       miner inventory")
      print("       miner dimension <nether|overworld>")
      print("")
      print("Strategies: shaft, branch, hybrid")
      print("Dimensions: overworld, nether (auto-detected if not specified)")
      print("Examples:")
      print("  miner 32 64 branch                # Auto-detect dimension")
      print("  miner 32 64 branch nether         # Force Nether mining mode") 
      print("  miner 32 64 branch 65             # Overworld, surface at Y=65")
      print("  miner 32 64 branch 65 nether      # Nether, base at Y=65")
      print("  miner 16 16 branch overworld      # Force Overworld mode")
      print("  miner dimension nether            # Switch existing save to Nether")
      print("  miner inventory                   # Check what turtle is carrying")
      print("  miner reset                       # Clear saved state")
      print("  miner fueltest                    # Debug fuel system")
      print("  miner recalltest                  # Debug recall system")
      print("")
      print("Nether Mode Features:")
      print("- Optimized Y-levels: 8,10,12,14,16,18,20,22 (Ancient Debris)")
      print("- Higher levels: 32,48,64,80,96 (general Nether mining)")
      print("- Ignores: netherrack, basalt, blackstone, soul sand/soil")
      print("- Targets: ancient debris, nether gold, quartz + modded nether ores")
      print("\nOverworld Mode Features:")
      print("- Optimized Y-levels: -54 to -6 (diamonds, deepslate ores)")
      print("- Ignores: stone, dirt, cobblestone, gravel")
      print("- Targets: diamonds, emeralds, gold, iron + all modded ores")
      print("\nSafety Features:")
      print("- Underground base approach: Always approaches base from Y≤-5")
      print("- Structure protection: Never digs through surface buildings")
      print("- Safe departures: Leaves base underground to avoid damage")
      print("- Emergency recall: Responsive recall system with safe return")
      print("\nNote: Turtle requires bucket and fuel to prevent accidental autostart")
      return 
    end
    init(args)
    is_autostart = false -- Manual start with arguments
  else
    is_autostart = true -- Autostarting from saved state
    state_loaded = true
    print("Found saved state - attempting to resume mining...")
    print("Area: " .. state.width .. "x" .. state.length .. ", Strategy: " .. state.strategy)
  end
  
  -- Run pre-flight check with different strictness based on start type
  if not preFlightCheck(is_autostart) then 
    if is_autostart then
      print("\nTo start fresh (ignore saved state), run:")
      print("miner <width> <length> [strategy]")
    end
    return 
  end
  
  if is_autostart then
    print("Autostart approved - resuming mining operation...")
    comms.sendStatus("Resuming mining from saved state...")
  end
  
  comms.init()
  
  -- Auto-detect dimension if not specified in state
  if not state.dimension then
    print("Auto-detecting dimension...")
    local detected_dimension = detectDimension()
    state.dimension = detected_dimension
    
    -- Update branch levels based on detected dimension
    if detected_dimension == "nether" then
      BRANCH_LEVELS = NETHER_BRANCH_LEVELS
      print("Detected: NETHER - Optimizing for Ancient Debris and Nether ores!")
    else
      BRANCH_LEVELS = OVERWORLD_BRANCH_LEVELS  
      print("Detected: OVERWORLD - Optimizing for Diamonds and standard ores!")
    end
    saveState()
  else
    -- Use saved dimension setting
    if state.dimension == "nether" then
      BRANCH_LEVELS = NETHER_BRANCH_LEVELS
      print("Resuming NETHER mining - Targeting Ancient Debris and Nether ores!")
    else
      BRANCH_LEVELS = OVERWORLD_BRANCH_LEVELS
      print("Resuming OVERWORLD mining - Targeting Diamonds and standard ores!")
    end
  end
  
  print("Starting miner. Width: "..state.width..", Length: "..state.length..", Strategy: "..state.strategy..", Dimension: "..state.dimension)
  
  -- Find surface if needed - DIMENSION-AWARE LOGIC
  if not state.surfaceY then
    state.task = "FINDING_SURFACE"
    
    if state.dimension == "nether" then
      comms.sendStatus("Finding Nether base level...")
      print("Nether mining - finding suitable base level...")
      
      -- In Nether, find a solid platform level
      -- Go down until we find solid netherrack/basalt, then go up slightly
      local ground_attempts = 0
      while not turtle.detectDown() and ground_attempts < 100 and state.y > 8 do
        if not pos_lib.down() then break end
        ground_attempts = ground_attempts + 1
      end
      
      -- Go up a bit to be on a platform
      if turtle.detectDown() then
        pos_lib.up()
        pos_lib.up() -- Go up 2 blocks for headroom
      end
      
      state.surfaceY = state.y
      comms.sendStatus("Nether base level found at Y=" .. state.surfaceY)
      print("Nether base level set to Y=" .. state.surfaceY)
      
    else
      -- Overworld surface detection (existing logic)
      comms.sendStatus("Finding surface level.")
      
      -- Check if we're already at a reasonable surface level (Y > 0)
      if state.y >= 0 then
        comms.sendStatus("Already above sea level, finding ground...")
        
        -- Go down to find solid ground
        local ground_search_attempts = 0
        while not turtle.detectDown() and ground_search_attempts < 100 do
          if not pos_lib.down() then break end
          ground_search_attempts = ground_search_attempts + 1
        end
        
        -- If we found ground, go up one to be on top of it
        if turtle.detectDown() then
          pos_lib.up()
        end
        
        state.surfaceY = state.y
        comms.sendStatus("Surface found at Y=" .. state.surfaceY)
      else
        -- We're underground, need to go up first
        comms.sendStatus("Underground, going up to find surface...")
        
        -- Go up until we're above sea level or find air
        local up_attempts = 0
        while state.y < 0 and up_attempts < 200 do
          if not turtle.digUp() then
            if not pos_lib.up() then break end
          else
            if not pos_lib.up() then break end
          end
          up_attempts = up_attempts + 1
        end
        
        -- Now we should be above ground, find the surface
        -- Look for solid ground below us
        local surface_search_attempts = 0
        while not turtle.detectDown() and surface_search_attempts < 100 do
          if not pos_lib.down() then break end
          surface_search_attempts = surface_search_attempts + 1
        end
        
        -- Go up one level to be on top of solid ground
        if turtle.detectDown() then
          pos_lib.up()
        end
        
        state.surfaceY = state.y
        comms.sendStatus("Surface found at Y=" .. state.surfaceY)
      end
    end
    
    -- Sanity check based on dimension
    if state.dimension == "nether" then
      if state.surfaceY < 8 or state.surfaceY > 120 then
        comms.sendStatus("WARNING: Unusual Nether base level Y=" .. state.surfaceY .. ". Continuing anyway.")
      end
    else
      if state.surfaceY < -60 then
        comms.sendStatus("WARNING: Surface seems too low (Y=" .. state.surfaceY .. "). Continuing anyway.")
      elseif state.surfaceY > 200 then
        comms.sendStatus("WARNING: Surface seems too high (Y=" .. state.surfaceY .. "). Continuing anyway.")
      end
    end
    
    saveState()
  end

  -- Execute selected strategy
  if state.strategy == "branch" then
    branchMiningStrategy()
  elseif state.strategy == "hybrid" then
    hybridMiningStrategy()
  else
    shaftMiningStrategy()
  end
end

function main(args)
  -- Special commands
  if args[1] == "reset" then
    if fs.exists(STATE_FILE) then
      fs.delete(STATE_FILE)
      print("State file deleted. Turtle will start fresh next time.")
    else
      print("No state file found.")
    end
    return
  end
  
  -- DEBUG: Manual fuel test command
  if args[1] == "fueltest" then
    -- Initialize basic state for testing
    if not state.facing then
      state = { x = 0, y = 0, z = 0, facing = 0 }
    end
    
    print("=== FUEL SYSTEM TEST ===")
    print("Current fuel level: " .. turtle.getFuelLevel())
    print("Turtle facing: " .. state.facing)
    
    -- Test fuel chest access
    print("Testing fuel chest access (west/left)...")
    pos_lib.turnTo(3) -- Face west
    turtle.select(FUEL_SLOT)
    
    local current_fuel_item = turtle.getItemDetail(FUEL_SLOT)
    print("Fuel slot before: " .. (current_fuel_item and (current_fuel_item.count .. "x " .. current_fuel_item.name) or "empty"))
    
    if turtle.suck() then
      local item = turtle.getItemDetail(FUEL_SLOT)
      if item then
        print("Successfully got: " .. item.count .. "x " .. item.name)
        if FUEL_TYPES[item.name] then
          print("This is valid fuel type!")
          print("Fuel value per item: " .. FUEL_TYPES[item.name])
          
          local before = turtle.getFuelLevel()
          local consumed = turtle.refuel(1) -- Try refueling just 1 item
          local after = turtle.getFuelLevel()
          
          print("Refuel test results:")
          print("  Before: " .. before)
          print("  Items consumed: " .. consumed)
          print("  After: " .. after)
          print("  Fuel gained: " .. (after - before))
          
          if consumed > 0 then
            print("SUCCESS: Refueling works!")
          else
            print("PROBLEM: No items consumed!")
          end
        else
          print("ERROR: Not a recognized fuel type!")
          print("Available fuel types:")
          for fuel_name, fuel_value in pairs(FUEL_TYPES) do
            print("  " .. fuel_name .. " = " .. fuel_value)
          end
          print("Putting item back...")
          turtle.drop()
        end
      else
        print("ERROR: Suck succeeded but got nothing?")
      end
    else
      print("ERROR: Cannot suck from fuel chest!")
      print("Troubleshooting checklist:")
      print("1. Is there a chest to the LEFT (west) of turtle?")
      print("2. Does the chest contain coal or other fuel?")
      print("3. Is the turtle's fuel slot (slot 1) available?")
      print("4. Is the turtle facing the correct direction?")
    end
    
    turtle.select(SAFE_SLOT)
    print("=== TEST COMPLETE ===")
    return
  end
  
  parallel.waitForAny(function() runMining(args) end, listenForCommands)

  local final_message = "Mining operation complete."
  if recall_activated then 
    final_message = "Recalled by operator."
  elseif state.task == "STUCK" then 
    final_message = "Halted due to an obstacle." 
  elseif state.task == "AWAITING_FUEL" then
    final_message = "Halted due to fuel shortage."
  end
  
  comms.sendStatus(final_message .. " Stats: " .. state.statistics.ores_found .. " ores, " .. 
                  state.statistics.blocks_mined .. " blocks, " .. state.statistics.distance_traveled .. " distance")
  
  -- FIXED: Always return home first, then do cleanup (with better recall handling and safe approach)
  local function returnHomeAndCleanup()
    -- If recalled, prioritize getting home immediately
    if recall_activated then
      comms.sendStatus("RECALL ACTIVATED - Emergency return to base!")
      print("RECALL RECEIVED - Stopping all operations and returning home...")
    end
    
    -- Return to base regardless of why we stopped (but faster if recalled and always safely)
    if state.x ~= 0 or state.y ~= 0 or state.z ~= 0 then
      local return_status = final_message .. " Returning home."
      if recall_activated then
        return_status = "RECALL - Emergency return to base!"
      end
      
      -- Use safe pathfinding - always approach from underground
      if recall_activated then
        comms.sendStatus(return_status)
        -- Try safe path home - if it fails, we'll still try the normal goTo
        if not safeGoToBase("RECALL - Emergency underground return") then
          print("Safe path home failed, turtle may be stuck at: " .. state.x .. ", " .. state.y .. ", " .. state.z)
          comms.sendStatus("RECALL: Turtle stuck at (" .. state.x .. ", " .. state.y .. ", " .. state.z .. ")")
        end
      else
        safeGoToBase(return_status)
      end
    end
    
    -- Final dropoff (preserve essential items) - into chest behind robot
    if not recall_activated or (state.x == 0 and state.y == 0 and state.z == 0) then
      pos_lib.turnTo(2) -- Face south (behind starting position) toward main chest
      for i = 2, 16 do
        local item = turtle.getItemDetail(i)
        if item and not ESSENTIAL_ITEMS[item.name] and i ~= FUEL_SLOT then
            turtle.select(i); turtle.drop()
        end
      end
      turtle.select(SAFE_SLOT)
    end
    
    local final_stats_msg = "Mission complete. Final stats: " .. state.statistics.ores_found .. " ores found, " .. 
                           state.statistics.blocks_mined .. " blocks mined."
    
    if recall_activated then
      final_stats_msg = "RECALL COMPLETE. Turtle safely returned. Stats: " .. state.statistics.ores_found .. " ores found, " .. 
                       state.statistics.blocks_mined .. " blocks mined."
      print("RECALL COMPLETE - Turtle has returned to base and dropped off inventory.")
    end
    
    comms.sendStatus(final_stats_msg)
    saveState()
    print(final_message .. " Program finished.")
  end
  
  -- Continue listening for commands during cleanup
  parallel.waitForAny(returnHomeAndCleanup, listenForCommands)
end

local args = {...}
main(args)