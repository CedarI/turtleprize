-- Mining turtle program for turtleprize2
-- target: turtle (Advanced Peripherals: geoScanner, Chunky Turtle)
-- Requires modem, pickaxe and optional chunk loader/ender chest

package.path = package.path .. ";/?.lua;/?/init.lua"

local const = require("turtleprize2.const")
local util = require("turtleprize2.util")
local net = require("turtleprize2.net")
local geo = require("turtleprize2.geoscanner")
local inv = require("turtleprize2.inventory")

net.open() -- open modem

-- determine starting position via GPS
local function getPos()
  local x,y,z = gps.locate(5)
  if x then return {x=x,y=y,z=z} end
  return nil
end

local home = getPos()

-- simple refuel routine using any fuel in inventory
local function refuel()
  if turtle.getFuelLevel() > 200 then return true end
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      if turtle.refuel(0) then
        turtle.refuel(turtle.getItemCount(i))
        turtle.select(1)
        return true
      end
    end
  end
  turtle.select(1)
  return false
end

-- move one block forward digging if needed
local function forward()
  while not turtle.forward() do
    turtle.dig()
    util.yield()
  end
end

-- dig any valuable ore adjacent to turtle
local function mineAdjacent()
  local ores = geo.findValuables(8)
  for _,o in ipairs(ores) do
    if o.x==0 and o.y==0 and o.z==1 then
      turtle.dig(); return true
    elseif o.x==0 and o.y==1 and o.z==0 then
      turtle.digUp(); return true
    elseif o.x==0 and o.y==-1 and o.z==0 then
      turtle.digDown(); return true
    elseif o.x==1 and o.y==0 and o.z==0 then
      turtle.turnRight(); turtle.dig(); turtle.turnLeft(); return true
    elseif o.x==-1 and o.y==0 and o.z==0 then
      turtle.turnLeft(); turtle.dig(); turtle.turnRight(); return true
    end
  end
  return false
end

-- main mining loop
while true do
  if not refuel() then
    net.broadcast(const.msg.status, {error = "out_of_fuel"})
    break
  end

  inv.report(getPos())

  -- check for recall commands
  local id,msg = net.receive(0.1)
  if msg and msg.type == const.msg.recall then
    break
  end

  if not mineAdjacent() then
    turtle.dig()
    forward()
  end

  inv.dropJunk()
  if inv.summary().total > 14*64 then
    inv.depositToEnder()
  end
  util.yield()
end

-- ascend to surface if GPS home is known
if home then
  while true do
    local pos = getPos()
    if not pos or pos.y >= home.y then break end
    while not turtle.up() do turtle.digUp(); util.yield() end
  end
end

inv.report(getPos())
print("Miner stopped")
