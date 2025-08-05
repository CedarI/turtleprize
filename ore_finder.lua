---------------------------------------------------------------------
-- ATM10 ORE FINDER - Advanced Pocket Computer Geo Scanner App
-- v1.9-trackingfix - By CedarI, cleanup by Gemini
---------------------------------------------------------------------

-- CONFIGURATION
local SCAN_RADIUS = 16
local TRACKING_UPDATE_RATE = 0.5
local VERSION = "1.9-trackingfix"

---------------------------------------------------------------------
-- INITIALIZE GEO SCANNER & GPS
---------------------------------------------------------------------
term.clear(); term.setCursorPos(1,1)
print("ATM10 Ore Finder v" .. VERSION)
print("Looking for geo scanner...")

local geoscanner = peripheral.wrap("back")
if not (geoscanner and geoscanner.scan) then
    local sides = {"front", "left", "right", "top", "bottom"}
    for _, side in ipairs(sides) do
        if peripheral.getType(side) and peripheral.getType(side):find("geo") then
            geoscanner = peripheral.wrap(side); break
        end
    end
end

if not (geoscanner and geoscanner.scan) then
    print("ERROR: Could not find a functional geo scanner!")
    return
end
print("Geo scanner ready.")

local has_gps = gps and gps.locate
if has_gps then print("GPS system detected.")
else print("Warning: No GPS. Tracking will be less accurate.") end
os.sleep(1.5)

---------------------------------------------------------------------
-- ORE DEFINITIONS
---------------------------------------------------------------------
local ORE_CATEGORIES = {
    { name = "ATM Special Ores", color = colors.purple, ores = {
        {name = "Allthemodium", blocks = {"allthemodium:allthemodium_ore"}},
        {name = "Vibranium", blocks = {"allthemodium:vibranium_ore"}},
        {name = "Unobtainium", blocks = {"allthemodium:unobtainium_ore"}},
    }},
    { name = "Precious Ores", color = colors.yellow, ores = {
        {name = "Diamond", blocks = {"minecraft:diamond_ore", "minecraft:deepslate_diamond_ore"}},
        {name = "Emerald", blocks = {"minecraft:emerald_ore", "minecraft:deepslate_emerald_ore"}},
        {name = "Ancient Debris", blocks = {"minecraft:ancient_debris"}},
        {name = "Gold", blocks = {"minecraft:gold_ore", "minecraft:deepslate_gold_ore", "minecraft:nether_gold_ore"}},
    }},
    { name = "Technology Ores", color = colors.cyan, ores = {
        {name = "Certus Quartz", blocks = {"ae2:certus_quartz_ore", "ae2:deepslate_certus_quartz_ore"}},
        {name = "Osmium", blocks = {"mekanism:osmium_ore", "mekanism:deepslate_osmium_ore"}},
        {name = "Uranium", blocks = {"mekanism:uranium_ore", "mekanism:deepslate_uranium_ore"}},
    }},
    { name = "Industrial Ores", color = colors.orange, ores = {
        {name = "Tin", blocks = {"thermal:tin_ore", "thermal:deepslate_tin_ore", "mekanism:tin_ore"}},
        {name = "Lead", blocks = {"thermal:lead_ore", "thermal:deepslate_lead_ore", "mekanism:lead_ore"}},
        {name = "Silver", blocks = {"thermal:silver_ore", "thermal:deepslate_silver_ore"}},
        {name = "Nickel", blocks = {"thermal:nickel_ore", "thermal:deepslate_nickel_ore"}},
    }},
    { name = "Common Ores", color = colors.lightGray, ores = {
        {name = "Iron", blocks = {"minecraft:iron_ore", "minecraft:deepslate_iron_ore"}},
        {name = "Copper", blocks = {"minecraft:copper_ore", "minecraft:deepslate_copper_ore"}},
        {name = "Coal", blocks = {"minecraft:coal_ore", "minecraft:deepslate_coal_ore"}},
        {name = "Redstone", blocks = {"minecraft:redstone_ore", "minecraft:deepslate_redstone_ore"}},
    }},
    { name = "Nether Ores", color = colors.red, ores = {
        {name = "Ancient Debris", blocks = {"minecraft:ancient_debris"}},
        {name = "Nether Quartz", blocks = {"minecraft:nether_quartz_ore"}},
        {name = "Nether Gold", blocks = {"minecraft:nether_gold_ore"}},
    }}
}

