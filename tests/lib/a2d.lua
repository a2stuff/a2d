--[[============================================================

  Utilities for Apple II DeskTop

  ============================================================]]--

local a2d = {}

local apple2 = require("apple2")

--------------------------------------------------
-- Reset configuration
--------------------------------------------------

function a2d.InitSystem()

  local system = manager.machine.system

  -- Video
  if not system.name:match("^apple2gs") then
    -- Monitor type
    if system.name:match("^apple2e") then
      -- Apple IIe
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

  -- CPU and other options

  if system.name:match("^apple2gs") then
    -- bit0 = ZIP, bits 1-7=speed (0-3):
    -- "CPU type": "Standard", "7MHz ZipGS", "8MHz ZipGS", "12MHz ZipGS", "16MHz ZipGS"
    apple2.SetSystemConfig(":a2_config", "CPU type", 0xFF, 1 | (3 << 1))

  elseif system.name:match("^apple2e") then
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
    -- bit 6 = "40/80 Columns", 0="80 columns", 1="40 columns"
    apple2.SetSystemConfig(":a2_config", "40/80 Columns", 1 << 6, 0 << 6)
    -- ":kbd_lang_select", mask=$FF="Keyboard", 0="QWERTY", 1="DVORAK"
    apple2.SetSystemConfig(":kbd_lang_select", "Keyboard", 0xFF, 0)
  end
end

--------------------------------------------------
-- Lifecycle
--------------------------------------------------

local MINIMAL_REPAINT = 0.5

function a2d.WaitForCopyToRAMCard()
  emu.wait(20)
end

function a2d.WaitForRestart()
  emu.wait(10)
end

function a2d.WaitForRepaint()
  emu.wait(5)
end

--------------------------------------------------
-- Menus
--------------------------------------------------

for k,v in pairs({
    APPLE_MENU     = 1,
    FILE_MENU      = 2,
    EDIT_MENU      = 3,
    VIEW_MENU      = 4,
    SPECIAL_MENU   = 5,
    STARTUP_MENU   = 6,
    SHORTCUTS_MENU = 7,

    -- Note that effective menu offsets can change based on enable state!
    -- Prefer shortcut keys where available

    ABOUT_APPLE_II_DESKTOP = 1,
    ABOUT_THIS_APPLE_II    = 2,
    CONTROL_PANELS         = 3,
    CALCULATOR             = 6,
    CHANGE_TYPE            = 8,
    FIND_FILES             = 9,
    RUN_BASIC_HERE         = 11,
    SORT_DIRECTORY         = 12,

    FILE_NEW_FOLDER = 1,
    FILE_OPEN       = 2,
    FILE_CLOSE      = 3,
    FILE_CLOSE_ALL  = 4,
    FILE_GET_INFO   = 5,
    FILE_RENAME     = 6,
    FILE_DUPLICATE  = 7,
    FILE_COPY_TO    = 8,
    FILE_DELETE     = 9,
    FILE_QUIT       = 10,

    EDIT_CUT        = 1,
    EDIT_COPY       = 2,
    EDIT_PASTE      = 3,
    EDIT_CLEAR      = 4,
    EDIT_SELECT_ALL = 5,

    VIEW_AS_ICONS       = 1,
    VIEW_AS_SMALL_ICONS = 2,
    VIEW_BY_NAME        = 3,
    VIEW_BY_DATE        = 4,
    VIEW_BY_SIZE        = 5,
    VIEW_BY_TYPE        = 6,

    SPECIAL_CHECK_ALL_DRIVES = 1,
    SPECIAL_CHECK_DRIVE      = 2,
    SPECIAL_EJECT_DISK       = 3,
    SPECIAL_FORMAT_DISK      = 4,
    SPECIAL_ERASE_DISK       = 5,
    SPECIAL_COPY_DISK        = 6,
    SPECIAL_MAKE_ALIAS       = 7,
    SPECIAL_SHOW_ORIGINAL    = 8,

    -- Startup menu is entirely dynamic

    SHORTCUTS_ADD_A_SHORTCUT    = 1,
    SHORTCUTS_EDIT_A_SHORTCUT   = 2,
    SHORTCUTS_DELETE_A_SHORTCUT = 3,
    SHORTCUTS_RUN_A_SHORTCUT    = 4,

}) do a2d[k] = v end

function a2d.OpenMenu(mth)
  -- activate menu
  apple2.EscapeKey()
  emu.wait(MINIMAL_REPAINT)
  local i
  -- over to mth menu
  for i=2,mth do
    apple2.RightArrowKey()
    emu.wait(MINIMAL_REPAINT)
  end
  a2d.WaitForRepaint()
end

-- Invoke nth item on mth menu (1-based)
function a2d.InvokeMenuItem(mth, nth)
  a2d.OpenMenu(mth)
  -- down to nth item
  for i=1,nth do
    apple2.DownArrowKey()
    emu.wait(MINIMAL_REPAINT)
  end
  -- invoke
  apple2.ReturnKey()
  a2d.WaitForRepaint()
end

function a2d.OAShortcut(key)
  apple2.OAKey(key)
  a2d.WaitForRepaint()
end

function a2d.SAShortcut(key)
  apple2.SAKey(key)
  a2d.WaitForRepaint()
end

function a2d.OASAShortcut(key)
  apple2.OASAKey(key)
  a2d.WaitForRepaint()
end

--------------------------------------------------
-- Automations
--------------------------------------------------

function a2d.OpenSelection()
  a2d.OAShortcut("O")
  a2d.WaitForRepaint()
end

function a2d.OpenSelectionAndCloseCurrent()
  a2d.OASADown()
  a2d.WaitForRepaint()
end

function a2d.Select(name)
  a2d.ClearSelection()
  apple2.Type(name)
end

