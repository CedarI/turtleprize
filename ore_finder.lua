---------------------------------------------------------------------
-- ATM10 ORE FINDER - Advanced Pocket Computer Geo Scanner App
-- Requires: Advanced Pocket Computer + Geo Scanner from Advanced Peripherals
---------------------------------------------------------------------

-- CONFIGURATION
local SCAN_RADIUS = 64 -- Maximum scan radius (adjust based on performance)
local REFRESH_RATE = 2 -- Seconds between scans
local VERSION = "1.0"

-- Check for geo scanner - simplified approach since we know it's on "back"
local geo = nil

print("Looking for geo scanner...")

-- Try wrapping the back peripheral directly
geo = peripheral.wrap("back")

if geo and geo.scan then
    print("Geo scanner found on back and functional!")
elseif geo then
    print("Peripheral found on back but no scan function available")
    print("Available methods:", table.concat(peripheral.getMethods("back"), ", "))
    geo = nil
else
    print("No peripheral found on back")
    
    -- Fallback: try other locations and names
    local possible_sides = {"front", "left", "right", "top", "bottom"}
    
    for _, side in ipairs(possible_sides) do
        local p_type = peripheral.getType(side)
        if p_type and (p_type == "geo_scanner" or p_type:find("geo")) then
            geo = peripheral.wrap(side)
            if geo and geo.scan then
                print("Found geo scanner on " .. side)
                break
            else
                geo = nil
            end
        end
    end
end

-- Final error handling
if not geo then
    print("ERROR: Could not initialize geo scanner!")
    print("")
    print("Debug information:")
    print("Back peripheral type:", peripheral.getType("back") or "none")
    if peripheral.getType("back") then
        print("Back peripheral methods:", table.concat(peripheral.getMethods("back"), ", "))
    end
    print("")
    print("All peripherals:")
    local all_peripherals = peripheral.getNames()
    for _, name in ipairs(all_peripherals) do
        local p_type = peripheral.getType(name)
        print("  " .. name .. " - " .. (p_type or "unknown"))
    end
    print("")
    print("Manual test: Try running these commands:")
    print("lua> geo = peripheral.wrap('back')")
    print("lua> print(geo)")
    print("lua> print(geo.scan)")
    return
end

-- ATM10 VALUABLE ORES DATABASE
local ORE_CATEGORIES = {
    ["ATM Special"] = {
        name = "ATM Special Ores",
        color = colors.purple,
        ores = {
            {name = "Allthemodium", blocks = {"allthemodium:allthemodium_ore"}},
            {name = "Vibranium", blocks = {"allthemodium:vibranium_ore"}},
            {name = "Unobtainium", blocks = {"allthemodium:unobtainium_ore"}},
        }
    },
    ["Precious"] = {
        name = "Precious Ores", 
        color = colors.yellow,
        ores = {
            {name = "Diamond", blocks = {"minecraft:diamond_ore", "minecraft:deepslate_diamond_ore"}},
            {name = "Emerald", blocks = {"minecraft:emerald_ore", "minecraft:deepslate_emerald_ore"}},
            {name = "Ancient Debris", blocks = {"minecraft:ancient_debris"}},
            {name = "Gold", blocks = {"minecraft:gold_ore", "minecraft:deepslate_gold_ore", "minecraft:nether_gold_ore"}},
        }
    },
    ["Tech Ores"] = {
        name = "Technology Ores",
        color = colors.cyan,
        ores = {
            {name = "Certus Quartz", blocks = {"ae2:certus_quartz_ore", "ae2:deepslate_certus_quartz_ore"}},
            {name = "Osmium", blocks = {"mekanism:osmium_ore", "mekanism:deepslate_osmium_ore"}},
            {name = "Uranium", blocks = {"mekanism:uranium_ore", "mekanism:deepslate_uranium_ore"}},
            {name = "Fluorite", blocks = {"mekanism:fluorite_ore", "mekanism:deepslate_fluorite_ore"}},
            {name = "Zinc", blocks = {"create:zinc_ore", "create:deepslate_zinc_ore", "alltheores:zinc_ore"}},
        }
    },
    ["Industrial"] = {
        name = "Industrial Ores",
        color = colors.orange,
        ores = {
            {name = "Tin", blocks = {"thermal:tin_ore", "thermal:deepslate_tin_ore", "mekanism:tin_ore", "mekanism:deepslate_tin_ore", "alltheores:tin_ore"}},
            {name = "Lead", blocks = {"thermal:lead_ore", "thermal:deepslate_lead_ore", "mekanism:lead_ore", "mekanism:deepslate_lead_ore", "alltheores:lead_ore"}},
            {name = "Silver", blocks = {"thermal:silver_ore", "thermal:deepslate_silver_ore", "alltheores:silver_ore"}},
            {name = "Nickel", blocks = {"thermal:nickel_ore", "thermal:deepslate_nickel_ore", "alltheores:nickel_ore"}},
            {name = "Aluminum", blocks = {"alltheores:aluminum_ore"}},
        }
    },
    ["Common"] = {
        name = "Common Ores",
        color = colors.lightGray,
        ores = {
            {name = "Iron", blocks = {"minecraft:iron_ore", "minecraft:deepslate_iron_ore"}},
            {name = "Copper", blocks = {"minecraft:copper_ore", "minecraft:deepslate_copper_ore"}},
            {name = "Coal", blocks = {"minecraft:coal_ore", "minecraft:deepslate_coal_ore"}},
            {name = "Redstone", blocks = {"minecraft:redstone_ore", "minecraft:deepslate_redstone_ore"}},
            {name = "Lapis", blocks = {"minecraft:lapis_ore", "minecraft:deepslate_lapis_ore"}},
        }
    },
    ["Nether"] = {
        name = "Nether Ores",
        color = colors.red,
        ores = {
            {name = "Ancient Debris", blocks = {"minecraft:ancient_debris"}},
            {name = "Nether Quartz", blocks = {"minecraft:nether_quartz_ore"}},
            {name = "Nether Gold", blocks = {"minecraft:nether_gold_ore"}},
            {name = "Gilded Blackstone", blocks = {"minecraft:gilded_blackstone"}},
        }
    }
}

