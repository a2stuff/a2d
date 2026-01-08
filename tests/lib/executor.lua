executor = {}

-- Set to "starting" then to "running" to inform executor.Go()
local state = "starting"

function executor.Init()
  emu.wait(1/60) -- allow logging to get ready

  -- Dependencies (in coroutine so logging is ready)
  util = require("util")
  test = require("test")
  apple2 = require("apple2")
  a2d = require("a2d")
  a2dtest = require("a2dtest")
  mgtk = require("mgtk")

  -- TODO: Once or every time?
  a2d.InitSystem() -- async; outside require

  -- TODO: These need to happen within each restart


  -- Globals
  machine = manager.machine

  -- Execute passed script
  local chunk_function, err = loadfile(emu.subst_env("$LUA_SCRIPT"), "t", _ENV)
  if err then
    io.stderr:write(err .. "\n")
    os.exit(1)
  end
  -- TODO: xpcall? do anything with result?
  local result = chunk_function()

  if not test.HasMoreSteps() then
    io.stderr:write("no tests run!\n")
    os.exit(1)
  end

  -- Kick things off
  executor.RunNextStep()
end

function executor.RunNextStep()
  state = "running"

  if not test.HasMoreSteps() then
    os.exit(0)
  end

  -- Sometimes hangs here. Untangle coroutines?
  -- ACE 2200 is hard-coded to autostart at Slot 6
  if manager.machine.system.name:match("^ace2200") then
    apple2.ControlReset()
    apple2.TypeLine("PR#7")
  end

  -- Wait for DeskTop to start
  if emu.subst_env("$WAITFORDESKTOP") == "true" then
    -- TODO: Why does this timeout sometimes? with --visible looks okay
    -- Probably auxmem - reading old memory
    a2d.WaitForDesktopReady()
  end

  -- Test step
  test.RunNextStep()

  -- Done?
  if not test.HasMoreSteps() then
    os.exit(0)
  end

  -- Reset to trigger the next step
  manager.machine:hard_reset()
end

function executor.Go()
  local c = coroutine.create(function()
      if state == "starting" then
        executor.Init()
      else
        executor.RunNextStep()
      end
  end)
  coroutine.resume(c)
end

return executor
