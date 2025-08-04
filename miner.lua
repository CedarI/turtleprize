---------------------------------------------------------------------
-- SECTION 1: CONFIGURATION
---------------------------------------------------------------------

-- JUNK ITEMS: Any item in this list will be dropped.
local JUNK_ITEMS = {
  ["minecraft:stone"] = true, ["minecraft:cobblestone"] = true, ["minecraft:dirt"] = true,
  ["minecraft:gravel"] = true, ["minecraft:sand"] = true, ["minecraft:andesite"] = true,
  ["minecraft:diorite"] = true, ["minecraft:granite"] = true, ["minecraft:deepslate"] = true,
  ["minecraft:cobbled_deepslate"] = true, ["minecraft:tuff"] = true, ["minecraft:calcite"] = true,
  ["minecraft:flint"] = true,
}

-- ORE PRIORITY: This list defines valuable ores worth mining
local ORE_PRIORITY = {
  ["allthemodium:allthemodium_ore"] = true, ["allthemodium:vibranium_ore"] = true, ["allthemodium:unobtainium_ore"] = true,
  ["minecraft:diamond_ore"] = true, ["minecraft:deepslate_diamond_ore"] = true, ["minecraft:ancient_debris"] = true,
  ["minecraft:emerald_ore"] = true, ["minecraft:deepslate_emerald_ore"] = true, ["minecraft:lapis_ore"] = true,
  ["minecraft:deepslate_lapis_ore"] = true, ["minecraft:gold_ore"] = true, ["minecraft:deepslate_gold_ore"] = true,
  ["mekanism:osmium_ore"] = true, ["mekanism:deepslate_osmium_ore"] = true, ["mekanism:uranium_ore"] = true,
  ["mekanism:deepslate_uranium_ore"] = true, ["mekanism:fluorite_ore"] = true, ["mekanism:deepslate_fluorite_ore"] = true,
  ["mekanism:tin_ore"] = true, ["mekanism:deepslate_tin_ore"] = true, ["mekanism:lead_ore"] = true,
  ["mekanism:deepslate_lead_ore"] = true, ["thermal:tin_ore"] = true, ["thermal:deepslate_tin_ore"] = true,
  ["alltheores:tin_ore"] = true, ["thermal:lead_ore"] = true, ["thermal:deepslate_lead_ore"] = true,
  ["alltheores:lead_ore"] = true, ["thermal:silver_ore"] = true, ["thermal:deepslate_silver_ore"] = true,
  ["alltheores:silver_ore"] = true, ["thermal:nickel_ore"] = true, ["thermal:deepslate_nickel_ore"] = true,
  ["alltheores:nickel_ore"] = true, ["alltheores:aluminum_ore"] = true, ["alltheores:zinc_ore"] = true,
  ["thermal:cinnabar_ore"] = true, ["thermal:deepslate_cinnabar_ore"] = true, ["thermal:niter_ore"] = true,
  ["thermal:deepslate_niter_ore"] = true, ["thermal:sulfur_ore"] = true, ["thermal:deepslate_sulfur_ore"] = true,
  ["thermal:apatite_ore"] = true, ["thermal:deepslate_apatite_ore"] = true, ["create:zinc_ore"] = true,
  ["create:deepslate_zinc_ore"] = true, ["ae2:certus_quartz_ore"] = true, ["ae2:deepslate_certus_quartz_ore"] = true,
  ["minecraft:iron_ore"] = true, ["minecraft:deepslate_iron_ore"] = true, ["minecraft:copper_ore"] = true,
  ["minecraft:deepslate_copper_ore"] = true, ["minecraft:redstone_ore"] = true, ["minecraft:deepslate_redstone_ore"] = true,
  ["minecraft:coal_ore"] = true, ["minecraft:deepslate_coal_ore"] = true,
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
local BRANCH_LEVELS = {-54, -50, -46, -42, -38, -34, -30, -26, -22, -18, -14, -10, -6} -- Key Y levels for branch mining
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

-- Enhanced initialization with strategy selection
local function init(args)
  state = {
    x = 0, y = 0, z = 0, facing = 0, task = "STARTING",
    width = tonumber(args[1]) or 32, length = tonumber(args[2]) or 64,
    strategy = args[3] or MINING_STRATEGY,
    progress = { x = 0, z = 0, level_index = 1 },
    surfaceY = nil,
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
  while turtle[detectFunc]() do
    if attempts > 5 then return false end
    if not turtle[digFunc]() then return false end
    attempts = attempts + 1
    os.sleep(0.1)
  end
  return true
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
  for i = 2, 16 do
    if i ~= FUEL_SLOT then
      local item = turtle.getItemDetail(i)
      if item and JUNK_ITEMS[item.name] then
        turtle.select(i)
        turtle.drop()
      end
    end
  end
  turtle.select(SAFE_SLOT)
end

-- Enhanced fuel management functions

-- Find fuel in inventory and move it to fuel slot
local function consolidateFuel()
  local fuel_slot_item = turtle.getItemDetail(FUEL_SLOT)
  
  -- If fuel slot is empty, find fuel elsewhere
  if not fuel_slot_item then
    for i = 2, 16 do
      local item = turtle.getItemDetail(i)
      if item and FUEL_TYPES[item.name] then
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
      if item and item.name == fuel_slot_item.name then
        turtle.select(i)
        turtle.transferTo(FUEL_SLOT, item.count)
      end
    end
  end
  
  turtle.select(SAFE_SLOT)
end

-- Try to refuel from base fuel chest
local function refuelFromBase()
  local current_x, current_y, current_z = state.x, state.y, state.z
  
  comms.sendStatus("Low fuel. Checking base for fuel supplies.")
  
  -- Go to base
  if not pos_lib.goTo(0, 0, 0, "Returning to base for fuel") then return false end
  
  -- Face west (left) toward fuel chest
  pos_lib.turnTo(3) -- Direction 3 = west (left from starting position)
  
  -- Try to suck fuel from chest
  local fuel_found = false
  for fuel_name, _ in pairs(FUEL_TYPES) do
    turtle.select(FUEL_SLOT)
    if turtle.suck() then
      local item = turtle.getItemDetail(FUEL_SLOT)
      if item and FUEL_TYPES[item.name] then
        fuel_found = true
        print("Found " .. item.name .. " in fuel chest")
        break
      else
        turtle.drop() -- Put back non-fuel items
      end
    end
  end
  
  if fuel_found then
    turtle.select(FUEL_SLOT)
    turtle.refuel()
    comms.sendStatus("Refueled at base. Returning to work.")
  end
  
  turtle.select(SAFE_SLOT)
  
  -- Return to previous position
  if not pos_lib.goTo(current_x, current_y, current_z, "Returning to work area") then
    return false
  end
  
  return fuel_found
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
    
    -- First, try to consolidate any fuel in inventory
    consolidateFuel()
    
    -- Try to refuel from fuel slot
    turtle.select(FUEL_SLOT)
    local fuel_item = turtle.getItemDetail(FUEL_SLOT)
    if fuel_item and FUEL_TYPES[fuel_item.name] then
      local fuel_value = FUEL_TYPES[fuel_item.name]
      local fuel_needed = math.ceil((FUEL_LOW_THRESHOLD * 2 - state.fuelLevel) / fuel_value)
      turtle.refuel(math.min(fuel_needed, fuel_item.count))
      print("Used " .. fuel_item.name .. " for fuel")
    end
    turtle.select(SAFE_SLOT)
    
    -- If still low, try lava
    if type(turtle.getFuelLevel()) == "number" and turtle.getFuelLevel() < FUEL_LOW_THRESHOLD then
      if not refuelFromLava() then
        -- If still low, try base
        if not refuelFromBase() then
          print("WARNING: No fuel source found.")
        end
      end
    end
    
    comms.sendStatus("Refueling attempt finished. Fuel: " .. turtle.getFuelLevel())
  end
  
  -- CRITICAL FUEL HANDLING - Stay at base and wait
  if type(turtle.getFuelLevel()) == "number" and turtle.getFuelLevel() < 100 then
    comms.sendStatus("CRITICAL FUEL (" .. turtle.getFuelLevel() .. "). Returning to base.")
    
    -- Go to base if not already there
    if state.x ~= 0 or state.y ~= 0 or state.z ~= 0 then
      if not pos_lib.goTo(0, 0, 0, "Emergency fuel return") then
        state.task = "STUCK"
        return false
      end
    end
    
    -- Wait at base until fuel is available
    comms.sendStatus("WAITING FOR FUEL. Please add fuel to the fuel chest (to the left).")
    print("CRITICAL FUEL - Waiting at base for fuel to be added to fuel chest...")
    
    while type(turtle.getFuelLevel()) == "number" and turtle.getFuelLevel() < 500 do
      if recall_activated then return false end
      
      -- Check fuel chest periodically
      pos_lib.turnTo(3) -- Face west toward fuel chest
      turtle.select(FUEL_SLOT)
      
      local fuel_added = false
      -- Try to get fuel from chest
      if turtle.suck() then
        local item = turtle.getItemDetail(FUEL_SLOT)
        if item and FUEL_TYPES[item.name] then
          print("Found " .. item.name .. " in fuel chest!")
          turtle.refuel(item.count)
          fuel_added = true
          comms.sendStatus("Refueled! Fuel level: " .. turtle.getFuelLevel())
        else
          turtle.drop() -- Put back non-fuel items
        end
      end
      
      turtle.select(SAFE_SLOT)
      
      if not fuel_added then
        -- Still no fuel, wait and try again
        comms.sendStatus("Still waiting for fuel. Current: " .. turtle.getFuelLevel() .. "/500 needed")
        os.sleep(5) -- Wait 5 seconds before checking again
      end
    end
    
    if type(turtle.getFuelLevel()) == "number" and turtle.getFuelLevel() >= 500 then
      comms.sendStatus("Fuel restored! Level: " .. turtle.getFuelLevel() .. ". Resuming operations.")
      print("Fuel restored! Resuming mining operations.")
      return true
    end
  end
  
  return true
end

-- Enhanced digging functions
function digAndMoveForward()
  local success, data = turtle.inspect()
  if success and data and data.name and ORE_PRIORITY[data.name] then
    state.statistics.ores_found = state.statistics.ores_found + 1
  end
  if not digRobust("dig", "detect") then return false end
  state.statistics.blocks_mined = state.statistics.blocks_mined + 1
  return pos_lib.forward()
end

function digAndUp()
  local success, data = turtle.inspectUp()
  if success and data and data.name and ORE_PRIORITY[data.name] then
    state.statistics.ores_found = state.statistics.ores_found + 1
  end
  if not digRobust("digUp", "detectUp") then return false end
  state.statistics.blocks_mined = state.statistics.blocks_mined + 1
  return pos_lib.up()
end

function digAndDown()
  local success, data = turtle.inspectDown()
  if success and data and data.name and ORE_PRIORITY[data.name] then
    state.statistics.ores_found = state.statistics.ores_found + 1
  end
  if not digRobust("digDown", "detectDown") then return false end
  state.statistics.blocks_mined = state.statistics.blocks_mined + 1
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
  
  -- Try to use ender chest first
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
      return current_x, current_y, current_z -- Return current position
    end
  end
  
  -- Fallback: return to base
  comms.sendStatus("Inventory full. Returning to base.")
  if not pos_lib.goTo(0, 0, 0, "Returning to base") then return nil end
  
  -- Face south (behind starting position) toward main chest
  pos_lib.turnTo(2)
  for i = 2, 16 do
    local item = turtle.getItemDetail(i)
    if item and not ESSENTIAL_ITEMS[item.name] and i ~= FUEL_SLOT then
      turtle.select(i); turtle.drop()
    end
  end
  turtle.select(SAFE_SLOT)
  
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
        
        -- Check for inventory management
        if isInventoryFull() then
          local return_x, return_y, return_z = returnToBase()
          if not return_x then state.task = "STUCK"; return end
          if not pos_lib.goTo(return_x, return_y, return_z, "Returning to tunnel") then
            state.task = "STUCK"; return
          end
        end
        
        if not ensureFuel() then state.task = "AWAITING_FUEL"; return end
        manageJunk()
        
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
              if not pos_lib.goTo(return_x, return_y, return_z, "Returning to branch") then
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
          if not pos_lib.goTo(return_x, return_y, return_z, "Returning to shaft") then
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
      print("Usage: miner <width> <length> [strategy]")
      print("Strategies: shaft, branch, hybrid")
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
  print("Starting miner. Width: "..state.width..", Length: "..state.length..", Strategy: "..state.strategy)
  
  -- Find surface if needed
  if not state.surfaceY then
    state.task = "FINDING_SURFACE"
    comms.sendStatus("Finding surface level.")
    while not turtle.detectDown() do
      if not pos_lib.down() then
        comms.sendStatus("Cannot find ground. Halting."); state.task = "STUCK"; return
      end
    end
    while turtle.detectUp() do pos_lib.up() end
    state.surfaceY = state.y
    comms.sendStatus("Surface found at Y=" .. state.surfaceY)
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
  parallel.waitForAny(function() runMining(args) end, listenForCommands)

  local final_message = "Mining operation complete."
  if recall_activated then 
    final_message = "Recalled by operator."
  elseif state.task == "STUCK" then 
    final_message = "Halted due to an obstacle." 
  end
  
  comms.sendStatus(final_message .. " Stats: " .. state.statistics.ores_found .. " ores, " .. 
                  state.statistics.blocks_mined .. " blocks, " .. state.statistics.distance_traveled .. " distance")
  
  -- FIXED: Keep listening for commands during return home and cleanup
  local function returnHomeAndCleanup()
    pos_lib.goTo(0, 0, 0, final_message .. " Returning home.")
    
    -- Final dropoff (preserve essential items) - into chest behind robot
    pos_lib.turnTo(2) -- Face south (behind starting position) toward main chest
    for i = 2, 16 do
      local item = turtle.getItemDetail(i)
      if item and not ESSENTIAL_ITEMS[item.name] and i ~= FUEL_SLOT then
          turtle.select(i); turtle.drop()
      end
    end
    turtle.select(SAFE_SLOT)
    
    comms.sendStatus("Mission complete. Final stats: " .. state.statistics.ores_found .. " ores found, " .. 
                    state.statistics.blocks_mined .. " blocks mined.")
    saveState()
    print(final_message .. " Program finished.")
  end
  
  -- Continue listening for commands during cleanup
  parallel.waitForAny(returnHomeAndCleanup, listenForCommands)
end

local args = {...}
main(args)