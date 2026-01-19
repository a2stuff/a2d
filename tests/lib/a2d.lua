--[[============================================================

  Utilities for Apple II DeskTop

  ============================================================]]

local a2d = {}

local util = require("util")
local apple2 = require("apple2")
local mgtk = require("mgtk")

local function default_options(o)
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
    -- bit 6 = "40/80 Columns", 0="80 columns", 1="40 columns"
    apple2.SetSystemConfig(":a2_config", "40/80 Columns", 1 << 6, 0 << 6)
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

local repaint_time = 5

function a2d.WaitForRepaint()
  emu.wait(repaint_time)
end

function a2d.ConfigureRepaintTime(s)
  if s == nil or s == 0 then
    error("specify a non-zero time", 2)
  end
  repaint_time = s
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
    APPLE_EMPTY_SLOT       = 13,

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
-- (if nth is negative, from the bottom of menu)
function a2d.InvokeMenuItem(mth, nth, options)
  options = default_options(options)

  a2d.OpenMenu(mth)
  if nth > 0 then
    -- down to nth item
    for i=1,nth do
      apple2.DownArrowKey()
      emu.wait(2/60)
    end
  else
    for i=1,-nth do
      apple2.UpArrowKey()
      emu.wait(2/60)
    end
  end
  -- invoke
  apple2.ReturnKey()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

function a2d.OAShortcut(key, options)
  options = default_options(options)

  apple2.OAKey(key)
  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

function a2d.SAShortcut(key, options)
  options = default_options(options)

  apple2.SAKey(key)
  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

function a2d.OASAShortcut(key, options)
  options = default_options(options)

  apple2.OASAKey(key)
  if not options.no_wait then
    a2d.WaitForRepaint()
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

function a2d.OpenSelection()
  a2d.OAShortcut("O")
  a2d.WaitForRepaint() -- TODO: This is an extra wait - is it needed?
end

function a2d.OpenSelectionAndCloseCurrent()
  a2d.OASADown()
  a2d.WaitForRepaint()
end

