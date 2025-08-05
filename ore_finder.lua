---------------------------------------------------------------------
-- ATM10 ORE FINDER - Advanced Pocket Computer Geo Scanner App
-- Requires: Advanced Pocket Computer + Geo Scanner from Advanced Peripherals
---------------------------------------------------------------------

-- CONFIGURATION
local SCAN_RADIUS = 16 -- Scan radius for geo scanner
local REFRESH_RATE = 5 -- Seconds between automatic scans
local VERSION = "1.6-fixed"

---------------------------------------------------------------------
-- INITIALIZE GEO SCANNER FIRST (before any other code)
---------------------------------------------------------------------
print("ATM10 Ore Finder v" .. VERSION)
print("Looking for geo scanner...")

local geoscanner = peripheral.wrap("back")

if not (geoscanner and geoscanner.scan) then
    print("No functional geo scanner on back, trying other sides...")
    local sides = {"front", "left", "right", "top", "bottom"}
    for _, side in ipairs(sides) do
        local p_type = peripheral.getType(side)
        if p_type and (p_type == "geo_scanner" or p_type:find("geo")) then
            geoscanner = peripheral.wrap(side)
            if geoscanner and geoscanner.scan then
                print("Found geo scanner on " .. side)
                break
            else
                geoscanner = nil
            end
        end
    end
end

-- Exit if no geo scanner found
if not geoscanner then
    print("ERROR: Could not find geo scanner!")
    print("Make sure you have:")
    print("1. Advanced Pocket Computer")
    print("2. Geo Scanner addon installed")
    return
end

print("Geo scanner ready!")

---------------------------------------------------------------------
-- JUNK ITEMS AND ORE DEFINITIONS
---------------------------------------------------------------------

-- JUNK ITEMS: Any item in this list will be dropped.
local JUNK_ITEMS = {
  ["minecraft:stone"] = true, ["minecraft:cobblestone"] = true, ["minecraft:dirt"] = true,
  ["minecraft:gravel"] = true, ["minecraft:sand"] = true, ["minecraft:andesite"] = true,
  ["minecraft:diorite"] = true, ["minecraft:granite"] = true, ["minecraft:deepslate"] = true,
  ["minecraft:cobbled_deepslate"] = true, ["minecraft:tuff"] = true, ["minecraft:calcite"] = true,
  ["minecraft:flint"] = true, ["minecraft:netherrack"] = true, ["minecraft:soul_sand"] = true,
  ["minecraft:soul_soil"] = true, ["minecraft:blackstone"] = true, ["minecraft:basalt"] = true,
  ["minecraft:smooth_basalt"] = true, ["minecraft:polished_blackstone"] = true,
  ["minecraft:warped_nylium"] = true, ["minecraft:crimson_nylium"] = true,
  ["minecraft:magma_block"] = true, ["minecraft:nether_bricks"] = true,
  ["minecraft:red_nether_bricks"] = true, ["minecraft:warped_stem"] = true,
  ["minecraft:crimson_stem"] = true, ["minecraft:warped_hyphae"] = true,
  ["minecraft:crimson_hyphae"] = true, ["minecraft:shroomlight"] = true,
  ["minecraft:nether_wart_block"] = true, ["minecraft:warped_wart_block"] = true,
  ["minecraft:bone_block"] = true, ["minecraft:glowstone"] = true,
  ["minecraft:polished_basalt"] = true, ["minecraft:chiseled_nether_bricks"] = true,
  ["minecraft:cracked_nether_bricks"] = true, ["minecraft:nether_brick"] = true,
}

