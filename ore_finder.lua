---------------------------------------------------------------------
-- ATM10 ORE FINDER - Advanced Pocket Computer Geo Scanner App
-- Requires: Advanced Pocket Computer + Geo Scanner from Advanced Peripherals
---------------------------------------------------------------------

-- CONFIGURATION
local SCAN_RADIUS = 16 -- Scan radius for geo scanner
local REFRESH_RATE = 5 -- Seconds between automatic scans
local VERSION = "1.5-clean"

---------------------------------------------------------------------
-- INITIALIZE GEO SCANNER FIRST (before any other code)
---------------------------------------------------------------------
print("ATM10 Ore Finder v" .. VERSION)
print("Looking for geo scanner...")

local geoscanner = peripheral.wrap("back")

if geoscanner and geoscanner.scan then
    print("Geo scanner found on back and functional!")
elseif geoscanner then
    print("Peripheral found on back but no scan function available")
    if peripheral.getMethods then
        print("Available methods:", table.concat(peripheral.getMethods("back"), ", "))
    end
    geoscanner = nil
else
    print("No peripheral found on back, trying other sides...")

    -- Try other sides
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

-- ATM10 VALUABLE ORES DATABASE (Updated with AllTheOres and mod variants)
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
            {name = "Gold", blocks = {
                "minecraft:gold_ore", "minecraft:deepslate_gold_ore", "minecraft:nether_gold_ore",
                "alltheores:gold_ore", "alltheores:deepslate_gold_ore", "alltheores:nether_gold_ore"
            }},
        }
    },
    ["Tech Ores"] = {
        name = "Technology Ores",
        color = colors.cyan,
        ores = {
            {name = "Certus Quartz", blocks = {"ae2:certus_quartz_ore", "ae2:deepslate_certus_quartz_ore"}},
            {name = "Osmium", blocks = {
                "mekanism:osmium_ore", "mekanism:deepslate_osmium_ore",
                "alltheores:osmium_ore", "alltheores:deepslate_osmium_ore"
            }},
            {name = "Uranium", blocks = {
                "mekanism:uranium_ore", "mekanism:deepslate_uranium_ore",
                "alltheores:uranium_ore", "alltheores:deepslate_uranium_ore"
            }},
            {name = "Fluorite", blocks = {
                "mekanism:fluorite_ore", "mekanism:deepslate_fluorite_ore",
                "alltheores:fluorite_ore", "alltheores:deepslate_fluorite_ore"
            }},
            {name = "Zinc", blocks = {
                "create:zinc_ore", "create:deepslate_zinc_ore",
                "alltheores:zinc_ore", "alltheores:deepslate_zinc_ore"
            }},
        }
    },
    ["Industrial"] = {
        name = "Industrial Ores",
        color = colors.orange,
        ores = {
            {name = "Tin", blocks = {
                "thermal:tin_ore", "thermal:deepslate_tin_ore",
                "mekanism:tin_ore", "mekanism:deepslate_tin_ore",
                "alltheores:tin_ore", "alltheores:deepslate_tin_ore"
            }},
            {name = "Lead", blocks = {
                "thermal:lead_ore", "thermal:deepslate_lead_ore",
                "mekanism:lead_ore", "mekanism:deepslate_lead_ore",
                "alltheores:lead_ore", "alltheores:deepslate_lead_ore"
            }},
            {name = "Silver", blocks = {
                "thermal:silver_ore", "thermal:deepslate_silver_ore",
                "alltheores:silver_ore", "alltheores:deepslate_silver_ore"
            }},
            {name = "Nickel", blocks = {
                "thermal:nickel_ore", "thermal:deepslate_nickel_ore",
                "alltheores:nickel_ore", "alltheores:deepslate_nickel_ore"
            }},
            {name = "Aluminum", blocks = {
                "alltheores:aluminum_ore", "alltheores:deepslate_aluminum_ore"
            }},
        }
    },
    ["Common"] = {
        name = "Common Ores",
        color = colors.lightGray,
        ores = {
            {name = "Iron", blocks = {
                "minecraft:iron_ore", "minecraft:deepslate_iron_ore",
                "alltheores:iron_ore", "alltheores:deepslate_iron_ore"
            }},
            {name = "Copper", blocks = {
                "minecraft:copper_ore", "minecraft:deepslate_copper_ore",
                "alltheores:copper_ore", "alltheores:deepslate_copper_ore",
                "thermal:copper_ore", "thermal:deepslate_copper_ore"
            }},
            {name = "Coal", blocks = {
                "minecraft:coal_ore", "minecraft:deepslate_coal_ore",
                "alltheores:coal_ore", "alltheores:deepslate_coal_ore"
            }},
            {name = "Redstone", blocks = {
                "minecraft:redstone_ore", "minecraft:deepslate_redstone_ore",
                "alltheores:redstone_ore", "alltheores:deepslate_redstone_ore"
            }},
            {name = "Lapis", blocks = {
                "minecraft:lapis_ore", "minecraft:deepslate_lapis_ore",
                "alltheores:lapis_ore", "alltheores:deepslate_lapis_ore"
            }},
        }
    },
    ["Nether"] = {
        name = "Nether Ores",
        color = colors.red,
        ores = {
            {name = "Ancient Debris", blocks = {"minecraft:ancient_debris"}},
            {name = "Nether Quartz", blocks = {
                "minecraft:nether_quartz_ore",
                "alltheores:nether_quartz_ore"
            }},
            {name = "Nether Gold", blocks = {
                "minecraft:nether_gold_ore",
                "alltheores:nether_gold_ore"
            }},
            {name = "Gilded Blackstone", blocks = {"minecraft:gilded_blackstone"}},
            {name = "Nether Copper", blocks = {
                "alltheores:nether_copper_ore", "thermal:nether_copper_ore"
            }},
            {name = "Nether Iron", blocks = {
                "alltheores:nether_iron_ore", "thermal:nether_iron_ore"
            }},
        }
    }
}

