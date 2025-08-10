-- Wrapper around Advanced Peripherals geoscanner
-- Requires a geoScanner peripheral on the turtle
-- target: turtle

local const = require("turtleprize2.const")
local M = {}

-- Find geoscanner peripheral
local scanner = peripheral.find("geoScanner")

-- returns table of valuable ores in scan radius
function M.findValuables(radius)
  if not scanner then return {} end
  local ok, data = pcall(scanner.scan, radius or 8)
  if not ok or not data then return {} end
  local found = {}
  for _,block in ipairs(data) do
    if const.valuableOres[block.name] then
      table.insert(found, block)
    end
  end
  return found
end

return M
