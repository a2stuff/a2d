--[[============================================================

  Utilities for Apple II DeskTop

  ============================================================]]

-- May need tweaking between MAME releases
local TIME_SCALE = 2

local a2d = {}

local util = require("util")
local apple2 = require("apple2")
local mgtk = require("mgtk")

--------------------------------------------------
-- Reset configuration
--------------------------------------------------

function a2d.InitSystem()

  local system = manager.machine.system

  ----------------------------------------
  -- Video
  ----------------------------------------

  if not system.name:match("^apple2gs") then
    -- Monitor type
    if system.name:match("^apple2e")
      or system.name:match("^tk3000")
      or system.name:match("^prav8c") then
      -- Apple IIe or TK3000//e or Pravetz 8C
      apple2.SetMonitorType(apple2.MONITOR_TYPE_VIDEO7)
    elseif system.name:match("^apple2c") then
      -- Apple IIc
      apple2.SetMonitorType(apple2.MONITOR_TYPE_BW)
    elseif system.name:match("^las.*128") then
      -- Laser 128
      apple2.SetMonitorType(apple2.MONITOR_TYPE_BW)
    elseif system.name:match("^ace") then
      -- Franklin ACE 500/2200
      apple2.SetMonitorType(apple2.MONITOR_TYPE_BW)
    end

    -- Rendering preferences
    apple2.SetColorAlgorithm(apple2.ALGORITHM_BWBIAS)
    apple2.SetLoresArtifacts(apple2.LORES_ARTIFACTS_OFF)
    apple2.SetTextColorMode(apple2.TEXTCOLOR_MODE_OFF)
  end

  ----------------------------------------
  -- CPU and other options
  ----------------------------------------

  if system.name:match("^apple2gs") then
    -- bit0 = ZIP, bits 1-7=speed (0-3):
    -- "CPU type": "Standard", "7MHz ZipGS", "8MHz ZipGS", "12MHz ZipGS", "16MHz ZipGS"
    apple2.SetSystemConfig(":a2_config", "CPU type", 0xFF, 1 | (3 << 1))

    -- Address general apple2gs emulation slowness
    TIME_SCALE = TIME_SCALE / 4

  elseif system.name:match("^apple2e")
    or system.name:match("^tk3000")
    or system.name:match("^prav8c") then
    -- bit 4 = "CPU type": 0="Standard", 1="4MHz Zip Chip"
    apple2.SetSystemConfig(":a2_config", "CPU type", 1 << 4, 1 << 4)
    -- bit 5 = "Bootup speed": 0="Standard", 1="4MHz"
    apple2.SetSystemConfig(":a2_config", "Bootup speed", 1 << 5, 1 << 5)

  elseif system.name:match("^apple2c") and not system.name:match("^apple2cp") then
    -- bit 4 = "CPU type": 0="Standard", 1="4MHz Zip Chip"
    apple2.SetSystemConfig(":a2_config", "CPU type", 1 << 4, 1 << 4)
    -- bit 5 = "Bootup speed": 0="Standard", 1="4MHz"
    apple2.SetSystemConfig(":a2_config", "Bootup speed", 1 << 5, 1 << 5)
    -- bit 6 = "40/80 Columns", 0="80 columns", 1="40 columns"
    apple2.SetSystemConfig(":a2_config", "40/80 Columns", 1 << 6, 0 << 6)

  elseif system.name:match("^las.*128") then
    -- bit 3 = "Printer Type", 0="Serial", 1="Parallel"
    apple2.SetSystemConfig(":a2_config", "Printer type", 1 << 3, 0 << 3)

    if not system.name:match("^laser128") then
      -- bit 6 = "40/80 Columns", 0="80 columns", 1="40 columns"
      apple2.SetSystemConfig(":a2_config", "40/80 Columns", 1 << 6, 0 << 6)
    end

    -- ":kbd_lang_select", mask=$FF="Keyboard", 0="QWERTY", 1="DVORAK"
    apple2.SetSystemConfig(":kbd_lang_select", "Keyboard", 0xFF, 0)
  end

  ----------------------------------------
  -- Caps Lock
  ----------------------------------------

  -- Caps lock state is retained between runs
  apple2.CapsLockOff()

end

--------------------------------------------------
-- Lifecycle
--------------------------------------------------

local MINIMAL_REPAINT = 0.5

function a2d.WaitForCopyToRAMCard()
  a2d.WaitForDesktopReady()
end

local repaint_time = 0.25

