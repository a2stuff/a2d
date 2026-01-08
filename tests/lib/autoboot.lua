--[[
  This file is loaded every time the machine is hard reset.

  The require() happens only once, so this loads/executes a single copy of
  executor.lua which maintains state across hard resets.

  The executor.Go() call is executed on startup and after every
  hard reset.
]]

local prefix = emu.subst_env("$LUA_PATH") .. ";"
if package.path:sub(1, #prefix) ~= prefix then
  package.path = prefix .. package.path
end

require("executor")

executor.Go()