---------------------------------------------------------------------
-- GLOBAL STATE
---------------------------------------------------------------------
local current_menu = "main"
local selected_category = nil
local selected_ore = nil
local last_scan_results = {}
local scan_timer = nil
local player_pos = {x = 0, y = 0, z = 0}

---------------------------------------------------------------------
-- UTILITY FUNCTIONS
---------------------------------------------------------------------

-- Safe wrapper functions for geo scanner API
local function safeFuelLevel()
    if geoscanner.getFuelLevel then
        return geoscanner.getFuelLevel()
    end
    return 999999 -- Assume infinite fuel if function doesn't exist
end

local function safeMaxFuelLevel()
    if geoscanner.getMaxFuelLevel then
        return geoscanner.getMaxFuelLevel()
    end
    return 999999 -- Assume infinite fuel if function doesn't exist
end

local function safeCost(radius)
    if geoscanner.cost then
        return geoscanner.cost(radius)
    end
    return 0 -- Assume no cost if function doesn't exist
end

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
    -- Try GPS if available (completely optional)
    local has_gps = false
    if gps and gps.locate then
        local x, y, z = gps.locate(1) -- 1 second timeout
        if x and y and z then
            -- GPS gives eye level, adjust to feet level
            player_pos = {x = x, y = y - 1, z = z}
            has_gps = true
        end
    end

    -- If no GPS, use relative positioning from (0,0,0) at feet level
    if not has_gps then
        player_pos = {x = 0, y = -1, z = 0} -- Feet level relative positioning
    end

    return true -- Always return true since relative positioning always works
end

-- DIRECTION CALCULATION
local function calculateDistance(x1, y1, z1, x2, y2, z2)
    -- Safety check for nil values
    if not x1 or not y1 or not z1 or not x2 or not y2 or not z2 then
        return 0
    end

    return math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