local function CheckSelectionName(name, options)
  options = default_options(options)

  local selected = a2d.GetSelectedIcons()
  if #selected ~= 1 then
    error(string.format("Failed to select %q - have %d selected",
                        name, #selected), options.level)
  end
  if name:lower() ~= selected[1].name:lower() then
    error(string.format("Failed to select %q - have %q selected",
                        name, selected[1].name), options.level)
  end
end

function a2d.Select(name, options)
  options = default_options(options)

  a2d.ClearSelection()
  apple2.Type(name)
  a2d.WaitForRepaint() -- TODO: spin here?
  CheckSelectionName(name, options)
end

-- additional option: {close_current=true}
function a2d.SelectAndOpen(name, options)
  options = default_options(options)

  a2d.Select(name, options)
  if options.close_current then
    a2d.OpenSelectionAndCloseCurrent()
    emu.wait(1)
  else
    a2d.OpenSelection()
  end
end

function a2d.SelectAll()
  a2d.OAShortcut("A")
  emu.wait(2)
end

function a2d.CloseWindow(options)
  options = default_options(options)
  a2d.OAShortcut("W", options)
  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

function a2d.CloseAllWindows()
  a2d.OASAShortcut("W")
  util.WaitFor("all windows to close",
               function() return mgtk.FrontWindow() == 0 end)
end

-- additional option: {leave_parent=true}
function a2d.OpenPath(path, options)
  options = default_options(options)

  if options.leave_parent then
    options.close_current = false
  else
    options.close_current = true
  end

  if options.keep_windows then
    a2d.FocusDesktop()
  else
    a2d.CloseAllWindows()
  end
  for segment in path:gmatch("([^/]+)") do
    a2d.SelectAndOpen(segment, options)
  end
end

function a2d.SplitPath(path)
  return path:match("^(.*)/([^/]+)$")
end

function a2d.SelectPath(path, options)
  options = default_options(options)
  local base, name = a2d.SplitPath(path)
  if base ~= "" then
    a2d.OpenPath(base, options)
  elseif options.keep_windows then
    a2d.FocusDesktop()
  else
    a2d.CloseAllWindows()
  end
  a2d.Select(name, options)
end

function a2d.ClearSelection()
  apple2.PressOA()
  apple2.EscapeKey()
  apple2.ReleaseOA()
  a2d.WaitForRepaint()
end

function a2d.FocusDesktop()
  apple2.PressOA()
  apple2.ControlKey("D")
  apple2.ReleaseOA()
  a2d.WaitForRepaint()
end

function a2d.FocusActiveWindow()
  apple2.PressOA()
  apple2.ControlKey("W")
  apple2.ReleaseOA()
  a2d.WaitForRepaint()
end

function a2d.DialogOK(options)
  options = default_options(options)

  apple2.ReturnKey()
  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

function a2d.DialogCancel(options)
  options = default_options(options)

  apple2.EscapeKey()
  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

function a2d.RenameSelection(newname, options)
  options = default_options(options)
  if newname:match("^/") then
    error(string.format("%s: new name %q should not be a path",
                        debug.getinfo(1,"n").name, newname), options.level)
  end
  apple2.ReturnKey()
  a2d.ClearTextField()
  apple2.Type(newname)
  apple2.ReturnKey()
  emu.wait(5) -- I/O
  CheckSelectionName(newname, options)
end

function a2d.RenamePath(path, newname, options)
  options = default_options(options)
  if newname:match("^/") then
    error(string.format("%s: new name %q should not be a path",
                        debug.getinfo(1,"n").name, newname), options.level)
  end
  a2d.SelectPath(path, options)
  a2d.RenameSelection(newname, options)
end

function a2d.DuplicateSelection(newname, options)
  options = default_options(options)
  if newname == nil then
    error("DuplicateSelection: nil passed as newname", options.level)
  end
  a2d.OAShortcut("D")
  emu.wait(10) -- same as CopySelectionTo
  a2d.ClearTextField()
  apple2.Type(newname)
  apple2.ReturnKey()
  a2d.WaitForRepaint()
  CheckSelectionName(newname, options)
end

function a2d.DuplicatePath(path, newname)
  if newname:match("^/") then
    error(string.format("%s: new name %q should not be a path",
                        debug.getinfo(1,"n").name, newname), options.level)
  end
  a2d.SelectPath(path)
  a2d.DuplicateSelection(newname)
end

function a2d.DeleteSelection()
  a2d.OADelete()
  -- TODO: Wait for alert
  emu.wait(5) -- wait for enumeration
  a2d.DialogOK() -- confirm delete
  emu.wait(5) -- wait for delete
end

function a2d.DeletePath(path, options)
  options = default_options(options)
  a2d.SelectPath(path, options)
  a2d.DeleteSelection()
end

function a2d.CreateFolder(path, options)
  options = default_options(options)
  local name = path
  if path:match("/") then
    local base
    base, name = a2d.SplitPath(path)
    if base ~= "" then
      a2d.OpenPath(base, options)
    end
  end
  emu.wait(1) -- flaky without this
  a2d.OAShortcut("N") -- File > New Folder
  a2d.ClearTextField()
  apple2.Type(name)
  apple2.ReturnKey()
  emu.wait(5) -- I/O
  CheckSelectionName(name, options)
end

function a2d.FormatVolume(name, opt_new_name)
  a2d.SelectPath("/"..name)
  a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_FORMAT_DISK)
  if opt_new_name then
    a2d.ClearTextField()
    apple2.Type(opt_new_name)
  end
  a2d.DialogOK()
  -- TODO: WaitForAlert here (layering violation!)
  a2d.WaitForRepaint()
  a2d.DialogOK() -- confirm overwrite
  emu.wait(5) -- I/O
end

function a2d.EraseVolume(name, opt_new_name, options)
  options = default_options(options)
  a2d.SelectPath("/"..name, options)
  a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_ERASE_DISK)
  if opt_new_name then
    a2d.ClearTextField()
    apple2.Type(opt_new_name)
  end
  a2d.DialogOK()
  -- TODO: WaitForAlert here (layering violation!)
  a2d.WaitForRepaint()
  a2d.DialogOK() -- confirm overwrite
  emu.wait(5) -- I/O
end

function a2d.CopyDisk(opt_path)
  if opt_path == nil then
    a2d.ClearSelection()
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK-2)
  else
    a2d.SelectPath(opt_path)
    a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_COPY_DISK)
  end
  a2d.WaitForDesktopReady()
end

function a2d.CycleWindows()
  apple2.PressOA()
  apple2.TabKey()
  apple2.ReleaseOA()
  a2d.WaitForRepaint()
end

function a2d.AddShortcut(path, options)
  options = default_options(options)

  a2d.SelectPath(path, options)
  a2d.InvokeMenuItem(a2d.SHORTCUTS_MENU, a2d.SHORTCUTS_ADD_A_SHORTCUT)
  a2d.WaitForRepaint() -- extra, for I/O

  if options then
    if options.list_only == true then
      a2d.OAShortcut("2")
    end

    if options.copy == "boot" then
      a2d.OAShortcut("3")
    elseif options.copy == "use" then
      a2d.OAShortcut("4")
    end
  end

  a2d.DialogOK()
  a2d.WaitForRepaint() -- extra, for I/O
end

