--[[============================================================

  Generic Utilities

  ============================================================]]

local util = {}

function util.WaitFor(message, func, options, level)
  local timeout = 60
  if options and options.timeout then
    timeout = options.timeout
  end
  if level == nil then
    level = 1
  end
  for i = 1, timeout do
    if func() then
      return
    end
    emu.wait(1)
  end
  error(string.format("Timeout (%ds) waiting for %s", timeout, message), level + 2)
end

return util
