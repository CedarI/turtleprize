-- Central controller for turtleprize2
-- target: computer (supports external monitors)
-- Displays inventory stats for each turtle and allows recall via touch

package.path = package.path .. ";/?.lua;/?/init.lua"

local const = require("turtleprize2.const")
local util = require("turtleprize2.util")
local net = require("turtleprize2.net")

net.open()

local monitor = peripheral.find("monitor")
if monitor then
  monitor.setTextScale(0.5)
  term.redirect(monitor)
end

local turtles = {} -- id -> status

local function redraw()
  term.clear()
  term.setCursorPos(1,1)
  print("TurtlePrize2 Controller")
  print("Click a turtle to recall")
  local row = 3
  for id,st in pairs(turtles) do
    local line = string.format("%d: fuel %d items %d", id, st.fuel or 0, st.total or 0)
    print(line)
    st._row = row
    row = row + 1
  end
end

redraw()

while true do
  local e = {os.pullEvent()}
  if e[1] == "rednet_message" then
    local id,msg = e[2], e[3]
    if msg.type == const.msg.status then
      local st = turtles[id] or {}
      st.total = msg.data.total or 0
      st.fuel = msg.data.fuel or 0
      st.pos = msg.data.pos
      turtles[id] = st
      redraw()
    end
  elseif e[1] == "monitor_touch" then
    local x,y = e[3], e[4]
    for id,st in pairs(turtles) do
      if st._row == y then
        net.send(id, const.msg.recall, true)
      end
    end
  end
  util.yield()
end