function a2d.CopySelectionTo(path, is_volume, options)
  options = default_options(options)

  -- Assert: there is a selection
  --[[
    But we don't know if it's 1 or more than 1 so we index
    from the bottom of the menu, which is a fixed number.
    TODO: Make this less hacky
  ]]
  a2d.InvokeMenuItem(a2d.FILE_MENU, is_volume and -2 or -3)

  --Automate file picker dialog
  apple2.ControlKey("D") -- Drives
  a2d.WaitForRepaint()
  for segment in path:gmatch("([^/]+)") do
    apple2.Type(segment)
    apple2.ControlKey("O") -- Open
    a2d.WaitForRepaint()
  end
  a2d.DialogOK(options)

  if not options.no_wait then
    emu.wait(10)
  end
end

function a2d.CopyPath(src, dst, options)
  a2d.SelectPath(src)
  local is_volume = not src:match("^/.*/")
  a2d.CopySelectionTo(dst, is_volume, options)
end

function a2d.CheckAllDrives(options)
  options = default_options(options)
  a2d.InvokeMenuItem(a2d.SPECIAL_MENU, a2d.SPECIAL_CHECK_ALL_DRIVES, options)
  if not options.no_wait then
    emu.wait(10)
  end
end

function a2d.FormatEraseSelectSlotDrive(slot, drive, options)
  options = default_options(options)
  -- List is presented in reverse order
  local list = apple2.GetProDOSDeviceList()
  local found = false
  for index = #list, 1, -1 do
    apple2.DownArrowKey()
    if list[index].slot == slot and list[index].drive == drive then
      found = true
      break
    end
  end
  if not found then
    error(string.format("Failed to select S%d,D%d", slot, drive))
  end
  if not options.no_ok then
    a2d.DialogOK()
  end
end

--------------------------------------------------
-- Configuration
--------------------------------------------------

function a2d.RemoveClockDriverAndReboot()
  a2d.DeletePath("/A2.DESKTOP/CLOCK.SYSTEM")
  a2d.Reboot()
  a2d.WaitForDesktopReady()
end

function a2d.ToggleOptionCopyToRAMCard()
  a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
  a2d.OAShortcut("1") -- Toggle "Copy to RAMCard"
  a2d.CloseWindow()
  a2d.CloseAllWindows()
end
function a2d.ToggleOptionShowShortcutsOnStartup()
  a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
  a2d.OAShortcut("2") -- Toggle "Show shortcuts on startup"
  a2d.CloseWindow()
  a2d.CloseAllWindows()
end
function a2d.ToggleOptionPreserveCase()
  a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
  a2d.OAShortcut("4") -- Toggle "Preserve uppercase and lowercase in names"
  a2d.CloseWindow()
  a2d.CloseAllWindows()
end
function a2d.ToggleOptionShowInvisible()
  a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS")
  a2d.OAShortcut("5") -- Toggle "Show invisible files"
  a2d.CloseWindow()
  a2d.CloseAllWindows()
end

function a2d.Quit()
  a2d.OAShortcut("Q")
  apple2.WaitForBitsy()
end

function a2d.QuitAndRestart()
  a2d.Quit()
  apple2.BitsyInvokeFile("PRODOS")
  a2d.WaitForDesktopReady()
end

-- Reboot via menu equivalent of PR#7 (or PR#5 on IIc+)
function a2d.Reboot(options)
  if manager.machine.system.name:match("^apple2cp") then
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 2) -- PR#5 (list is 6,5,...)
  else
    a2d.InvokeMenuItem(a2d.STARTUP_MENU, 1) -- startup volume index
  end
  apple2.ResetMouse()
end

-- TODO: Use this in Reboot, etc.
-- TODO: Ensure callers wait until idle, though
function a2d.WaitForDesktopShowing(options, level)
  if options == nil then options = {} end
  if level == nil then level = 0 end

  function IsDesktopShowing()
    -- TODO: Is there RDDHIRES (two 'D's) on anything but IIc?
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

  util.WaitFor("desktop", IsDesktopShowing, options, level+1)
end

function a2d.WaitForDesktopReady(options)
  emu.wait(1) -- Don't check too soon and see old module
  a2d.WaitForDesktopShowing(options, 1)
  emu.wait(5) -- TODO: Something better here
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

function a2d.MouseKeysDoubleClick()
  a2d.MouseKeysClick()
  emu.wait(10/60)
  a2d.MouseKeysClick()
end

function a2d.MouseKeysClick()
  apple2.SpaceKey()
end

function a2d.MouseKeysOAClick()
  apple2.PressOA()
  emu.wait(1/60)
  a2d.MouseKeysClick()
  emu.wait(1/60)
  apple2.ReleaseOA()
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
end