-- Prefer a2dtest.WaitForSystemTask() when possible, as this
-- is just a heuristic.
function a2d.WaitForRepaint()
  emu.wait(repaint_time * TIME_SCALE) -- heuristic
end

--------------------------------------------------
-- Menus
--------------------------------------------------

function a2d.OpenMenu(mth)
  -- activate menu
  apple2.EscapeKey()
  a2d.WaitForRepaint() -- in menu loop
  local i
  -- over to mth menu
  for i=2,mth do
    apple2.RightArrowKey()
    a2d.WaitForRepaint() -- in menu loop
  end
  a2d.WaitForRepaint() -- in menu loop
end

-- Invoke nth item on mth menu (1-based)
-- (if nth is negative, from the bottom of menu)
function a2d.InvokeMenuItem(mth, nth)
  a2d.OpenMenu(mth)
  if nth > 0 then
    -- down to nth item
    for i=1,nth do
      apple2.DownArrowKey()
      emu.wait(2/60) -- in menu loop
    end
  else
    for i=1,-nth do
      apple2.UpArrowKey()
      emu.wait(2/60) -- in menu loop
    end
  end
  -- invoke
  apple2.ReturnKey()
end

function a2d.OAShortcut(key, options)
  options = util.default_options(options)

  apple2.OAKey(key)
  if not options.no_wait then
    a2d.WaitForRepaint() -- used across modules; may not return to loop
  end
end

function a2d.SAShortcut(key, options)
  options = util.default_options(options)

  apple2.SAKey(key)
  if not options.no_wait then
    a2d.WaitForRepaint() -- used across modules; may not return to loop
  end
end

function a2d.OASAShortcut(key, options)
  options = util.default_options(options)

  apple2.OASAKey(key)
  if not options.no_wait then
    a2d.WaitForRepaint() -- used across modules; may not return to loop
  end
end

--------------------------------------------------
-- Text Fields
--------------------------------------------------

function a2d.ClearTextField()
  apple2.ControlKey("X")
end

--------------------------------------------------
-- Automations
--------------------------------------------------

function a2d.DialogOK(options)
  options = util.default_options(options)

  apple2.ReturnKey()

  if not options.no_wait then
    a2d.WaitForRepaint() -- used outside DeskTop module
  end
end

function a2d.DialogCancel(options)
  options = util.default_options(options)

  apple2.EscapeKey()

  if not options.no_wait then
    a2d.WaitForRepaint() -- used outside DeskTop module
  end
end

-- TODO: Use exported symbol for this!
function a2d.GetFilePickerCurrentPath()
  return apple2.GetPascalString(0x1620)
end

-- NOTE: Used outside of DeskTop module
function a2d.NavigateFilePickerTo(path, opt_file, options)
  apple2.ControlKey("D") -- Drives
  emu.wait(2 * TIME_SCALE)
  for segment in path:gmatch("([^/]+)") do
    apple2.PressOA()
    apple2.Type(segment)
    apple2.ReleaseOA()
    apple2.ControlKey("O") -- Open
    a2d.WaitForRepaint()
  end

  local current_path = a2d.GetFilePickerCurrentPath()
  if current_path:lower() ~= path:lower() then
    error(string.format("Failed to navigate to %q, at %q instead", path, current_path))
  end

  if opt_file then
    apple2.Type(opt_file)
    a2d.WaitForRepaint() -- used outside of DeskTop module
  end
end

--------------------------------------------------
-- Configuration
--------------------------------------------------

-- TODO: Use this in Reboot, etc.
-- TODO: Ensure callers wait until idle, though
function a2d.WaitForDesktopShowing(options)
  options = util.default_options(options)

  function IsDesktopShowing()
    -- RDDHIRES is only on the IIc.
    -- Use RDHIRES (one 'D'), the best we can do on the IIe.
    if apple2.ReadSSW("RDHIRES") < 128 then
      return false
    end

    local dhr = apple2.SnapshotDHR()
    -- skip first column, usually has cursor in it
    for i = 1, apple2.SCREEN_COLUMNS-1 do
      if dhr[i] ~= 0x7F then
        return false
      end
    end

    return true
  end

  util.WaitFor("desktop", IsDesktopShowing, options)
end

-- NOTE: Used outside of DeskTop module (despite the name)
function a2d.WaitForDesktopReady(options)
  options = util.default_options(options)
  emu.wait(1 * TIME_SCALE) -- Don't check too soon and see old module
  a2d.WaitForDesktopShowing(options)
  emu.wait(5 * TIME_SCALE) -- TODO: Something better here
  -- TODO: Some sort of assertion here
