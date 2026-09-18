--[[============================================================

  Generic Utilities

  ============================================================]]

local util = {}

function util.WaitFor(message, func, options, level)
  local timeout = 60
  local scale = 20
  local wait = 1 / scale
  if options and options.timeout then
    timeout = options.timeout
  end
  if options and options.wait then
    wait = options.wait
  end
  if level == nil then
    level = 1
  end
  for i = 1, timeout*scale do
    if func() then
      return
    end
    emu.wait(wait)
  end
  error(string.format("Timeout (%ds) waiting for %s", timeout, message), level + 2)
end

function util.WaitForNoError(func, options)
  local timeout = 60
  if options and options.timeout then
    timeout = options.timeout
  end
  if level == nil then
    level = 1
  end
  for i = 1, timeout do
    if func() then
      return true
    end
    emu.wait(1)
  end
  return false
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

function util.GetSymbols(envar)
  local symbols = {}
  for pair in emu.subst_env("$" .. envar):gmatch("([^ ]+)") do
    local k,v = pair:match("^(.+)=(.+)$")
    symbols[k] = tonumber(v, 16)
  end
  return symbols
end

return util