-- ATM10 VALUABLE ORES DATABASE
local ORE_CATEGORIES = {
    { name = "ATM Special Ores", color = colors.purple,
        ores = {
            {name = "Allthemodium", blocks = {"allthemodium:allthemodium_ore"}},
            {name = "Vibranium", blocks = {"allthemodium:vibranium_ore"}},
            {name = "Unobtainium", blocks = {"allthemodium:unobtainium_ore"}},
        }},
    { name = "Precious Ores", color = colors.yellow,
        ores = {
            {name = "Diamond", blocks = {"minecraft:diamond_ore", "minecraft:deepslate_diamond_ore"}},
            {name = "Emerald", blocks = {"minecraft:emerald_ore", "minecraft:deepslate_emerald_ore"}},
            {name = "Ancient Debris", blocks = {"minecraft:ancient_debris"}},
            {name = "Gold", blocks = {"minecraft:gold_ore", "minecraft:deepslate_gold_ore", "minecraft:nether_gold_ore", "alltheores:gold_ore", "alltheores:deepslate_gold_ore", "alltheores:nether_gold_ore"}},
        }},
    { name = "Technology Ores", color = colors.cyan,
        ores = {
            {name = "Certus Quartz", blocks = {"ae2:certus_quartz_ore", "ae2:deepslate_certus_quartz_ore"}},
            {name = "Osmium", blocks = {"mekanism:osmium_ore", "mekanism:deepslate_osmium_ore", "alltheores:osmium_ore", "alltheores:deepslate_osmium_ore"}},
            {name = "Uranium", blocks = {"mekanism:uranium_ore", "mekanism:deepslate_uranium_ore", "alltheores:uranium_ore", "alltheores:deepslate_uranium_ore"}},
            {name = "Fluorite", blocks = {"mekanism:fluorite_ore", "mekanism:deepslate_fluorite_ore", "alltheores:fluorite_ore", "alltheores:deepslate_fluorite_ore"}},
            {name = "Zinc", blocks = {"create:zinc_ore", "create:deepslate_zinc_ore", "alltheores:zinc_ore", "alltheores:deepslate_zinc_ore"}},
        }},
    { name = "Industrial Ores", color = colors.orange,
        ores = {
            {name = "Tin", blocks = {"thermal:tin_ore", "thermal:deepslate_tin_ore", "mekanism:tin_ore", "mekanism:deepslate_tin_ore", "alltheores:tin_ore", "alltheores:deepslate_tin_ore"}},
            {name = "Lead", blocks = {"thermal:lead_ore", "thermal:deepslate_lead_ore", "mekanism:lead_ore", "mekanism:deepslate_lead_ore", "alltheores:lead_ore", "alltheores:deepslate_lead_ore"}},
            {name = "Silver", blocks = {"thermal:silver_ore", "thermal:deepslate_silver_ore", "alltheores:silver_ore", "alltheores:deepslate_silver_ore"}},
            {name = "Nickel", blocks = {"thermal:nickel_ore", "thermal:deepslate_nickel_ore", "alltheores:nickel_ore", "alltheores:deepslate_nickel_ore"}},
            {name = "Aluminum", blocks = {"alltheores:aluminum_ore", "alltheores:deepslate_aluminum_ore"}},
        }},
    { name = "Common Ores", color = colors.lightGray,
        ores = {
            {name = "Iron", blocks = {"minecraft:iron_ore", "minecraft:deepslate_iron_ore", "alltheores:iron_ore", "alltheores:deepslate_iron_ore"}},
            {name = "Copper", blocks = {"minecraft:copper_ore", "minecraft:deepslate_copper_ore", "alltheores:copper_ore", "alltheores:deepslate_copper_ore", "thermal:copper_ore", "thermal:deepslate_copper_ore"}},
            {name = "Coal", blocks = {"minecraft:coal_ore", "minecraft:deepslate_coal_ore", "alltheores:coal_ore", "alltheores:deepslate_coal_ore"}},
            {name = "Redstone", blocks = {"minecraft:redstone_ore", "minecraft:deepslate_redstone_ore", "alltheores:redstone_ore", "alltheores:deepslate_redstone_ore"}},
            {name = "Lapis", blocks = {"minecraft:lapis_ore", "minecraft:deepslate_lapis_ore", "alltheores:lapis_ore", "alltheores:deepslate_lapis_ore"}},
        }},
    { name = "Nether Ores", color = colors.red,
        ores = {
            {name = "Ancient Debris", blocks = {"minecraft:ancient_debris"}},
            {name = "Nether Quartz", blocks = {"minecraft:nether_quartz_ore", "alltheores:nether_quartz_ore"}},
            {name = "Nether Gold", blocks = {"minecraft:nether_gold_ore", "alltheores:nether_gold_ore"}},
            {name = "Gilded Blackstone", blocks = {"minecraft:gilded_blackstone"}},
            {name = "Nether Copper", blocks = {"alltheores:nether_copper_ore", "thermal:nether_copper_ore"}},
            {name = "Nether Iron", blocks = {"alltheores:nether_iron_ore", "thermal:nether_iron_ore"}},
        }},
}

