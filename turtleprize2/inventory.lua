-- Inventory management for turtleprize2 turtles
-- target: turtle

local const = require("turtleprize2.const")
local net = require("turtleprize2.net")
local util = require("turtleprize2.util")

local M = {}

-- Summarize current inventory counts for valuable ores
function M.summary()
  local sums = {}
  local total = 0
  for i=1,16 do
    local item = turtle.getItemDetail(i)
    if item then
      total = total + item.count
      if const.valuableOres[item.name] then
        sums[item.name] = (sums[item.name] or 0) + item.count
      end
    end
  end
  return {total = total, ores = sums, fuel = turtle.getFuelLevel()}
end

-- Broadcast status over network to controller
function M.report(pos)
  local status = M.summary()
  status.pos = pos
  net.broadcast(const.msg.status, status)
end

-- Drop non-valuable items
function M.dropJunk()
  for i=1,16 do
    local item = turtle.getItemDetail(i)
    if item and not const.valuableOres[item.name] then
      turtle.select(i)
      turtle.drop()
      util.yield()
    end
  end
end

-- deposit items into ender chest if present in front
function M.depositToEnder()
  local ok, data = turtle.inspect()
  if ok and data.name == "minecraft:ender_chest" then
    for i=1,16 do
      turtle.select(i)
      turtle.drop()
      util.yield()
    end
    turtle.select(1)
    return true
  end
  return false
end

return M
