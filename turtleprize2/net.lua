-- Networking helpers using rednet for turtleprize2
-- Any device with a modem can use this module

local const = require("turtleprize2.const")

local M = {}

-- Ensure a modem is open for rednet
function M.open()
  if rednet.isOpen() then return true end
  for _,side in ipairs(rs.getSides()) do
    if peripheral.getType(side) == "modem" then
      rednet.open(side)
      return true
    end
  end
  return false
end

-- Send a message to id using protocol
function M.send(id, typ, data)
  if not M.open() then return false end
  local msg = {type = typ, data = data}
  return rednet.send(id, msg, const.protocol)
end

-- Broadcast message to all computers
function M.broadcast(typ, data)
  if not M.open() then return false end
  local msg = {type = typ, data = data}
  rednet.broadcast(msg, const.protocol)
end

-- Receive message, returns sender and table
function M.receive(timeout)
  if not M.open() then return nil end
  local id, msg = rednet.receive(const.protocol, timeout)
  return id, msg
end

return M
