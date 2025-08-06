---------------------------------------------------------------------
-- ATM10 ORE FINDER - Advanced Pocket Computer Geo Scanner App
-- v2.9-final - By CedarI, cleanup by Gemini
---------------------------------------------------------------------

-- CONFIGURATION
local SCAN_RADIUS = 16
local GPS_UPDATE_RATE = 0.5
local SCANNER_UPDATE_RATE = 2.0
local VERSION = "2.9-final"
local W, H = 26, 20 -- Advanced Pocket Computer Screen Size

---------------------------------------------------------------------
-- INITIALIZE PERIPHERALS
---------------------------------------------------------------------
term.clear(); term.setCursorPos(1,1)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)

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
    print("ERROR: No geo scanner found!")
    return
end
print("Geo scanner ready.")

-- *** ROBUST NON-BLOCKING GPS CHECK ***
local has_gps = false
print("Checking for active GPS...")
if gps and gps.locate then
    -- Run a short, timed check in parallel to prevent the program from hanging.
    parallel.waitForAny(
            function()
                local x, _, _ = gps.locate()
                if x then has_gps = true end
            end,
            function()
                os.sleep(0.2)
            end
    )
end

if has_gps then
    print("GPS system detected.")
else
    print("No active GPS modem found.")
end
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
    }},
    { name = "Technology Ores", color = colors.cyan, ores = {
        {name = "Certus Quartz", blocks = {"ae2:certus_quartz_ore"}},
        {name = "Osmium", blocks = {"mekanism:osmium_ore"}},
        {name = "Uranium", blocks = {"mekanism:uranium_ore"}},
    }},
    { name = "Common Ores", color = colors.lightGray, ores = {
        {name = "Iron", blocks = {"minecraft:iron_ore"}},
        {name = "Coal", blocks = {"minecraft:coal_ore"}},
    }},
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
    clearScreen(); local x = math.floor((W - #title) / 2) + 1
    term.setCursorPos(x, 1); term.write(title); term.setCursorPos(1, 2); term.write(string.rep("-", W-1))
end

local function updatePlayerPosition()
    if has_gps then
        local x, y, z = gps.locate()
        if x then state.player_pos = {x=x, y=y, z=z} end
    end
end

---------------------------------------------------------------------
-- UI DRAWING FUNCTIONS
---------------------------------------------------------------------
local function drawMainMenu()
    drawHeader("Ore Finder - Main Menu")
    term.setCursorPos(1, 4); term.write("Select ore category:")
    local y = 6; for i, c in ipairs(ORE_CATEGORIES) do term.setCursorPos(3, y); term.setTextColor(c.color); term.write(i .. ". " .. c.name); y = y + 1 end
    term.setTextColor(colors.white); term.setCursorPos(1, H); term.write("Press number or 'q' to quit")
end

local function drawOreMenu()
    drawHeader(state.selected_category.name)
    term.setCursorPos(1, 4); term.write("Select an ore:")
    local y = 6; for i, ore in ipairs(state.selected_category.ores) do term.setCursorPos(3, y); term.write(i .. ". " .. ore.name); y = y + 1 end
    term.setCursorPos(1, H); term.write("Press number, 'b' back, 'q' quit")
end

local function drawScanResults()
    drawHeader("Scan: " .. state.selected_ore.name)
    if #state.last_scan_results == 0 then
        term.setCursorPos(1, 5); term.write("No " .. state.selected_ore.name .. " found.")
    else
        local c = state.last_scan_results[1]
        term.setCursorPos(1, 5); term.write("Found " .. #state.last_scan_results .. " deposit(s).")
        term.setCursorPos(1, 7); term.write("Closest:")
        term.setCursorPos(3, 8); term.write("Dist: " .. string.format("%.1f", c.dist) .. "m | Y: " .. tostring(c.y or "?"))
    end
    term.setCursorPos(1, H); term.write("'t' track, 'r' rescan, 'b' back")
end

local function updateTrackingScreen(dist, dx, dz, dy)
    for y = 4, H - 2 do term.setCursorPos(1, y); term.write(string.rep(" ", W)) end

    local mode = has_gps and "(GPS)" or "(Scanner)"
    term.setCursorPos(1, 4); term.write("Tracking: " .. state.target_ore.name .. " " .. mode)
    term.setCursorPos(1, 6); term.write(string.format("Dist: %.1fm", dist))
    term.setCursorPos(1, 7); term.write(string.format("X:%+.1f Y:%+.1f Z:%+.1f", dx, dy, dz))

    local ay, ax = math.floor(H/2), math.floor(W/2) - 2
    if dist < 2.5 then
        term.setTextColor(colors.lime); term.setCursorPos(ax-2, ay); term.write("[  HERE  ]")
    else
        term.setTextColor(colors.yellow)
        if math.abs(dz) > math.abs(dx) then
            term.setCursorPos(ax, ay-1); term.write(dz<0 and "   ^   " or "       ")
            term.setCursorPos(ax, ay+0); term.write(dz<0 and "  / \\  " or "  \\ /  ")
            term.setCursorPos(ax, ay+1); term.write(dz<0 and " /___\\ " or "   V   ")
        else
            term.setCursorPos(ax-2, ay); term.write(dx<0 and "<<< " or " >>>")
        end
    end
    term.setTextColor(colors.white)
end

---------------------------------------------------------------------
-- LOGIC & INPUT HANDLING
---------------------------------------------------------------------
local function performScan(is_silent)
    if not is_silent then term.setCursorPos(1, 5); term.write("Scanning...") end
    state.last_scan_results = {}
    local all_blocks, _ = geoscanner.scan(SCAN_RADIUS)
    if all_blocks then
        local ore_lookup = {}; for _, n in ipairs(state.selected_ore.blocks) do ore_lookup[n] = true end
        for _, block in ipairs(all_blocks) do
            if block and block.name and ore_lookup[block.name] then
                updatePlayerPosition()
                local abs_x, abs_y, abs_z = nil
                if has_gps then abs_x, abs_y, abs_z = state.player_pos.x+block.x, state.player_pos.y+block.y, state.player_pos.z+block.z end
                local dist = math.sqrt(block.x^2 + block.y^2 + block.z^2)
                table.insert(state.last_scan_results, {dist=dist, x=block.x, y=block.y, z=block.z, name=block.name, abs={x=abs_x,y=abs_y,z=abs_z}})
            end
        end
        table.sort(state.last_scan_results, function(a, b) return a.dist < b.dist end)
    end
    if not is_silent then drawScanResults() end
end

local function mainLoop()
    while true do
        local _, key = os.pullEvent("char")
        if key == "q" then state.current_menu = "quit"; break end
        if state.current_menu == "main" then
            local c = tonumber(key)
            if c and ORE_CATEGORIES[c] then state.selected_category=ORE_CATEGORIES[c]; state.current_menu="ore_select"; drawOreMenu() end
        elseif state.current_menu == "ore_select" then
            if key == "b" then state.current_menu="main"; drawMainMenu(); goto next_event end
            local c = tonumber(key)
            if c and state.selected_category.ores[c] then state.selected_ore=state.selected_category.ores[c]; state.current_menu="scanning"; performScan(false) end
        elseif state.current_menu == "scanning" then
            if key == "b" then state.current_menu="ore_select"; drawOreMenu()
            elseif key == "r" then performScan(false)
            elseif key == "t" and #state.last_scan_results > 0 then
                state.target_ore={name=state.selected_ore.name, block_name=state.last_scan_results[1].name, abs=state.last_scan_results[1].abs}; state.current_menu="tracking"; break
            end
        end
        ::next_event::
    end
end

local function trackingLoop()
    drawHeader("Live Tracker")
    local update_rate = has_gps and GPS_UPDATE_RATE or SCANNER_UPDATE_RATE
    local timer = os.startTimer(0)
    local target_lost = false

    local function update()
        if has_gps then
            updatePlayerPosition()
            local t = state.target_ore.abs
            local dx, dy, dz = t.x-state.player_pos.x, t.y-state.player_pos.y, t.z-state.player_pos.z
            updateTrackingScreen(math.sqrt(dx^2+dy^2+dz^2), dx, dz, dy)
        else
            performScan(true)
            if #state.last_scan_results > 0 then
                target_lost=false; local c=state.last_scan_results[1]; updateTrackingScreen(c.dist, c.x, c.z, c.y)
            elseif not target_lost then
                target_lost=true; term.setCursorPos(1,9); term.setTextColor(colors.red); term.write("Target lost!")
            end
        end
    end

    while true do
        local event, p1 = os.pullEvent()
        if event == "timer" and p1 == timer then
            update()
            timer = os.startTimer(update_rate)
        elseif event == "char" and (p1 == "b" or p1 == "q") then
            state.current_menu = "scanning"; drawScanResults(); break
        end
    end
end

-- MAIN PROGRAM
while state.current_menu ~= "quit" do
    if state.current_menu == "tracking" then trackingLoop()
    else mainLoop() end
end

clearScreen(); print("Thanks for using ATM10 Ore Finder!")