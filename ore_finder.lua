---------------------------------------------------------------------
-- ATM10 ORE FINDER - Advanced Pocket Computer Geo Scanner App
-- v1.7-fixed - By CedarI, cleanup by Gemini
---------------------------------------------------------------------

-- CONFIGURATION
local SCAN_RADIUS = 16 -- Scan radius for geo scanner
local VERSION = "1.7-fixed"

---------------------------------------------------------------------
-- INITIALIZE GEO SCANNER
---------------------------------------------------------------------
print("ATM10 Ore Finder v" .. VERSION)
print("Looking for geo scanner...")

local geoscanner = peripheral.wrap("back")

if not (geoscanner and geoscanner.scan) then
    print("No functional geo scanner on back, trying other sides...")
    local sides = {"front", "left", "right", "top", "bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) and peripheral.getType(side):find("geo") then
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

if not geoscanner then
    term.clear(); term.setCursorPos(1,1)
    print("ERROR: Could not find a functional geo scanner!")
    print("Please ensure you have:")
    print("1. An Advanced Pocket Computer")
    print("2. A Geo Scanner addon installed")
    print("3. Sufficient power for the scanner")
    return
end

print("Geo scanner ready!")
os.sleep(1)

---------------------------------------------------------------------
-- ORE DEFINITIONS (as a standard array)
---------------------------------------------------------------------
local ORE_CATEGORIES = {
    {
        name = "ATM Special Ores",
        color = colors.purple,
        ores = {
            {name = "Allthemodium", blocks = {"allthemodium:allthemodium_ore"}},
            {name = "Vibranium", blocks = {"allthemodium:vibranium_ore"}},
            {name = "Unobtainium", blocks = {"allthemodium:unobtainium_ore"}},
        }
    },
    {
        name = "Precious Ores",
        color = colors.yellow,
        ores = {
            {name = "Diamond", blocks = {"minecraft:diamond_ore", "minecraft:deepslate_diamond_ore"}},
            {name = "Emerald", blocks = {"minecraft:emerald_ore", "minecraft:deepslate_emerald_ore"}},
            {name = "Ancient Debris", blocks = {"minecraft:ancient_debris"}},
            {name = "Gold", blocks = {"minecraft:gold_ore", "minecraft:deepslate_gold_ore", "minecraft:nether_gold_ore"}}
        }
    },
    {
        name = "Technology Ores",
        color = colors.cyan,
        ores = {
            {name = "Certus Quartz", blocks = {"ae2:certus_quartz_ore", "ae2:deepslate_certus_quartz_ore"}},
            {name = "Osmium", blocks = {"mekanism:osmium_ore", "mekanism:deepslate_osmium_ore"}},
            {name = "Uranium", blocks = {"mekanism:uranium_ore", "mekanism:deepslate_uranium_ore"}},
            {name = "Fluorite", blocks = {"mekanism:fluorite_ore", "mekanism:deepslate_fluorite_ore"}},
            {name = "Zinc", blocks = {"create:zinc_ore", "create:deepslate_zinc_ore"}}
        }
    },
    {
        name = "Industrial Ores",
        color = colors.orange,
        ores = {
            {name = "Tin", blocks = {"thermal:tin_ore", "thermal:deepslate_tin_ore", "mekanism:tin_ore", "mekanism:deepslate_tin_ore"}},
            {name = "Lead", blocks = {"thermal:lead_ore", "thermal:deepslate_lead_ore", "mekanism:lead_ore", "mekanism:deepslate_lead_ore"}},
            {name = "Silver", blocks = {"thermal:silver_ore", "thermal:deepslate_silver_ore"}},
            {name = "Nickel", blocks = {"thermal:nickel_ore", "thermal:deepslate_nickel_ore"}},
            {name = "Aluminum", blocks = {"alltheores:aluminum_ore", "alltheores:deepslate_aluminum_ore"}}
        }
    },
    {
        name = "Common Ores",
        color = colors.lightGray,
        ores = {
            {name = "Iron", blocks = {"minecraft:iron_ore", "minecraft:deepslate_iron_ore"}},
            {name = "Copper", blocks = {"minecraft:copper_ore", "minecraft:deepslate_copper_ore"}},
            {name = "Coal", blocks = {"minecraft:coal_ore", "minecraft:deepslate_coal_ore"}},
            {name = "Redstone", blocks = {"minecraft:redstone_ore", "minecraft:deepslate_redstone_ore"}},
            {name = "Lapis", blocks = {"minecraft:lapis_ore", "minecraft:deepslate_lapis_ore"}}
        }
    },
    {
        name = "Nether Ores",
        color = colors.red,
        ores = {
            {name = "Ancient Debris", blocks = {"minecraft:ancient_debris"}},
            {name = "Nether Quartz", blocks = {"minecraft:nether_quartz_ore"}},
            {name = "Nether Gold", blocks = {"minecraft:nether_gold_ore"}},
            {name = "Gilded Blackstone", blocks = {"minecraft:gilded_blackstone"}}
        }
    }
}

---------------------------------------------------------------------
-- GLOBAL STATE & UTILITIES
---------------------------------------------------------------------
local current_menu = "main"
local selected_category = nil
local selected_ore = nil
local last_scan_results = {}
local player_pos = {x = 0, y = 0, z = 0}

local function clearScreen() term.clear(); term.setCursorPos(1, 1) end
local function safeFuelLevel() return geoscanner and geoscanner.getFuelLevel and geoscanner.getFuelLevel() or 999999 end
local function safeMaxFuelLevel() return geoscanner and geoscanner.getMaxFuelLevel and geoscanner.getMaxFuelLevel() or 999999 end
local function safeCost(radius) return geoscanner and geoscanner.cost and geoscanner.cost(radius) or 0 end

local function drawHeader()
    local w, _ = term.getSize()
    local x = math.floor((w - #("ATM10 ORE FINDER v" .. VERSION)) / 2) + 1
    term.setCursorPos(x, 1); term.write("ATM10 ORE FINDER v" .. VERSION)
    term.setCursorPos(1, 2); term.write(string.rep("-", w))
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
    term.setTextColor(colors.white)

    term.setCursorPos(1, 6); term.write("Select ore category:")
    local y = 8
    for i, category in ipairs(ORE_CATEGORIES) do
        term.setCursorPos(3, y); term.setTextColor(category.color); term.write(i .. ". " .. category.name); y = y + 1
    end
    term.setTextColor(colors.white)
    term.setCursorPos(1, y + 1); term.write("Enter number (1-" .. #ORE_CATEGORIES .. ") and press Enter, or 'q' to quit:")
    term.setCursorPos(1, y + 2); term.write("> ")
end

local function drawOreMenu()
    if not selected_category then return end
    clearScreen(); drawHeader()
    term.setCursorPos(1, 4); term.setTextColor(selected_category.color); term.write(selected_category.name)
    term.setTextColor(colors.white); term.setCursorPos(1, 6); term.write("Select an ore:")
    local y = 8
    for i, ore in ipairs(selected_category.ores) do
        term.setCursorPos(3, y); term.write(i .. ". " .. ore.name); y = y + 1
    end
    term.setCursorPos(1, y + 1); term.write("Enter number and press Enter, 'b' for back, or 'q' to quit:")
    term.setCursorPos(1, y + 2); term.write("> ")
end

local function drawScanResults()
    if not selected_ore or not last_scan_results then return end
    clearScreen(); drawHeader()
    local fuel, max_fuel, cost = safeFuelLevel(), safeMaxFuelLevel(), safeCost(SCAN_RADIUS)

    term.setCursorPos(1, 4); term.setTextColor(selected_category.color); term.write("Scanning: " .. selected_ore.name .. " (radius: " .. SCAN_RADIUS .. ")")
    term.setTextColor(colors.white)

    term.setCursorPos(1, 5)
    if fuel < cost and fuel < 999999 then
        term.setTextColor(colors.orange); term.write("Low fuel: " .. fuel .. "/" .. max_fuel .. " (need " .. cost .. ")")
    else
        term.setTextColor(colors.green)
        if fuel < 999999 then term.write("Fuel: " .. fuel .. "/" .. max_fuel)
        else term.write("Scanner ready") end
    end
    term.setTextColor(colors.white)

    if #last_scan_results == 0 then
        term.setCursorPos(1, 7); term.write("No " .. selected_ore.name .. " found within " .. SCAN_RADIUS .. " blocks.")
    else
        local closest = last_scan_results[1]
        local dx = closest.x and player_pos and player_pos.x and (closest.x - player_pos.x) or 0
        local dz = closest.z and player_pos and player_pos.z and (closest.z - player_pos.z) or 0
        local direction = "Unknown"
        if dx ~= 0 or dz ~= 0 then
            if math.abs(dx) > math.abs(dz) then direction = dx > 0 and "East (→)" or "West (←)"
            else direction = dz > 0 and "South (↓)" or "North (↑)" end
        else direction = "Here (●)" end

        term.setCursorPos(1, 7); term.write("Found " .. #last_scan_results .. " deposit(s).")
        term.setCursorPos(1, 9); term.write("CLOSEST DEPOSIT:")
        term.setCursorPos(3, 10); term.write("Direction: " .. direction)
        term.setCursorPos(3, 11); term.write("Distance:  " .. math.floor(closest.distance or 0) .. " blocks")
        term.setCursorPos(3, 12); term.write("Y-Level:   " .. tostring(closest.y or "?"))
    end
    local _, h = term.getSize(); term.setCursorPos(1, h - 1); term.write("'r' to rescan, 'b' for back, 'q' to quit (and press Enter)")
    term.setCursorPos(1, h); term.write("> ")
end

---------------------------------------------------------------------
-- SCANNING & INPUT LOGIC
---------------------------------------------------------------------
local function performScan()
    if not selected_ore then return end
    term.setCursorPos(1,1); term.write("Scanning...")
    last_scan_results = {}
    local all_blocks, _ = geoscanner.scan(SCAN_RADIUS)
    if all_blocks then
        local ore_lookup = {}; for _, name in ipairs(selected_ore.blocks) do ore_lookup[name] = true end
        for _, block in ipairs(all_blocks) do
            if block and block.name and ore_lookup[block.name] then
                local dist = math.sqrt((block.x^2) + (block.y^2) + (block.z^2)) -- Relative distance from player
                table.insert(last_scan_results, {distance=dist, x=block.x, y=block.y, z=block.z, block_name=block.name})
            end
        end
        table.sort(last_scan_results, function(a, b) return a.distance < b.distance end)
    end
    drawScanResults()
end

local function handleInput()
    local input = read()
    if current_menu == "main" then
        local choice = tonumber(input)
        if input == "q" then return false end
        if choice and choice >= 1 and choice <= #ORE_CATEGORIES then
            selected_category = ORE_CATEGORIES[choice]
            current_menu = "ore_select"
            drawOreMenu()
        else drawMainMenu() end

    elseif current_menu == "ore_select" then
        local choice = tonumber(input)
        if input == "q" then return false end
        if input == "b" then current_menu = "main"; drawMainMenu()
        elseif choice and choice >= 1 and choice <= #selected_category.ores then
            selected_ore = selected_category.ores[choice]
            current_menu = "scanning"
            performScan()
        else drawOreMenu() end

    elseif current_menu == "scanning" then
        if input == "q" then return false end
        if input == "b" then current_menu = "ore_select"; drawOreMenu()
        elseif input == "r" then performScan()
        else drawScanResults() end
    end
    return true
end

---------------------------------------------------------------------
-- MAIN PROGRAM
---------------------------------------------------------------------
local function main()
    drawMainMenu()
    local running = true
    while running do
        running = handleInput()
    end
    clearScreen(); print("Thanks for using ATM10 Ore Finder!")
end

local success, err = pcall(main)
if not success then
    clearScreen()
    print("A critical error occurred:")
    print(tostring(err))
end