end

--------------------------------------------------
-- Mouse Keys
--------------------------------------------------

function a2d.EnterMouseKeysMode()
  a2d.OASAShortcut(" ")
end

function a2d.ExitMouseKeysMode()
  apple2.EscapeKey()
end

function a2d.InMouseKeysMode(func)
  a2d.EnterMouseKeysMode()
  local last_x, last_y
  local exit = func({
      ButtonDown = a2d.MouseKeysButtonDown,
      ButtonUp = a2d.MouseKeysButtonUp,
      Click = a2d.MouseKeysClick,
      DoubleClick = a2d.MouseKeysDoubleClick,
      OAClick = a2d.MouseKeysOAClick,

      Up = a2d.MouseKeysUp,
      Down = a2d.MouseKeysDown,
      Left = a2d.MouseKeysLeft,
      Right = a2d.MouseKeysRight,

      Home = function()
        a2d.MouseKeysHome()
        last_x, last_y = 0, 0
      end,

      MoveToApproximately = function(x, y)
        assert(x)
        assert(y)
        if last_x == nil then
          a2d.MouseKeysMoveToApproximately(x, y)
        else
          a2d.MouseKeysMoveByApproximately(x - last_x, y - last_y)
        end
        last_x, last_y = x, y
      end,

      MoveByApproximately = function(x, y)
        a2d.MouseKeysMoveByApproximately(x, y)
        if last_x ~= nil then
          last_x = last_x + x
          last_y = last_y + y
        end
      end,

      Wait = function()
        emu.wait(10/60)
      end,
  })
  -- Allow returning false to not explicitly exit, e.g. if we exit
  -- DeskTop by double-clicking an executable.
  if exit ~= false then
    -- TODO: Without this, clicks can be treated as drags. Investigate!
    emu.wait(10/60)

    a2d.ExitMouseKeysMode()

    -- TODO: Without this, ClearSelection triggers menu. Why is delay needed?
    emu.wait(10/60)
  end
end

function a2d.MouseKeysDoubleClick(options)
  options = util.default_options(options)

  apple2.SpaceKey()
  emu.wait(10/60)
  apple2.SpaceKey()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

function a2d.MouseKeysClick(options)
  options = util.default_options(options)
  apple2.SpaceKey()

  if not options.no_wait then
    emu.wait(1) -- let double-click timer expire
  end
end

function a2d.MouseKeysOAClick()
  apple2.PressOA()
  emu.wait(1/60)
  a2d.MouseKeysClick()
  emu.wait(1/60)
  apple2.ReleaseOA()
  a2d.WaitForRepaint()
end

function a2d.MouseKeysUp(n)
  for i=1,n do
    apple2.UpArrowKey()
  end
end

function a2d.MouseKeysDown(n)
  for i=1,n do
    apple2.DownArrowKey()
  end
end

function a2d.MouseKeysLeft(n)
  for i=1,n do
    apple2.LeftArrowKey()
  end
end

function a2d.MouseKeysRight(n)
  for i=1,n do
    apple2.RightArrowKey()
  end
end

function a2d.MouseKeysButtonDown()
  apple2.Type(",")
end

function a2d.MouseKeysButtonUp()
  apple2.Type(".")
end

local MOUSE_KEYS_DELTA_X = 8
local MOUSE_KEYS_DELTA_Y = 4
local function round(n)
  return math.floor(n + 0.5)
end

function a2d.MouseKeysHome()
  a2d.MouseKeysLeft(round(apple2.SCREEN_WIDTH / MOUSE_KEYS_DELTA_X))
  a2d.MouseKeysUp(round(apple2.SCREEN_HEIGHT / MOUSE_KEYS_DELTA_Y))
end

function a2d.MouseKeysMoveToApproximately(x,y)
  if x == nil then error("nil passed as x", 2) end
  if y == nil then error("nil passed as y", 2) end

  a2d.MouseKeysHome() -- known location
  a2d.MouseKeysMoveByApproximately(x, y)
end