function a2d.MoveWindowBy(x, y, options)
  options = default_options(options)
  a2d.OAShortcut("M")
  a2d.MouseKeysMoveByApproximately(x,y)
  apple2.ReturnKey()
  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

function a2d.GrowWindowBy(x, y, options)
  options = default_options(options)
  a2d.OAShortcut("G")
  a2d.MouseKeysMoveByApproximately(x,y)
  apple2.ReturnKey()
  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

function a2d.DragSelectMultipleVolumes()
  a2d.InMouseKeysMode(function(m)
      m.MoveToApproximately(apple2.SCREEN_WIDTH,20)
      m.ButtonDown()
      m.MoveByApproximately(-80, 130)
      m.ButtonUp()
      a2d.WaitForRepaint()
  end)
end

function a2d.Drag(src_x, src_y, dst_x, dst_y, options)
  a2d.InMouseKeysMode(function(m)
      m.MoveToApproximately(src_x, src_y)
      m.ButtonDown()
      m.MoveToApproximately(dst_x, dst_y)

      if options and options.oa_drop then
        apple2.PressOA()
      end
      if options and options.sa_drop then
        apple2.PressSA()
      end

      m.ButtonUp()

      if options and options.oa_drop then
        apple2.ReleaseOA()
      end
      if options and options.sa_drop then
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
  options = default_options(options)
  apple2.PressOA()
  apple2.DownArrowKey()
  apple2.ReleaseOA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Page Down (alias)
function a2d.SADown(options)
  options = default_options(options)
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
  options = default_options(options)
  apple2.PressOA()
  apple2.UpArrowKey()
  apple2.ReleaseOA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Page Up (alias)
function a2d.SAUp(options)
  options = default_options(options)
  apple2.PressSA()
  apple2.UpArrowKey()
  apple2.ReleaseSA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Move to Start
function a2d.OALeft(options)
  options = default_options(options)
  apple2.PressOA()
  apple2.LeftArrowKey()
  apple2.ReleaseOA()

  if not options.no_wait then
    a2d.WaitForRepaint()
  end
end

-- Move to End
function a2d.OARight(options)
  options = default_options(options)
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
  options = default_options(options)
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
  options = default_options(options)
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
  options = default_options(options)
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

local function ram_u8(addr)
  return apple2.GetRAMDeviceProxy().read_u8(addr)
end

local function ram_u16(addr)
  return apple2.GetRAMDeviceProxy().read_u16(addr)
end

local function ram_s16(addr)
  return apple2.GetRAMDeviceProxy().read_s16(addr)
end

--------------------------------------------------
-- Icons
--------------------------------------------------

local DESKTOP_SYMBOLS = {}
for pair in emu.subst_env("$DESKTOP_SYMBOLS"):gmatch("([^ ]+)") do
  local k,v = pair:match("^(.+)=(.+)$")
  DESKTOP_SYMBOLS[k] = tonumber(v, 16)
end

local function ReadIcon(id)
  local icon = {}
  local icon_entries = DESKTOP_SYMBOLS["icon_entries"] | 0x010000

  local IconEntry = {
    state = 0,
    win_flags = 1,
    iconx = 2,
    icony = 4,
    typ = 6,
    name = 7,
    record_num = 23,
    SIZE = 24,
  }

  local addr = icon_entries + (id-1) * IconEntry.SIZE

  icon.id = id
  icon.state = ram_u8(addr + IconEntry.state)
  icon.window = ram_u8(addr + IconEntry.win_flags) & 0x0F
  icon.flags = ram_u8(addr + IconEntry.win_flags) & 0xF0
  icon.x = ram_s16(addr + IconEntry.iconx)
  icon.y = ram_s16(addr + IconEntry.icony)
  icon.name = apple2.GetPascalString(addr + IconEntry.name)
  icon.type = ram_u8(addr + IconEntry.typ)
  icon.record_num = ram_u8(addr + IconEntry.record_num)
  icon.dimmed = (icon.state & 0x80) ~= 0
  icon.highlighted = (icon.state & 0x40) ~= 0

  return icon
end

function a2d.GetSelectedIcons()
  local selected_icon_count_addr = DESKTOP_SYMBOLS['selected_icon_count'] | 0x010000
  local selected_icon_list_addr = DESKTOP_SYMBOLS['selected_icon_list'] | 0x010000

  local selected_icon_count = ram_u8(selected_icon_count_addr)

  local icons = {}

  for i = 0, selected_icon_count-1 do
    local id = ram_u8(selected_icon_list_addr + i)
    table.insert(icons, ReadIcon(id))
  end
  return icons
end

--------------------------------------------------

return a2d
