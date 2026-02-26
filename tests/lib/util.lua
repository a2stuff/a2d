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

function util.SlurpFile(pathname)
  local f = assert(io.open(pathname, "rb"))
  local bytes = f:read("*all")
  assert(f:close())
  return bytes
end

function util.CaseInsensitivePattern(p)
  return (assert(p):gsub("(%%?)(.)", function(escape, char)
    if escape == "" and char:match("%a") then
      return "[" .. char:lower() .. char:upper() .. "]"
    else
      return escape .. char
    end
  end))
end

return util
