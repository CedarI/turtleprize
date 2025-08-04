-- CONFIGURATION
local STATUS_PROTOCOL = "turtle_status"
local COMMAND_PROTOCOL = "turtle_command" -- Protocol for sending commands
local REFRESH_RATE = 1 -- How often to redraw the screen (in seconds)

-- INITIALIZATION
local modem = peripheral.find("modem", function(_, p) return p.isWireless() end)
if not modem then printError("Wireless modem not found!"); return end

rednet.open(peripheral.getName(modem))
print("Listening for turtle status on protocol '"..STATUS_PROTOCOL.."'...")
print("My ID is: ".. os.getComputerID())

local turtle_states = {}
local bottom_message = ""
local is_recalling = false
local recall_id_str = ""
local message_timer = nil

-- Function to draw the main screen
local function draw()
  term.clear()
  term.setCursorPos(1, 1)
  term.write("--- Turtle Fleet Monitoring System ---")
  term.setCursorPos(1, 2)
  term.write("Press 'r' to recall a turtle. Press 'q' to quit.")

  if not next(turtle_states) then
    term.setCursorPos(1, 4)
    term.write("Awaiting first status update...")
  else
    local line = 4
    for id, data in pairs(turtle_states) do
      if line > term.getSize() - 8 then
        term.setCursorPos(1, line); term.write("...more turtles not shown..."); break
      end
      
      term.setCursorPos(1, line); term.write("Turtle ID: ".. tostring(id))
      term.setCursorPos(2, line + 1); term.write("Status: ".. tostring(data.statusMessage or "N/A"))
      term.setCursorPos(2, line + 2); term.write(string.format("Pos: (%d, %d, %d)", data.x or 0, data.y or 0, data.z or 0))
      
      if data.progress and data.width and data.length then
        local p = data.progress
        term.setCursorPos(2, line + 3); term.write(string.format("Progress: Scan (%d, %d) of (%d, %d)", p.x or 0, p.z or 0, data.width, data.length))
      end
      
      term.setCursorPos(2, line + 4); term.write("Fuel: ".. tostring(data.fuelLevel or "N/A"))
      
      local current_line = line + 5
      term.setCursorPos(2, current_line); term.write("Inventory:")
      current_line = current_line + 1
      
      if data.inventory and next(data.inventory) then
        for name, count in pairs(data.inventory) do
          if current_line > term.getSize() - 2 then break end
          term.setCursorPos(4, current_line); term.write(string.format("- %s: %d", name, count))
          current_line = current_line + 1
        end
      else
        term.setCursorPos(4, current_line); term.write("- Empty"); current_line = current_line + 1
      end
      line = current_line + 1
    end
  end

  local w, h = term.getSize()
  term.setCursorPos(1, h); term.write(string.rep(" ", w)); term.setCursorPos(1, h)
  if is_recalling then
    term.write("Enter Turtle ID to recall: " .. recall_id_str)
  else
    term.write(bottom_message)
  end
end

-- MAIN LOOP (FIXED to properly handle events and timeouts)
local running = true
draw() -- Initial draw

while running do
  -- Use os.startTimer for periodic redraws and os.pullEventRaw for proper event handling
  local refresh_timer = os.startTimer(REFRESH_RATE)
  
  local event, p1, p2, p3 = os.pullEventRaw()
  
  if event == "rednet_message" then
    -- p1 = sender_id, p2 = message, p3 = protocol
    local sender_id, message, protocol = p1, p2, p3
    if protocol == STATUS_PROTOCOL then
      local success, data = pcall(textutils.unserializeJSON, message)
      if success and type(data) == "table" then
        turtle_states[sender_id] = data
        print("Received status from turtle " .. sender_id) -- Debug output
      else
        print("Failed to parse JSON from turtle " .. sender_id) -- Debug output
      end
    end
    draw() -- Redraw immediately when we get new data
  elseif event == "key" then
    local key = p1
    if is_recalling then
      if key == keys.enter then
        local id = tonumber(recall_id_str)
        if id then
          rednet.send(id, "recall", COMMAND_PROTOCOL)
          bottom_message = "Recall command sent to turtle " .. id
        else
          bottom_message = "Invalid ID. Operation cancelled."
        end
        is_recalling = false
        recall_id_str = ""
        message_timer = os.startTimer(2) -- Set a timer to clear the message
      elseif key == keys.backspace and #recall_id_str > 0 then
        recall_id_str = recall_id_str:sub(1, -2)
      elseif key == keys.escape then
        is_recalling = false
        recall_id_str = ""
      end
    else
      if key == keys.r then
        is_recalling = true
        bottom_message = ""
      elseif key == keys.q then
        running = false
      end
    end
    draw()
  elseif event == "char" then
    if is_recalling then
      recall_id_str = recall_id_str .. p1
      draw()
    end
  elseif event == "timer" then
    if p1 == message_timer then
      bottom_message = ""
      message_timer = nil
      draw()
    elseif p1 == refresh_timer then
      draw() -- Periodic refresh
    end
  elseif event == "terminate" then
    running = false
  end
end

rednet.close()
term.clear()
term.setCursorPos(1,1)
print("Monitor program terminated.")