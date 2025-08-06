---------------------------------------------------------------------
-- ATM10 ORE FINDER - Advanced Pocket Computer Geo Scanner App
-- v2.4-tracking-fixed - By CedarI, cleanup by Gemini
---------------------------------------------------------------------

-- CONFIGURATION
local SCAN_RADIUS = 16
local GPS_UPDATE_RATE = 0.5      -- Faster updates for smooth GPS tracking
local SCANNER_UPDATE_RATE = 2.0  -- Slower updates for rescan mode
local VERSION = "2.4-tracking-fixed"

---------------------------------------------------------------------
-- INITIALIZE PERIPHERALS
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
if has_gps then print("GPS system detected for live tracking.")
else print("Warning: No GPS. Tracking will use slower scanner mode.") end
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
    current_menu = "main", selected_category = nil, selected_ore = nil,
    last_scan_results = {}, player_pos = {x=0, y=0, z=0}, target_ore = nil
}

local function clearScreen() term.clear(); term.setCursorPos(1, 1) end
local function drawHeader(title)
    clearScreen(); local w, _ = term.getSize(); local x = math.floor((w - #title) / 2) + 1
    term.setCursorPos(x, 1); term.write(title); term.setCursorPos(1, 2); term.write(string.rep("-", w))
end

local function updatePlayerPosition()
    if has_gps then
        local x, y, z = gps.locate()
        if x then state.player_pos = {x=x, y=y, z=z}; return true end
    end
    state.player_pos = {x=0, y=0, z=0}; return false
end

---------------------------------------------------------------------
-- UI DRAWING FUNCTIONS
---------------------------------------------------------------------
local function drawMainMenu()
    drawHeader("Ore Finder - Main Menu"); term.setCursorPos(1, 4); term.write("Select ore category:")
    local y = 6; for i, c in ipairs(ORE_CATEGORIES) do term.setCursorPos(3, y); term.setTextColor(c.color); term.write(i .. ". " .. c.name); y = y + 1 end
    term.setTextColor(colors.white); local _, h = term.getSize(); term.setCursorPos(1, h); term.write("Press number to select, or 'q' to quit.")
end

local function drawOreMenu()
    drawHeader(state.selected_category.name); term.setCursorPos(1, 4); term.write("Select an ore:")
    local y = 6; for i, ore in ipairs(state.selected_category.ores) do term.setCursorPos(3, y); term.write(i .. ". " .. ore.name); y = y + 1 end
    local _, h = term.getSize(); term.setCursorPos(1, h); term.write("Press number, 'b' for back, or 'q' to quit.")
end

local function drawScanResults()
    drawHeader("Scan Results: " .. state.selected_ore.name)
    if #state.last_scan_results == 0 then
        term.setCursorPos(1, 4); term.write("No " .. state.selected_ore.name .. " found.")
    else
        local closest = state.last_scan_results[1]
        term.setCursorPos(1, 4); term.write("Found " .. #state.last_scan_results .. " deposit(s).")
        term.setCursorPos(1, 6); term.write("Closest Deposit:")
        term.setCursorPos(3, 7); term.write("Distance: " .. string.format("%.1f", closest.distance) .. " blocks")
        term.setCursorPos(3, 8); term.write("Y-Level:  " .. tostring(closest.y or "?"))
    end
    local _, h = term.getSize();
    term.setCursorPos(1, h); term.write("Press 't' to track, 'r' to rescan, 'b' back.")
end

local function updateTrackingScreen(dist, dir_x, dir_z, dir_y)
    local w, h = term.getSize()
    for y = 4, h - 2 do term.setCursorPos(1, y); term.write(string.rep(" ", w)) end

    local mode = has_gps and "GPS Mode" or "Scanner Mode"
    term.setCursorPos(1, 4); term.write("Tracking: " .. state.target_ore.block_name .. " ("..mode..")")
    term.setCursorPos(1, 6); term.write(string.format("Dist: %.1fm | X: %+.1f | Y: %+.1f | Z: %+.1f", dist, dir_x, dir_y, dir_z))

    local arrow_y = math.floor(h/2) - 1
    local arrow_x = math.floor(w/2) - 3

    if dist < 2.5 then
        term.setTextColor(colors.lime)
        term.setCursorPos(arrow_x + 1, arrow_y + 1); term.write(" [HERE] ")
    else
        term.setTextColor(colors.yellow)
        if math.abs(dir_z) > math.abs(dir_x) then -- North/South is dominant
            if dir_z < 0 then -- North
                term.setCursorPos(arrow_x+2, arrow_y+0); term.write(" ^ ")
                term.setCursorPos(arrow_x+1, arrow_y+1); term.write("/_\\")
            else -- South
                term.setCursorPos(arrow_x+1, arrow_y+0); term.write("\\_/")
                term.setCursorPos(arrow_x+2, arrow_y+1); term.write(" v ")
            end
        else -- East/West is dominant
            if dir_x < 0 then -- West
                term.setCursorPos(arrow_x+0, arrow_y+0); term.write(" <' ")
                term.setCursorPos(arrow_x+0, arrow_y+1); term.write(" <. ")
            else -- East
                term.setCursorPos(arrow_x+3, arrow_y+0); term.write(" '> ")
                term.setCursorPos(arrow_x+3, arrow_y+1); term.write(" .> ")
            end
        end
    end
    term.setTextColor(colors.white)
end

---------------------------------------------------------------------
-- LOGIC & INPUT HANDLING
---------------------------------------------------------------------
local function performScan(is_silent)
    if not is_silent then term.setCursorPos(1, 4); term.write("Scanning...") end
    state.last_scan_results = {}
    updatePlayerPosition()
    local all_blocks, _ = geoscanner.scan(SCAN_RADIUS)
    if all_blocks then
        local ore_lookup = {}; for _, n in ipairs(state.selected_ore.blocks) do ore_lookup[n] = true end
        for _, block in ipairs(all_blocks) do
            if block and block.name and ore_lookup[block.name] then
                local abs_x, abs_y, abs_z = nil, nil, nil
                if has_gps then abs_x, abs_y, abs_z = state.player_pos.x + block.x, state.player_pos.y + block.y, state.player_pos.z + block.z end
                local dist = math.sqrt((block.x^2) + (block.y^2) + (block.z^2))
                table.insert(state.last_scan_results, {distance=dist, x=block.x, y=block.y, z=block.z, block_name=block.name, abs_pos={x=abs_x, y=abs_y, z=abs_z}})
            end
        end
        table.sort(state.last_scan_results, function(a, b) return a.distance < b.distance end)
    end
    if not is_silent then drawScanResults() end
end

local function mainLoop()
    while true do
        local event, key = os.pullEvent("char")
        if key == "q" then state.current_menu = "quit"; break end

        if state.current_menu == "main" then
            local choice = tonumber(key)
            if choice and choice >= 1 and choice <= #ORE_CATEGORIES then
                state.selected_category = ORE_CATEGORIES[choice]; state.current_menu = "ore_select"; drawOreMenu()
            end
        elseif state.current_menu == "ore_select" then
            if key == "b" then state.current_menu = "main"; drawMainMenu(); goto continue end
            local choice = tonumber(key)
            if choice and choice >= 1 and choice <= #state.selected_category.ores then
                state.selected_ore = state.selected_category.ores[choice]; state.current_menu = "scanning"; performScan(false)
            end
        elseif state.current_menu == "scanning" then
            if key == "b" then state.current_menu = "ore_select"; drawOreMenu()
            elseif key == "r" then performScan(false)
            elseif key == "t" and #state.last_scan_results > 0 then
                state.target_ore = state.last_scan_results[1]; state.current_menu = "tracking"; break
            end
        end
        ::continue::
    end
end

local function trackingLoop()
    drawHeader("Live Tracking Mode")
    local _, h = term.getSize(); term.setCursorPos(1, h); term.write("Press 'b' or 'q' to stop tracking.")

    local update_rate = has_gps and GPS_UPDATE_RATE or SCANNER_UPDATE_RATE
    local timer = os.startTimer(update_rate)
    local target_lost = false

    -- Initial Draw
    if has_gps then
        updatePlayerPosition()
        local target_pos = state.target_ore.abs_pos
        local dir_x = target_pos.x - state.player_pos.x
        local dir_y = target_pos.y - state.player_pos.y
        local dir_z = target_pos.z - state.player_pos.z
        local dist = math.sqrt(dir_x^2 + dir_y^2 + dir_z^2)
        updateTrackingScreen(dist, dir_x, dir_z, dir_y)
    else
        updateTrackingScreen(state.target_ore.distance, state.target_ore.x, state.target_ore.z, state.target_ore.y)
    end

    while state.current_menu == "tracking" do
        local event, p1 = os.pullEvent()
        if (event == "char" and (p1 == "b" or p1 == "q")) then
            state.current_menu = "scanning"; drawScanResults(); break
        elseif event == "timer" and p1 == timer then
            if has_gps then
                updatePlayerPosition()
                local target_pos = state.target_ore.abs_pos
                local dir_x = target_pos.x - state.player_pos.x
                local dir_y = target_pos.y - state.player_pos.y
                local dir_z = target_pos.z - state.player_pos.z
                local dist = math.sqrt(dir_x^2 + dir_y^2 + dir_z^2)
                updateTrackingScreen(dist, dir_x, dir_z, dir_y)
            else
                performScan(true) -- Silent scan for non-GPS mode
                if #state.last_scan_results > 0 then
                    target_lost = false
                    local new_closest = state.last_scan_results[1]
                    updateTrackingScreen(new_closest.distance, new_closest.x, new_closest.z, new_closest.y)
                elseif not target_lost then
                    target_lost = true
                    term.setCursorPos(1, 8); term.setTextColor(colors.red); term.write("Target lost!")
                end
            end
            timer = os.startTimer(update_rate)
        end
    end
end

-- MAIN PROGRAM EXECUTION
drawMainMenu()
while state.current_menu ~= "quit" do
    if state.current_menu == "tracking" then
        trackingLoop()
    else
        mainLoop()
    end
end

clearScreen(); print("Thanks for using ATM10 Ore Finder!")