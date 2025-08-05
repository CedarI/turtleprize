-- Auto-updater for ComputerCraft ATM10 Collection
-- Automatically detects device type and downloads appropriate files
-- Usage: update [branch_name]
-- 
-- Device Detection:
--   Computer -> downloads monitor.lua
--   Pocket Computer -> downloads ore_finder.lua  
--   Turtle -> downloads miner.lua

local args = {...}
local branch = args[1] or "main"
local base_url = "https://raw.githubusercontent.com/CedarI/turtleprize/" .. branch .. "/"

local files = {
  "miner.lua",
  "monitor.lua",
  "ore_finder.lua"
}

print("ComputerCraft ATM10 Collection Updater")
print("Downloading from branch: " .. branch)
print("========================")

local function downloadFile(filename)
  local url = base_url .. filename
  print("Downloading " .. filename .. "...")
  
  -- Delete old version
  if fs.exists(filename) then
    fs.delete(filename)
  end
  
  -- Download new version
  local response = http.get(url)
  if response then
    local content = response.readAll()
    response.close()
    
    local file = fs.open(filename, "w")
    file.write(content)
    file.close()
    
    print("✓ " .. filename .. " updated successfully")
    return true
  else
    print("✗ Failed to download " .. filename)
    return false
  end
end

local function isComputer()
  return turtle == nil and pocket == nil
end

local function isPocketComputer()
  return pocket ~= nil
end

local function isTurtle()
  return turtle ~= nil
end

-- Download appropriate files based on device type
local success_count = 0
local total_files = 0

if isComputer() then
  -- This is a computer, download monitor.lua
  print("Detected: Computer (downloading monitor.lua)")
  total_files = 1
  if downloadFile("monitor.lua") then
    success_count = success_count + 1
  end
elseif isPocketComputer() then
  -- This is a pocket computer, download ore_finder.lua
  print("Detected: Pocket Computer (downloading ore_finder.lua)")
  total_files = 1
  if downloadFile("ore_finder.lua") then
    success_count = success_count + 1
  end
elseif isTurtle() then
  -- This is a turtle, download miner.lua
  print("Detected: Turtle (downloading miner.lua)")
  total_files = 1
  if downloadFile("miner.lua") then
    success_count = success_count + 1
  end
else
  print("ERROR: Unknown device type!")
  print("Could not determine if this is a computer, turtle, or pocket computer.")
  return
end

print("========================")
if success_count == total_files then
  print("Update complete! " .. success_count .. "/" .. total_files .. " files updated")
  
  if isComputer() then
    print("Ready to run turtle monitoring: monitor")
  elseif isPocketComputer() then  
    print("Ready to find ores: ore_finder")
  elseif isTurtle() then
    print("Ready to mine: miner <width> <length> [strategy]")
  end
else
  print("Update failed! " .. success_count .. "/" .. total_files .. " files updated")
  print("Check your internet connection and try again")
end