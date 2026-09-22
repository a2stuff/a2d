--[[============================================================

  Generic Utilities

  ============================================================]]

local util = {}

function util.WaitFor(message, func, options)
  options = util.default_options(options)
  local timeout = 60
  local scale = 20
  local wait = 1 / scale
  if options.timeout then
    timeout = options.timeout
  end
  if options.wait then
    wait = options.wait
  end
  for i = 1, timeout*scale do
    if func() then
      return
    end
    emu.wait(wait)
  end
  error(string.format("Timeout (%ds) waiting for %s", timeout, message), options.level)
end

function util.WaitForNoError(func, options)
  options = util.default_options(options)

  local timeout = 60
  if options.timeout then
    timeout = options.timeout
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


--[[
  Usage:

    function MyExpectFunc(..., options)
      options = util.default_options(options)

      -- `options` is definitely a table
      if options.foo then ... end

      -- returns a copy, so this doesn't mutate the caller's copy
      options.extra = true

      -- options.level automagically set/incremented; will show the
      -- *caller* of this function as error source.
      if bad then error("bad", options.level) end

      -- if passed on to other such functions, so the correct caller
      -- will be shown.
      OtherExpectFunc(..., options)
  end
]]
function util.default_options(o)
  local options = {}
  if o then
    for k, v in pairs(o) do
      options[k] = v
    end
  end

  if options.level == nil then
    options.level = 1
  end

  options.level = options.level + 1
  return options
end


return util
