-- Utility helpers for turtleprize2
-- Works on computer, turtle and pocket

local M = {}

-- simple wrapper around sleep to avoid blocking
function M.yield()
  sleep(0)
end

-- Wait for an event, optionally filtering
function M.pull(event)
  return os.pullEvent(event)
end

return M