-- GLOBAL STATE
local current_menu = "main"
local selected_category = nil
local selected_ore = nil
local last_scan_results = {}
local scan_timer = nil
local player_pos = {x = 0, y = 0, z = 0}

-- UTILITY FUNCTIONS
local function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

local function centerText(text, y)
    local w, h = term.getSize()
    local x = math.floor((w - #text) / 2) + 1
    term.setCursorPos(x, y)
    term.write(text)
end

local function drawHeader()
    local w, h = term.getSize()
    centerText("ATM10 ORE FINDER v" .. VERSION, 1)
    centerText(string.rep("-", w), 2)
end

local function updatePlayerPosition()
    local x, y, z = gps.locate()
    if x and y and z then
        player_pos = {x = x, y = y, z = z}
        return true
    else
        -- GPS not available - use relative positioning from (0,0,0)
        -- The geo scanner works with relative coordinates anyway
        player_pos = {x = 0, y = 0, z = 0}
        return true
    end
end

-- DIRECTION CALCULATION
local function calculateDistance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

local function calculateDirection(dx, dz)
    local angle = math.atan2(dz, dx)
    local degrees = math.deg(angle)
    
    -- Convert to 0-360 range
    if degrees < 0 then degrees = degrees + 360 end
    
    -- Convert to 8-directional arrows
    local directions = {
        {arrow = "→", name = "East"},     -- 0°
        {arrow = "↘", name = "SE"},       -- 45°
        {arrow = "↓", name = "South"},    -- 90°
        {arrow = "↙", name = "SW"},       -- 135°
        {arrow = "←", name = "West"},     -- 180°
        {arrow = "↖", name = "NW"},       -- 225°
        {arrow = "↑", name = "North"},    -- 270°
        {arrow = "↗", name = "NE"},       -- 315°
    }
    
    local sector = math.floor((degrees + 22.5) / 45) % 8
    return directions[sector + 1]
end

-- SCANNING FUNCTIONS
local function scanForOres(ore_blocks)
    if not updatePlayerPosition() then
        return nil, "Cannot determine position"
    end
    
    local results = {}
    
    -- Scan for each block type
    for _, block_name in ipairs(ore_blocks) do
        local blocks = geo.scan(SCAN_RADIUS, block_name)
        if blocks and #blocks > 0 then
            for _, block in ipairs(blocks) do
                local distance = calculateDistance(
                    player_pos.x, player_pos.y, player_pos.z,
                    block.x, block.y, block.z
                )
                table.insert(results, {
                    x = block.x,
                    y = block.y, 
                    z = block.z,
                    distance = distance,
                    block_name = block_name
                })
            end
        end
    end
    
    -- Sort by distance
    table.sort(results, function(a, b) return a.distance < b.distance end)
    
    return results
end

-- UI DRAWING FUNCTIONS
local function drawMainMenu()
    clearScreen()
    drawHeader()
    
    term.setCursorPos(1, 4)
    term.write("Select ore category:")
    
    local y = 6
    local index = 1
    for key, category in pairs(ORE_CATEGORIES) do
        term.setCursorPos(3, y)
        term.setTextColor(category.color)
        term.write(index .. ". " .. category.name)
        term.setTextColor(colors.white)
        y = y + 1
        index = index + 1
    end
    
    term.setCursorPos(1, y + 1)
    term.write("Enter number (1-" .. (#ORE_CATEGORIES) .. ") or 'q' to quit:")
end

local function drawOreMenu()
    if not selected_category then return end
    
    clearScreen()
    drawHeader()
    
    term.setCursorPos(1, 4)
    term.setTextColor(selected_category.color)
    term.write(selected_category.name)
    term.setTextColor(colors.white)
    
    local y = 6
    for i, ore in ipairs(selected_category.ores) do
        term.setCursorPos(3, y)
        term.write(i .. ". " .. ore.name)
        y = y + 1
    end
    
    term.setCursorPos(1, y + 1)
    term.write("Enter number, 'b' for back, or 'q' to quit:")
end

local function drawScanResults()
    if not selected_ore or not last_scan_results then return end
    
    clearScreen()
    drawHeader()
    
    term.setCursorPos(1, 4)
    term.setTextColor(selected_category.color)
    term.write("Scanning for: " .. selected_ore.name)
    term.setTextColor(colors.white)
    
    if #last_scan_results == 0 then
        term.setCursorPos(1, 6)
        term.write("No " .. selected_ore.name .. " found within " .. SCAN_RADIUS .. " blocks")
        term.setCursorPos(1, 8)
        term.write("Try moving to a different area")
    else
        local closest = last_scan_results[1]
        local dx = closest.x - player_pos.x
        local dz = closest.z - player_pos.z
        local direction = calculateDirection(dx, dz)
        
        -- Draw large arrow
        term.setCursorPos(1, 6)
        term.write("Closest " .. selected_ore.name .. ":")
        
        local w, h = term.getSize()
        local arrow_x = math.floor(w / 2)
        local arrow_y = 9
        
        term.setCursorPos(arrow_x, arrow_y)
        term.setTextColor(colors.lime)
        term.write(direction.arrow)
        term.setTextColor(colors.white)
        
        -- Distance info
        term.setCursorPos(1, arrow_y + 2)
        term.write("Distance: " .. math.floor(closest.distance) .. " blocks")
        
        term.setCursorPos(1, arrow_y + 3)
        term.write("Direction: " .. direction.name)
        
        term.setCursorPos(1, arrow_y + 4)
        term.write("Y-Level: " .. closest.y)
        
        -- Show multiple results if available
        if #last_scan_results > 1 then
            term.setCursorPos(1, arrow_y + 6)
            term.write("Other deposits found:")
            for i = 2, math.min(4, #last_scan_results) do
                local ore = last_scan_results[i]
                term.setCursorPos(3, arrow_y + 5 + i)
                term.write(math.floor(ore.distance) .. " blocks away (Y=" .. ore.y .. ")")
            end
            
            if #last_scan_results > 4 then
                term.setCursorPos(3, arrow_y + 10)
                term.write("+" .. (#last_scan_results - 4) .. " more deposits")
            end
        end
    end
    
    local w, h = term.getSize()
    term.setCursorPos(1, h - 1)
    term.write("'r' to rescan, 'b' for back, 'q' to quit")
end

-- SCANNING LOOP
local function performScan()
    if not selected_ore then return end
    
    term.setCursorPos(1, 3)
    term.write("Scanning...")
    
    local results, error_msg = scanForOres(selected_ore.blocks)
    if results then
        last_scan_results = results
    else
        last_scan_results = {}
        print("Scan error: " .. (error_msg or "Unknown error"))
    end
    
    drawScanResults()
end

-- INPUT HANDLING
local function handleMainMenuInput()
    local event, key = os.pullEvent("char")
    
    if key == "q" then
        return false
    end
    
    local num = tonumber(key)
    if num and num >= 1 and num <= 6 then
        local categories = {}
        for k, v in pairs(ORE_CATEGORIES) do
            table.insert(categories, {key = k, value = v})
        end
        
        if categories[num] then
            selected_category = categories[num].value
            current_menu = "ore_select"
            drawOreMenu()
        end
    end
    
    return true
end

local function handleOreMenuInput()
    local event, key = os.pullEvent("char")
    
    if key == "q" then
        return false
    elseif key == "b" then
        current_menu = "main"
        selected_category = nil
        drawMainMenu()
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
    local event, key = os.pullEvent("char")
    
    if key == "q" then
        return false
    elseif key == "b" then
        current_menu = "ore_select"
        selected_ore = nil
        last_scan_results = {}
        drawOreMenu()
    elseif key == "r" then
        performScan()
    end
    
    return true
end

-- MAIN PROGRAM
local function main()
    print("ATM10 Ore Finder v" .. VERSION)
    print("Initializing geo scanner...")
    
    if not updatePlayerPosition() then
        print("Warning: Could not determine position. GPS or advanced features may be limited.")
    else
        print("Position: " .. player_pos.x .. ", " .. player_pos.y .. ", " .. player_pos.z)
    end
    
    sleep(1)
    
    current_menu = "main"
    drawMainMenu()
    
    local running = true
    while running do
        if current_menu == "main" then
            running = handleMainMenuInput()
        elseif current_menu == "ore_select" then
            running = handleOreMenuInput()
        elseif current_menu == "scanning" then
            running = handleScanInput()
        end
    end
    
    clearScreen()
    print("Thanks for using ATM10 Ore Finder!")
    print("Happy mining!")
end

-- ERROR HANDLING
local function safeMain()
    local success, error = pcall(main)
    if not success then
        clearScreen()
        print("ERROR: " .. tostring(error))
        print("")
        print("Make sure you have:")
        print("1. Advanced Pocket Computer")
        print("2. Geo Scanner addon installed")
        print("3. Sufficient power")
        print("")
        print("If the error persists, please report it.")
    end
end

-- RUN THE PROGRAM
safeMain()