local function calculateDirection(dx, dz)
    -- Ensure we have valid numbers
    if not dx or not dz then
        return {arrow = "?", name = "Unknown"}
    end

    -- Handle zero case
    if dx == 0 and dz == 0 then return {arrow = "●", name = "Here"} end

    -- Simple 4-direction system for clarity
    if math.abs(dx) > math.abs(dz) then
        if dx > 0 then
            return {arrow = "→", name = "East"}
        else
            return {arrow = "←", name = "West"}
        end
    else
        if dz > 0 then
            return {arrow = "↓", name = "South"}
        else
            return {arrow = "↑", name = "North"}
        end
    end
end

---------------------------------------------------------------------
-- UI DRAWING FUNCTIONS
---------------------------------------------------------------------

local function drawMainMenu()
    clearScreen()
    drawHeader()

    -- Show geo scanner status (simplified)
    local fuel = safeFuelLevel()
    local max_fuel = safeMaxFuelLevel()

    term.setCursorPos(1, 4)
    if fuel < 1000 and fuel < 999999 then
        term.setTextColor(colors.orange)
        term.write("Scanner Status: Low fuel (" .. fuel .. "/" .. max_fuel .. ")")
    else
        term.setTextColor(colors.green)
        if fuel < 999999 then
            term.write("Scanner Status: Ready (" .. fuel .. "/" .. max_fuel .. " fuel)")
        else
            term.write("Scanner Status: Ready")
        end
    end
    term.setTextColor(colors.white)

    term.setCursorPos(1, 6)
    term.write("Select ore category:")

    local y = 8
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
    term.setCursorPos(1, y + 3)
    term.write("Scan radius: " .. SCAN_RADIUS .. " blocks")
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

    -- Show fuel status (simplified)
    local fuel = safeFuelLevel()
    local max_fuel = safeMaxFuelLevel()
    local cost = safeCost(SCAN_RADIUS)

    term.setCursorPos(1, 4)
    term.setTextColor(selected_category.color)
    term.write("Scanning: " .. selected_ore.name .. " (radius: " .. SCAN_RADIUS .. ")")
    term.setTextColor(colors.white)

    term.setCursorPos(1, 5)
    if fuel < cost and fuel < 999999 then
        term.setTextColor(colors.orange)
        term.write("Low fuel: " .. fuel .. "/" .. max_fuel .. " (need " .. cost .. ")")
        term.setTextColor(colors.white)
    else
        if fuel < 999999 then
            term.setTextColor(colors.green)
            term.write("Fuel: " .. fuel .. "/" .. max_fuel)
        else
            term.setTextColor(colors.green)
            term.write("Scanner ready")
        end
        term.setTextColor(colors.white)
    end

    if #last_scan_results == 0 then
        term.setCursorPos(1, 7)
        term.write("No " .. selected_ore.name .. " found within " .. SCAN_RADIUS .. " blocks")
        term.setCursorPos(1, 9)
        term.write("Try moving to a different area")
        if fuel < cost and fuel < 999999 then
            term.setCursorPos(1, 10)
            term.write("or charge the geo scanner")
        end
    else
        local closest = last_scan_results[1]

        -- Calculate direction
        local dx = 0
        local dz = 0

        if closest.x and player_pos.x then
            dx = closest.x - player_pos.x
        end
        if closest.z and player_pos.z then
            dz = closest.z - player_pos.z
        end

        local direction = calculateDirection(dx, dz)

        -- Show ore info
        term.setCursorPos(1, 7)
        term.write("Found " .. #last_scan_results .. " deposit(s)")

        term.setCursorPos(1, 9)
        term.write("CLOSEST:")

        -- Show direction with clear arrow
        term.setCursorPos(1, 11)
        term.write("Direction: " .. direction.name)

        term.setCursorPos(1, 12)
        term.setTextColor(colors.lime)
        term.write("Arrow: " .. direction.arrow .. " " .. direction.arrow .. " " .. direction.arrow)
        term.setTextColor(colors.white)

        term.setCursorPos(1, 14)
        term.write("Distance: " .. math.floor(closest.distance or 0) .. " blocks")

        term.setCursorPos(1, 15)
        term.write("Y-Level: " .. tostring(closest.y or "unknown"))

        term.setCursorPos(1, 16)
        term.write("Block: " .. tostring(closest.block_name or "unknown"))

        -- Show other results if available
        if #last_scan_results > 1 then
            term.setCursorPos(1, 18)
            term.write("Other deposits:")
            for i = 2, math.min(3, #last_scan_results) do
                local ore = last_scan_results[i]
                term.setCursorPos(3, 17 + i)
                term.write(math.floor(ore.distance or 0) .. " blocks (Y=" .. tostring(ore.y or "?") .. ")")
            end
        end
    end

    local w, h = term.getSize()
    term.setCursorPos(1, h - 1)
    term.write("'r' to rescan, 'b' for back, 'q' to quit")
end

---------------------------------------------------------------------
-- SCANNING FUNCTIONS
---------------------------------------------------------------------

local function scanForOres(ore_blocks)
    -- Always update position
    updatePlayerPosition()

    -- Check fuel level (if function exists)
    local fuel = safeFuelLevel()
    local cost = safeCost(SCAN_RADIUS)

    if fuel < cost and fuel < 999999 then -- Don't check fuel if we're using fallback values
        return {}
    end

    -- Use the geo scanner scan function
    local all_blocks, error_msg = geoscanner.scan(SCAN_RADIUS)

    if not all_blocks then
        return {}
    end

    local results = {}

    -- Create a lookup table for faster ore checking
    local ore_lookup = {}
    for _, block_name in ipairs(ore_blocks) do
        ore_lookup[block_name] = true
    end

    -- Filter for the ores we want
    for i, block_data in ipairs(all_blocks) do
        if block_data and block_data.name and ore_lookup[block_data.name] then
            -- Check if coordinates are valid
            if block_data.x and block_data.y and block_data.z then
                local distance = calculateDistance(
                        player_pos.x, player_pos.y, player_pos.z,
                        block_data.x, block_data.y, block_data.z
                )

                table.insert(results, {
                    x = block_data.x,
                    y = block_data.y,
                    z = block_data.z,
                    distance = distance,
                    block_name = block_data.name,
                    tags = block_data.tags
                })
            end
        end
    end

    -- Sort by distance
    table.sort(results, function(a, b) return a.distance < b.distance end)

    return results
end

-- SCANNING LOOP
local function performScan()
    if not selected_ore then return end

    term.setCursorPos(1, 3)
    term.write("Scanning...")

    local results = scanForOres(selected_ore.blocks)
    last_scan_results = results or {}

    drawScanResults()
end

---------------------------------------------------------------------
-- INPUT HANDLING
---------------------------------------------------------------------

local function handleMainMenuInput()
    local event, key = os.pullEvent("char")

    if key == "q" then
        return false
    end

    local num = tonumber(key)
    if num and num >= 1 and num <= #ORE_CATEGORIES then
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

---------------------------------------------------------------------
-- MAIN PROGRAM
---------------------------------------------------------------------

local function main()
    -- Check if geo scanner was initialized successfully
    if not geoscanner then
        print("Cannot start - geo scanner initialization failed!")
        return
    end

    -- Check scanner status
    local fuel = safeFuelLevel()
    local max_fuel = safeMaxFuelLevel()
    local cost = safeCost(SCAN_RADIUS)

    if fuel < 999999 then
        if fuel < cost then
            print("WARNING: Not enough fuel for scanning!")
            print("Please charge your geo scanner before use.")
        end
    end

    -- Check GPS availability
    updatePlayerPosition()
    if gps and gps.locate then
        local x, y, z = gps.locate(1)
        if x and y and z then
            print("GPS available - using absolute coordinates")
        else
            print("GPS not available - using relative positioning")
        end
    else
        print("No GPS system - using relative positioning")
    end

    print("Ready to scan!")
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