function a2d.MouseKeysMoveByApproximately(x,y)
  if x == nil then error("nil passed as x", 2) end
  if y == nil then error("nil passed as y", 2) end

  if x > 0 then
    a2d.MouseKeysRight(round(x / MOUSE_KEYS_DELTA_X))
  elseif x < 0 then
    a2d.MouseKeysLeft(round(-x / MOUSE_KEYS_DELTA_X))
  end
  if y > 0 then
    a2d.MouseKeysDown(round(y / MOUSE_KEYS_DELTA_Y))
  elseif y < 0 then
    a2d.MouseKeysUp(round(-y / MOUSE_KEYS_DELTA_Y))
  end
  a2d.WaitForRepaint()
end

function a2d.Drag(src_x, src_y, dst_x, dst_y, options)
  options = util.default_options(options)

  a2d.InMouseKeysMode(function(m)
      m.MoveToApproximately(src_x, src_y)
      m.ButtonDown()
      a2d.WaitForRepaint()
      m.MoveToApproximately(dst_x, dst_y)

      if options.oa_drop then
        apple2.PressOA()
      end
      if options.sa_drop then
        apple2.PressSA()
      end

      emu.wait(1)
      m.ButtonUp()
      emu.wait(1)

      if options.oa_drop then
        apple2.ReleaseOA()
      end
      if options.sa_drop then
        apple2.ReleaseSA()
      end

  end)
end

--------------------------------------------------
-- Modifier Key Combos
--------------------------------------------------

-- Open Selection
-- Page Down
function a2d.OADown(options)
  options = util.default_options(options)
  apple2.PressOA()
  apple2.DownArrowKey()
  apple2.ReleaseOA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Page Down (alias)
function a2d.SADown(options)
  options = util.default_options(options)
  apple2.PressSA()
  apple2.DownArrowKey()
  apple2.ReleaseSA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Open Enclosing Folder
-- Page Up
function a2d.OAUp(options)
  options = util.default_options(options)
  apple2.PressOA()
  apple2.UpArrowKey()
  apple2.ReleaseOA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Page Up (alias)
function a2d.SAUp(options)
  options = util.default_options(options)
  apple2.PressSA()
  apple2.UpArrowKey()
  apple2.ReleaseSA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Move to Start
function a2d.OALeft(options)
  options = util.default_options(options)
  apple2.PressOA()
  apple2.LeftArrowKey()
  apple2.ReleaseOA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Move to End
function a2d.OARight(options)
  options = util.default_options(options)
  apple2.PressOA()
  apple2.RightArrowKey()
  apple2.ReleaseOA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Open Selection then Close Current
-- Scroll to End
function a2d.OASADown(options)
  options = util.default_options(options)
  apple2.PressOA()
  apple2.PressSA()
  apple2.DownArrowKey()
  apple2.ReleaseSA()
  apple2.ReleaseOA()

  if not options.no_wait then
    -- Double wait since it's a more complex action
    a2d.WaitForRepaint()
    a2d.WaitForRepaint()
  end
end

-- Open Enclosing then Close Current
-- Scroll to Start
function a2d.OASAUp(options)
  options = util.default_options(options)
  apple2.PressOA()
  apple2.PressSA()
  apple2.UpArrowKey()
  apple2.ReleaseSA()
  apple2.ReleaseOA()

  if not options.no_wait then
    -- Double wait since it's a more complex action
    a2d.WaitForRepaint()
    a2d.WaitForRepaint()
  end
end

-- Shortcut: File > Delete
function a2d.OADelete(options)
  options = util.default_options(options)
  apple2.PressOA()
  apple2.DeleteKey()
  apple2.ReleaseOA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

--------------------------------------------------
-- Helpers
--------------------------------------------------

local da_loc_table
function a2d.GetLocalizedDAFilename(filename)
  -- Load, parse, and cache the table on first use
  if not da_loc_table then
    local basedir = emu.subst_env("$BASEDIR")
    local lang = emu.subst_env("$lang")
    local f = assert(io.open(basedir .. "/src/desk_acc/res/filenames.res." .. lang, "r"))
    local line = f:read("*line")
    da_loc_table = {}
    while line do
      local key, str = line:match("^%.define res_filename_(%S+) \"(%S+)\"$")
      if key and str then
        da_loc_table[key] = str
      end
      line = f:read("*line")
    end
    assert(f:close())
  end

  -- Look up the localized name
  local key = assert(filename):lower():gsub("%.", "_")
  return da_loc_table[key] or filename
end

function a2d.GetLocalizedPath(path)
  local out = ""
  for segment in path:gmatch("([^/]+)") do
    out = out .. "/" .. a2d.GetLocalizedDAFilename(segment)
  end
  return out
end

--------------------------------------------------

return a2d