---------------------------------------------------------------------
-- GLOBAL STATE & UTILITIES
---------------------------------------------------------------------
local state = {
    current_menu = "main",
    selected_category = nil,
    selected_ore = nil,
    last_scan_results = {},
    player_pos = {x=0, y=0, z=0},
    target_ore = nil
}

local function clearScreen() term.clear(); term.setCursorPos(1, 1) end

local function drawHeader(title)
    clearScreen()
    local w, _ = term.getSize()
    local x = math.floor((w - #title) / 2) + 1
    term.setCursorPos(x, 1); term.write(title)
    term.setCursorPos(1, 2); term.write(string.rep("-", w))
end

local function updatePlayerPosition()
    if has_gps then
        local x, y, z = gps.locate()
        if x then state.player_pos = {x=x, y=y, z=z}; return end
    end
    state.player_pos = {x=0, y=0, z=0}
end

---------------------------------------------------------------------
-- UI DRAWING FUNCTIONS
---------------------------------------------------------------------
local function drawMainMenu()
    drawHeader("Ore Finder - Main Menu")
    term.setCursorPos(1, 4); term.write("Select ore category:")
    local y = 6
    for i, category in ipairs(ORE_CATEGORIES) do
        term.setCursorPos(3, y); term.setTextColor(category.color); term.write(i .. ". " .. category.name); y = y + 1
    end
    term.setTextColor(colors.white)
    local _, h = term.getSize(); term.setCursorPos(1, h); term.write("Press number to select, or 'q' to quit.")
end

local function drawOreMenu()
    drawHeader(state.selected_category.name)
    term.setCursorPos(1, 4); term.write("Select an ore:")
    local y = 6
    for i, ore in ipairs(state.selected_category.ores) do
        term.setCursorPos(3, y); term.write(i .. ". " .. ore.name); y = y + 1
    end
    local _, h = term.getSize(); term.setCursorPos(1, h); term.write("Press number, 'b' for back, or 'q' to quit.")
end

local function drawScanResults()
    drawHeader("Scan Results for " .. state.selected_ore.name)
    if #state.last_scan_results == 0 then
        term.setCursorPos(1, 4); term.write("No " .. state.selected_ore.name .. " found.")
    else
        local closest = state.last_scan_results[1]
        term.setCursorPos(1, 4); term.write("Found " .. #state.last_scan_results .. " deposit(s).")
        term.setCursorPos(1, 6); term.write("Closest Deposit:")
        term.setCursorPos(3, 7); term.write("Distance: " .. string.format("%.1f", closest.distance) .. " blocks")
        term.setCursorPos(3, 8); term.write("Y-Level:  " .. tostring(closest.y or "?"))
    end
    local _, h = term.getSize(); term.setCursorPos(1, h); term.write("Press 't' to track, 'r' to rescan, 'b' back.")
end

local function updateTrackingScreen(dist, dir_x, dir_z)
    local w, h = term.getSize()
    for y = 4, h - 2 do term.setCursorPos(1, y); term.write(string.rep(" ", w)) end

    term.setCursorPos(1, 4); term.write("Tracking: " .. state.target_ore.block_name)
    term.setCursorPos(1, 6); term.write("Distance: " .. string.format("%.1f", dist) .. "m")

    local arrow_y = math.floor(h/2) - 1
    local arrow_x = math.floor(w/2)
    term.setCursorPos(arrow_x, arrow_y)

    if dist < 2.0 then
        term.setTextColor(colors.lime)
        term.setCursorPos(arrow_x - 4, arrow_y); term.write("[ HERE ]")
    elseif math.abs(dir_z) > math.abs(dir_x) then
        term.write(dir_z < 0 and "↑" or "↓")
    else
        term.write(dir_x < 0 and "←" or "→")
    end
    term.setTextColor(colors.white)
end

---------------------------------------------------------------------
-- LOGIC & INPUT HANDLING
---------------------------------------------------------------------
local function performScan()
    term.setCursorPos(1, 4); term.write("Scanning...")
    state.last_scan_results = {}
    updatePlayerPosition()
    local all_blocks, _ = geoscanner.scan(SCAN_RADIUS)
    if all_blocks then
        local ore_lookup = {}; for _, name in ipairs(state.selected_ore.blocks) do ore_lookup[name] = true end
        for _, block in ipairs(all_blocks) do
            if block and block.name and ore_lookup[block.name] then
                local abs_x = has_gps and state.player_pos.x + block.x or nil
                local abs_y = has_gps and state.player_pos.y + block.y or nil
                local abs_z = has_gps and state.player_pos.z + block.z or nil
                local dist = math.sqrt((block.x^2) + (block.y^2) + (block.z^2))
                table.insert(state.last_scan_results, {distance=dist, x=block.x, y=block.y, z=block.z, block_name=block.name, abs_pos={x=abs_x, y=abs_y, z=abs_z}})
            end
        end
        table.sort(state.last_scan_results, function(a, b) return a.distance < b.distance end)
    end
    drawScanResults()
end

local function calculateInitialTracking()
    updatePlayerPosition()
    local target = state.target_ore
    local dist, dir_x, dir_z
    if has_gps and target.abs_pos.x then
        dir_x = target.abs_pos.x - state.player_pos.x
        dir_z = target.abs_pos.z - state.player_pos.z
        dist = math.sqrt(dir_x^2 + (target.abs_pos.y - state.player_pos.y)^2 + dir_z^2)
    else
        dist, dir_x, dir_z = target.distance, target.x, target.z
    end
    updateTrackingScreen(dist, dir_x, dir_z)
end

local function mainLoop()
    while true do
        local event, key = os.pullEvent("char")
        if key == "q" then state.current_menu = "quit"; break end

        if state.current_menu == "main" then
            local choice = tonumber(key)
            if choice and choice >= 1 and choice <= #ORE_CATEGORIES then
                state.selected_category = ORE_CATEGORIES[choice]
                state.current_menu = "ore_select"; drawOreMenu()
            end
        elseif state.current_menu == "ore_select" then
            if key == "b" then state.current_menu = "main"; drawMainMenu(); goto continue end
            local choice = tonumber(key)
            if choice and choice >= 1 and choice <= #state.selected_category.ores then
                state.selected_ore = state.selected_category.ores[choice]
                state.current_menu = "scanning"; performScan()
            end
        elseif state.current_menu == "scanning" then
            if key == "b" then state.current_menu = "ore_select"; drawOreMenu()
            elseif key == "r" then performScan()
            elseif key == "t" and #state.last_scan_results > 0 then
                state.target_ore = state.last_scan_results[1]
                state.current_menu = "tracking"
                drawHeader("Live Tracking Mode")
                local _, h = term.getSize(); term.setCursorPos(1, h); term.write("Press 'b' or 'q' to stop tracking.")
                calculateInitialTracking()
                break -- Exit mainLoop to enter trackingLoop
            end
        end
        ::continue::
    end
end

local function trackingLoop()
    local timer = os.startTimer(TRACKING_UPDATE_RATE)
    while state.current_menu == "tracking" do
        local event, p1 = os.pullEvent()
        if (event == "char" and (p1 == "b" or p1 == "q")) or (event == "key" and (p1 == keys.b or p1 == keys.q)) then
            state.current_menu = "scanning"; drawScanResults(); break
        elseif event == "timer" and p1 == timer then
            calculateInitialTracking() -- This function works for updates too
            timer = os.startTimer(TRACKING_UPDATE_RATE)
        end
    end
end

-- MAIN PROGRAM
drawMainMenu()
while state.current_menu ~= "quit" do
    if state.current_menu == "tracking" then
        trackingLoop()
    else
        mainLoop()
    end
end

clearScreen(); print("Thanks for using ATM10 Ore Finder!")