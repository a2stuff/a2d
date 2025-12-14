package.path = emu.subst_env("$LUA_PATH") .. ";" .. package.path

-- Run in an async context
local c = coroutine.create(function()
    emu.wait(1/60) -- allow logging to get ready

    -- Dependencies
    test = require("test")
    apple2 = require("apple2")
    a2d = require("a2d")
    a2dtest = require("a2dtest")
    mgtk = require("mgtk")
    a2d.InitSystem() -- async; outside require

    -- ACE 2200 is hard-coded to autostart at Slot 6
    if manager.machine.system.name:match("^ace2200") then
      apple2.ControlReset()
      apple2.TypeLine("PR#7")
    end

    -- Wait for DeskTop to start
    a2d.WaitForDesktopReady()

    -- Globals
    machine = manager.machine

    -- Execute passed script
    local chunk_function, err = loadfile(emu.subst_env("$LUA_SCRIPT"), "t", _ENV)
    if err then
      print(err)
      os.exit(1)
    end

    local result = chunk_function()
    if result then
      return
    end

    if test.count == 0 then
      print("no tests run!")
      os.exit(1)
    end

    -- Success by default
    os.exit(0)
end)
coroutine.resume(c)
