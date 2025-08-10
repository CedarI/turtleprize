-- Pocket computer display for turtleprize2
-- target: pocket
-- Shows current status of turtles

package.path = package.path .. ";/?.lua;/?/init.lua"

local const = require("turtleprize2.const")
local util = require("turtleprize2.util")
local net = require("turtleprize2.net")

net.open()
local turtles = {}

local function redraw()
  term.clear()
  term.setCursorPos(1,1)
  print("TurtlePrize2 Pocket")
  local row = 3
  for id,st in pairs(turtles) do
    print(string.format("%d: fuel %d items %d", id, st.fuel or 0, st.total or 0))
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
      turtles[id] = msg.data
      redraw()
    end
  elseif e[1] == "touch" then
    local x,y = e[2], e[3]
    for id,st in pairs(turtles) do
      if st._row == y then
        net.send(id, const.msg.recall, true)
      end
    end
  end
  util.yield()
end