---------------------------------------------------------------------
-- GLOBAL STATE
---------------------------------------------------------------------
local current_menu = "main"
local selected_category = nil
local selected_ore = nil
local last_scan_results = {}
local player_pos = {x = 0, y = 0, z = 0}

---------------------------------------------------------------------
-- UTILITY FUNCTIONS
---------------------------------------------------------------------
local function safeFuelLevel() return geoscanner.getFuelLevel and geoscanner.getFuelLevel() or 999999 end
local function safeMaxFuelLevel() return geoscanner.getMaxFuelLevel and geoscanner.getMaxFuelLevel() or 999999 end
local function safeCost(radius) return geoscanner.cost and geoscanner.cost(radius) or 0 end
local function clearScreen() term.clear(); term.setCursorPos(1, 1) end

local function centerText(text, y)
    local w, _ = term.getSize()
    local x = math.floor((w - #text) / 2) + 1
    term.setCursorPos(x, y)
    term.write(text)
end

local function drawHeader()
    local w, _ = term.getSize()
    centerText("ATM10 ORE FINDER v" .. VERSION, 1)
    term.setCursorPos(1, 2)
    term.write(string.rep("-", w))
end

local function updatePlayerPosition()
    if gps and gps.locate then
        local x, y, z = gps.locate(1)
        if x and y and z then
            player_pos = {x = x, y = y - 1, z = z}
            return
        end
    end
    player_pos = {x = 0, y = -1, z = 0}
end

local function calculateDistance(x1, y1, z1, x2, y2, z2)
    if not (x1 and y1 and z1 and x2 and y2 and z2) then return 0 end
    return math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

local function calculateDirection(dx, dz)
    if not (dx and dz) then return {arrow = "?", name = "Unknown"} end
    if dx == 0 and dz == 0 then return {arrow = "●", name = "Here"} end
    if math.abs(dx) > math.abs(dz) then
        return dx > 0 and {arrow = "→", name = "East"} or {arrow = "←", name = "West"}
    else
        return dz > 0 and {arrow = "↓", name = "South"} or {arrow = "↑", name = "North"}
    end
end

---------------------------------------------------------------------
-- UI DRAWING FUNCTIONS
---------------------------------------------------------------------

local function drawMainMenu()
    clearScreen(); drawHeader()
    local fuel, max_fuel = safeFuelLevel(), safeMaxFuelLevel()
    term.setCursorPos(1, 4)
    if fuel < 1000 and fuel < 999999 then
        term.setTextColor(colors.orange); term.write("Scanner Status: Low fuel (" .. fuel .. "/" .. max_fuel .. ")")
    else
        term.setTextColor(colors.green)
        if fuel < 999999 then term.write("Scanner Status: Ready (" .. fuel .. "/" .. max_fuel .. " fuel)")
        else term.write("Scanner Status: Ready") end
    end
    term.setTextColor(colors.white); term.setCursorPos(1, 6); term.write("Select ore category:")
    local y = 8
    for i, category in ipairs(ORE_CATEGORIES) do
        term.setCursorPos(3, y); term.setTextColor(category.color); term.write(i .. ". " .. category.name)
        y = y + 1
    end
    term.setTextColor(colors.white); term.setCursorPos(1, y + 1)
    term.write("Enter number (1-" .. #ORE_CATEGORIES .. ") or \'q\' to quit:")
    term.setCursorPos(1, y + 3); term.write("Scan radius: " .. SCAN_RADIUS .. " blocks")
end

local function drawOreMenu()
    if not selected_category then return end
    clearScreen(); drawHeader()
    term.setCursorPos(1, 4); term.setTextColor(selected_category.color); term.write(selected_category.name)
    term.setTextColor(colors.white)
    local y = 6
    for i, ore in ipairs(selected_category.ores) do
        term.setCursorPos(3, y); term.write(i .. ". " .. ore.name)
        y = y + 1
    end
    term.setCursorPos(1, y + 1); term.write("Enter number, \'b\' for back, or \'q\' to quit:")
end

local function drawScanResults()
    if not selected_ore or not last_scan_results then return end
    clearScreen(); drawHeader()
    local fuel, max_fuel, cost = safeFuelLevel(), safeMaxFuelLevel(), safeCost(SCAN_RADIUS)
    term.setCursorPos(1, 4); term.setTextColor(selected_category.color)
    term.write("Scanning: " .. selected_ore.name .. " (radius: " .. SCAN_RADIUS .. ")")
    term.setTextColor(colors.white); term.setCursorPos(1, 5)
    if fuel < cost and fuel < 999999 then
        term.setTextColor(colors.orange); term.write("Low fuel: " .. fuel .. "/" .. max_fuel .. " (need " .. cost .. ")")
    else
        term.setTextColor(colors.green)
        if fuel < 999999 then term.write("Fuel: " .. fuel .. "/" .. max_fuel)
        else term.write("Scanner ready") end
    end
    term.setTextColor(colors.white)
    if #last_scan_results == 0 then
        term.setCursorPos(1, 7); term.write("No " .. selected_ore.name .. " found within " .. SCAN_RADIUS .. " blocks")
        term.setCursorPos(1, 9); term.write("Try moving to a different area")
        if fuel < cost and fuel < 999999 then term.setCursorPos(1, 10); term.write("or charge the geo scanner") end
    else
        local closest = last_scan_results[1]
        local dx = closest.x and player_pos.x and (closest.x - player_pos.x) or 0
        local dz = closest.z and player_pos.z and (closest.z - player_pos.z) or 0
        local direction = calculateDirection(dx, dz)
        term.setCursorPos(1, 7); term.write("Found " .. #last_scan_results .. " deposit(s)")
        term.setCursorPos(1, 9); term.write("CLOSEST:")
        term.setCursorPos(1, 11); term.write("Direction: " .. direction.name)
        term.setCursorPos(1, 12); term.setTextColor(colors.lime); term.write("Arrow: " .. direction.arrow .. " " .. direction.arrow .. " " .. direction.arrow)
        term.setTextColor(colors.white); term.setCursorPos(1, 14); term.write("Distance: " .. math.floor(closest.distance or 0) .. " blocks")
        term.setCursorPos(1, 15); term.write("Y-Level: " .. tostring(closest.y or "unknown"))
        term.setCursorPos(1, 16); term.write("Block: " .. tostring(closest.block_name or "unknown"))
        if #last_scan_results > 1 then
            term.setCursorPos(1, 18); term.write("Other deposits:")
            for i = 2, math.min(4, #last_scan_results) do
                local ore = last_scan_results[i]
                term.setCursorPos(3, 17 + i); term.write(math.floor(ore.distance or 0) .. " blocks (Y=" .. tostring(ore.y or "?") .. ")")
            end
        end
    end
    local _, h = term.getSize(); term.setCursorPos(1, h - 1); term.write("\'r\' to rescan, \'b\' for back, \'q\' to quit")
end

---------------------------------------------------------------------
-- SCANNING FUNCTIONS
---------------------------------------------------------------------
local function scanForOres(ore_blocks)
    updatePlayerPosition()
    if safeFuelLevel() < safeCost(SCAN_RADIUS) and safeFuelLevel() < 999999 then return {} end
    local all_blocks, _ = geoscanner.scan(SCAN_RADIUS)
    if not all_blocks then return {} end
    local results = {}
    local ore_lookup = {}
    for _, block_name in ipairs(ore_blocks) do ore_lookup[block_name] = true end
    for _, block_data in ipairs(all_blocks) do
        if block_data and block_data.name and ore_lookup[block_data.name] then
            local distance = calculateDistance(player_pos.x, player_pos.y, player_pos.z, block_data.x, block_data.y, block_data.z)
            table.insert(results, {x = block_data.x, y = block_data.y, z = block_data.z, distance = distance, block_name = block_data.name, tags = block_data.tags})
        end
    end
    table.sort(results, function(a, b) return a.distance < b.distance end)
    return results
end

local function performScan()
    if not selected_ore then return end
    term.setCursorPos(1, 3); term.write("Scanning..."); term.setCursorPos(1, 1) -- Hide cursor during scan
    last_scan_results = scanForOres(selected_ore.blocks)
    drawScanResults()
end

---------------------------------------------------------------------
-- INPUT HANDLING
---------------------------------------------------------------------

local function handleMainMenuInput()
    local _, key = os.pullEvent("char")
    if key == "q" then return false end
    local num = tonumber(key)
    if num and num >= 1 and num <= #ORE_CATEGORIES then
        selected_category = ORE_CATEGORIES[num]
        current_menu = "ore_select"
        drawOreMenu()
    end
    return true
end

local function handleOreMenuInput()
    local _, key = os.pullEvent("char")
    if key == "q" then return false
    elseif key == "b" then
        current_menu = "main"; selected_category = nil; drawMainMenu()
        return true
    end
    local num = tonumber(key)
    if num and num >= 1 and num <= #selected_category.ores then
        selected_ore = selected_category.ores[num]
        current_menu = "scanning"
        performScan()
    end
    return true
end

local function handleScanInput()
    local _, key = os.pullEvent("char")
    if key == "q" then return false
    elseif key == "b" then
        current_menu = "ore_select"; selected_ore = nil; last_scan_results = {}; drawOreMenu()
    elseif key == "r" then
        performScan()
    end
    return true
end

---------------------------------------------------------------------
-- MAIN PROGRAM
---------------------------------------------------------------------
local function main()
    if safeFuelLevel() < 999999 and safeFuelLevel() < safeCost(SCAN_RADIUS) then
        print("WARNING: Not enough fuel for scanning!")
        print("Please charge your geo scanner before use.")
    end
    updatePlayerPosition()
    if gps and gps.locate then
        local x,_,_ = gps.locate(1)
        if x then print("GPS available - using absolute coordinates")
        else print("GPS not available - using relative positioning") end
    else print("No GPS system - using relative positioning") end
    print("Ready to scan!"); sleep(1)
    current_menu = "main"; drawMainMenu()
    local running = true
    while running do
        if current_menu == "main" then running = handleMainMenuInput()
        elseif current_menu == "ore_select" then running = handleOreMenuInput()
        elseif current_menu == "scanning" then running = handleScanInput() end
    end
    clearScreen(); print("Thanks for using ATM10 Ore Finder!"); print("Happy mining!")
end

local function safeMain()
    local success, err = pcall(main)
    if not success then
        clearScreen()
        print("ERROR: " .. tostring(err))
        print("\nMake sure you have:\n1. Advanced Pocket Computer\n2. Geo Scanner addon installed\n3. Sufficient power\n\nIf the error persists, please report it.")
    end
end

safeMain()