function a2d.SelectAndOpen(name, opt_close_current)
  a2d.Select(name)
  if opt_close_current then
    a2d.OpenSelectionAndCloseCurrent()
  else
    a2d.OpenSelection()
  end
end

function a2d.SelectAll()
  a2d.OAShortcut("A")
  emu.wait(2)
end

function a2d.CloseWindow()
  a2d.OAShortcut("W")
  a2d.WaitForRepaint()
end

function a2d.CloseAllWindows()
  a2d.OASAShortcut("W")
  a2d.WaitForRepaint()
end

function a2d.OpenPath(path, opt_leave_parent)
  a2d.CloseAllWindows()
  for segment in path:gmatch("([^/]+)") do
    a2d.SelectAndOpen(segment, not opt_leave_parent)
  end
end

function a2d.SelectPath(path)
  local base, name = path:match("^(.*)/([^/]+)$")
  if base ~= "" then
    a2d.OpenPath(base)
  end
  a2d.Select(name)
end

function a2d.ClearSelection()
  apple2.PressOA()
  apple2.EscapeKey()
  apple2.ReleaseOA()
  a2d.WaitForRepaint()
end

function a2d.DialogOK()
  apple2.ReturnKey()
  a2d.WaitForRepaint()
end

function a2d.DialogCancel()
  apple2.EscapeKey()
  a2d.WaitForRepaint()
end

function a2d.RenameSelection(newname)
  apple2.ReturnKey()
  apple2.ControlKey("X") -- clear
  apple2.Type(newname)
  apple2.ReturnKey()
  a2d.WaitForRepaint()
end

function a2d.RenamePath(path, newname)
  a2d.SelectPath(path)
  a2d.RenameSelection(newname)
end

function a2d.DeleteSelection()
  a2d.OADelete()
  emu.wait(5) -- wait for enumeration
  a2d.DialogOK() -- confirm delete
  emu.wait(5) -- wait for delete
end

function a2d.DeletePath(path)
  a2d.SelectPath(path)
  a2d.DeleteSelection()
end

function a2d.EraseVolume(name)
  a2d.SelectPath("/"..name)
  a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK)
  apple2.Type(name) -- new name
  a2d.DialogOK()
  a2d.WaitForRepaint()
  a2d.DialogOK() -- confirm overwrite
  emu.wait(5)
end

function a2d.CycleWindows()
  apple2.PressOA()
  apple2.TabKey()
  apple2.ReleaseOA()
  a2d.WaitForRepaint()
end

function a2d.AddShortcut(path)
  a2d.SelectPath(path)
  a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
  a2d.DialogOK()
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
  func({
      ButtonDown = a2d.MouseKeysButtonDown,
      ButtonUp = a2d.MouseKeysButtonUp,
      Click = a2d.MouseKeysClick,
      DoubleClick = a2d.MouseKeysDoubleClick,

      Up = a2d.MouseKeysUp,
      Down = a2d.MouseKeysDown,
      Left = a2d.MouseKeysLeft,
      Right = a2d.MouseKeysRight,

      Home = a2d.MouseKeysHome,
      MoveToApproximately = a2d.MouseKeysMoveToApproximately,
      MoveByApproximately = a2d.MouseKeysMoveByApproximately,
  })
  a2d.ExitMouseKeysMode()
  -- TODO: Without this, ClearSelection triggers menu. Why is delay needed?
  emu.wait(10/60)
end

function a2d.MouseKeysDoubleClick()
  a2d.MouseKeysClick()
  emu.wait(10/60)
  a2d.MouseKeysClick()
end

function a2d.MouseKeysClick()
  a2d.MouseKeysButtonDown()
  emu.wait(1/60)
  a2d.MouseKeysButtonUp()
  emu.wait(1/60)
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
  apple2.PressSA()
end

function a2d.MouseKeysButtonUp()
  apple2.ReleaseSA()
end

local MOUSE_KEYS_DELTA_X = 8
local MOUSE_KEYS_DELTA_Y = 4
function round(n)
  return math.floor(n + 0.5)
end

function a2d.MouseKeysHome()
  a2d.MouseKeysLeft(round(560 / MOUSE_KEYS_DELTA_X))
  a2d.MouseKeysUp(round(192 / MOUSE_KEYS_DELTA_Y))
end

function a2d.MouseKeysMoveToApproximately(x,y)
  a2d.MouseKeysHome() -- known location
  a2d.MouseKeysMoveByApproximately(x, y)
end

function a2d.MouseKeysMoveByApproximately(x,y)
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
end

--------------------------------------------------
-- Modifier Key Combos
--------------------------------------------------

function a2d.OADown()
  apple2.PressOA()
  apple2.DownArrowKey()
  apple2.ReleaseOA()
end

function a2d.OASADown()
  apple2.PressOA()
  apple2.PressSA()
  apple2.DownArrowKey()
  apple2.ReleaseSA()
  apple2.ReleaseOA()
end

function a2d.OADelete()
  apple2.PressOA()
  apple2.DeleteKey()
  apple2.ReleaseOA()
end

--------------------------------------------------

-- TODO:
-- * Need API to get window count
-- * Need API to get active window name
-- * Need API to get selected icon count
-- Idea: Generate Lua-friendly symbol table on build by processing listing file

--------------------------------------------------

function a2d.SetProDOSDate(y,m,d)
  local hi = (y % 100) << 1 | (m >> 4)
  local lo = (m << 5) | d
  apple2.WriteRAMDevice(0xBF90, lo)
  apple2.WriteRAMDevice(0xBF91, hi)
end

function a2d.SetProDOSTime(h, m)
  apple2.WriteRAMDevice(0xBF92, h)
  apple2.WriteRAMDevice(0xBF93, m)
end

--------------------------------------------------


return a2d
