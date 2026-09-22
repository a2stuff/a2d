--[[============================================================

  Utilities for DeskTop module (the Finder-like one)

  ============================================================]]

local desktop = {}

local util = require("util")
local apple2 = require("apple2")
local mgtk = require("mgtk")
local a2d = require("a2d")

--------------------------------------------------
-- Symbol usage
--------------------------------------------------

--[[
  NOTE: Only DeskTop's are pulled in, although this library spans use
  of the Selector and Disk Copy modules. TODO: Better layering.
]]

local DESKTOP_SYMBOLS = util.GetSymbols("DESKTOP_SYMBOLS")
function WaitForDesktopSystemTask()
  apple2.WaitForMemoryRead(DESKTOP_SYMBOLS["TestInterceptSystemTask"])
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
    KEY_CAPS               = 10,
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

}) do desktop[k] = v end

--------------------------------------------------
-- Automations
--------------------------------------------------

--[[
  Assumes a window will be opened (directory window or DA); use
  {no_wait=true} to skip waiting for a system task afterwards.
]]
function desktop.OpenSelection(options)
  options = util.default_options(options)
  a2d.OAShortcut("O")

  if not options.no_wait then
    WaitForDesktopSystemTask()
  end
end

function desktop.OpenSelectionAndCloseCurrent()
  a2d.OASADown()
  WaitForDesktopSystemTask()
end

local function CheckSelectionName(name, options)
  options = util.default_options(options)

  local selected = desktop.GetSelectedIcons()
  if #selected ~= 1 then
    error(string.format("Failed to select %q - have %d selected",
                        name, #selected), options.level)
  end
  if name:lower() ~= selected[1].name:lower() then
    error(string.format("Failed to select %q - have %q selected",
                        name, selected[1].name), options.level)
  end
end

local function WaitForSelectionName(name, options)
  options = util.default_options(options)

  if not util.WaitForNoError(
    function()
      local selected = desktop.GetSelectedIcons()
      if #selected ~= 1 then
        return false
      end
      if name:lower() ~= selected[1].name:lower() then
        return false
      end
      return true
    end, {timeout=5}) then
    local selected = desktop.GetSelectedIcons()
    if #selected ~= 1 then
      error(string.format("Failed to select %q - have %d selected",
                          name, #selected), options.level)
    end
    if name:lower() ~= selected[1].name:lower() then
      error(string.format("Failed to select %q - have %q selected",
                          name, selected[1].name), options.level)
    end
  end
end

function desktop.Select(name, options)
  options = util.default_options(options)

  if not options.no_clear_selection then
    desktop.ClearSelection()
  end
  apple2.Type(name)
  WaitForDesktopSystemTask()
  WaitForSelectionName(name, options)
end

--[[
  additional option: {close_current=true} otherwise, {no_wait=true} to
  skip waiting for system task afterwards (e.g. if opening a
  screensaver)
]]
function desktop.SelectAndOpen(name, options)
  options = util.default_options(options)

  desktop.Select(name, options)
  if options.close_current then
    desktop.OpenSelectionAndCloseCurrent(options)
  else
    desktop.OpenSelection(options)
  end
end

function desktop.SelectAll()
  a2d.OAShortcut("A")
  WaitForDesktopSystemTask()
end

function desktop.CloseWindow(options)
  options = util.default_options(options)
  a2d.OAShortcut("W", options)
  if not options.no_wait then
    WaitForDesktopSystemTask()
  end
end

function desktop.CloseAllWindows()
  a2d.OASAShortcut("W")
  WaitForDesktopSystemTask()
end

--[[
  There are separate InvokePath() and OpenWindow() rather than a
  unified OpenPath() because if we are opening a window we want to
  perform extra validation at the end and know that we will remain in
  the DeskTop module, whereas invoking an arbitrary target may exit
  the module.

  Pass {no_wait=true} to skip waiting on a system task, e.g. if
  the result is a full-screen DA or exits the module.
]]

function desktop.InvokePath(path, options)
  options = util.default_options(options)

  desktop.SelectPath(path, options)
  WaitForDesktopSystemTask()

  a2d.OAShortcut("O") -- open
  if not options.no_wait then
    WaitForDesktopSystemTask()
  end
end

--[[
  Pass {no_validate=true} to skip validating the last segment, e.g. for
  when it is expected to fail.

  Pass {no_wait=true} to skip waiting after the last segment, e.g. to
  inspect the scrollbars as they are drawn.
]]
function desktop.OpenWindow(path, options)
  options = util.default_options(options)

  if options.leave_parent then
    options.close_current = false
  else
    options.close_current = true
  end

  if options.keep_windows then
    desktop.ClearSelectionAndFocusDesktop()
    options.no_clear_selection = true
  else
    desktop.CloseAllWindows()
  end

  local segments = {}
  for segment in path:gmatch("([^/]+)") do
    table.insert(segments, segment)
  end
  for index,segment in ipairs(segments) do
    desktop.SelectAndOpen(segment, options)

    --[[
      For any intermediate steps, or for the final step if not
      requested otherwise, validate that the expected window opened.
      This helps detect bugs in tests.
    ]]
    if index ~= #segments or not (options.no_validate or options.no_wait) then
      local top = mgtk.GetWindowName(assert(mgtk.FrontWindow()))
      if top:lower() ~= segment:lower() then
        error(string.format("%s: failed to open %q, top window is %q",
                            debug.getinfo(1,"n").name, segment, top), options.level)
      end
    end
  end
end

function desktop.SplitPath(path)
  return path:match("^(.*)/([^/]+)$")
end

function desktop.SelectPath(path, options)
  options = util.default_options(options)
  local base, name = desktop.SplitPath(path)
  if base ~= "" then
    desktop.OpenWindow(base, options)
  elseif options.keep_windows then
    desktop.ClearSelectionAndFocusDesktop()
    options.no_clear_selection = true
  else
    desktop.CloseAllWindows()
  end
  desktop.Select(name, options)
end

function desktop.ClearSelection()
  apple2.PressOA()
  apple2.EscapeKey()
  apple2.ReleaseOA()
  WaitForDesktopSystemTask()
end

function desktop.ClearSelectionAndFocusDesktop()
  apple2.PressOA()
  apple2.PressSA()
  apple2.EscapeKey()
  apple2.ReleaseSA()
  apple2.ReleaseOA()
  WaitForDesktopSystemTask()
end

function desktop.RenameSelection(newname, options)
  options = util.default_options(options)
  if newname:match("^/") then
    error(string.format("%s: new name %q should not be a path",
                        debug.getinfo(1,"n").name, newname), options.level)
  end
  apple2.ReturnKey()
  a2d.ClearTextField()
  apple2.Type(newname)
  apple2.ReturnKey()
  WaitForDesktopSystemTask()
  WaitForSelectionName(newname, options)
end

function desktop.RenamePath(path, newname, options)
  options = util.default_options(options)
  if newname:match("^/") then
    error(string.format("%s: new name %q should not be a path",
                        debug.getinfo(1,"n").name, newname), options.level)
  end
  desktop.SelectPath(path, options)
  desktop.RenameSelection(newname, options)
end

function desktop.DuplicateSelection(newname, options)
  options = util.default_options(options)
  if newname == nil then
    error("DuplicateSelection: nil passed as newname", options.level)
  end
  a2d.OAShortcut("D")
  WaitForDesktopSystemTask()
  a2d.ClearTextField()
  apple2.Type(newname)
  apple2.ReturnKey()
  WaitForDesktopSystemTask()
  WaitForSelectionName(newname, options)
end

function desktop.DuplicatePath(path, newname)
  if newname:match("^/") then
    error(string.format("%s: new name %q should not be a path",
                        debug.getinfo(1,"n").name, newname), options.level)
  end
  desktop.SelectPath(path)
  desktop.DuplicateSelection(newname)
end

function desktop.DeleteSelection()
  a2d.OADelete()
  WaitForDesktopSystemTask()
  a2d.DialogOK() -- confirm delete
  WaitForDesktopSystemTask()
end

function desktop.DeletePath(path, options)
  options = util.default_options(options)
  desktop.SelectPath(path, options)
  desktop.DeleteSelection()
end

function desktop.CreateFolder(path, options)
  options = util.default_options(options)
  local name = path
  if path:match("/") then
    local base
    base, name = desktop.SplitPath(path)
    if base ~= "" then
      desktop.OpenWindow(base, options)
    end
  end
  WaitForDesktopSystemTask()
  a2d.OAShortcut("N") -- File > New Folder
  a2d.ClearTextField()
  apple2.Type(name)
  apple2.ReturnKey()
  WaitForDesktopSystemTask()
  WaitForSelectionName(name, options)
end

function desktop.FormatVolume(name, opt_new_name)
  desktop.SelectPath("/"..name)
  a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_FORMAT_DISK)
  WaitForDesktopSystemTask()
  if opt_new_name then
    a2d.ClearTextField()
    apple2.Type(opt_new_name)
  end
  a2d.DialogOK()
  a2d.WaitForRepaint() -- TODO: WaitForAlert here (layering violation!)
  a2d.DialogOK() -- confirm overwrite
  WaitForDesktopSystemTask()
end

function desktop.EraseVolume(name, opt_new_name, options)
  options = util.default_options(options)
  desktop.SelectPath("/"..name, options)
  a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_ERASE_DISK)
  WaitForDesktopSystemTask()
  if opt_new_name then
    a2d.ClearTextField()
    apple2.Type(opt_new_name)
  end
  a2d.DialogOK()
  a2d.WaitForRepaint() -- TODO: WaitForAlert here (layering violation!)
  a2d.DialogOK() -- confirm overwrite
  WaitForDesktopSystemTask()
end

function desktop.CopyDisk(opt_path)
  if opt_path == nil then
    desktop.ClearSelection()
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_COPY_DISK-2)
    a2d.WaitForDesktopReady()
  else
    desktop.SelectPath(opt_path)
    a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_COPY_DISK)
    a2d.WaitForDesktopReady()
  end
end

function desktop.CycleWindows()
  apple2.PressOA()
  apple2.TabKey()
  apple2.ReleaseOA()
  WaitForDesktopSystemTask() -- updates
  WaitForDesktopSystemTask() -- idle
end

function desktop.AddShortcut(path, options)
  options = util.default_options(options)

  desktop.SelectPath(path, options)
  a2d.InvokeMenuItem(desktop.SHORTCUTS_MENU, desktop.SHORTCUTS_ADD_A_SHORTCUT)
  -- TODO: Workaround for https://github.com/mamedev/mame/issues/16167
  if manager.machine.system.name:match("^apple2gs") then
    emu.wait(1)
  else
    WaitForDesktopSystemTask()
  end

  if options.list_only == true then
    a2d.OAShortcut("2")
  end

  if options.copy == "boot" then
    a2d.OAShortcut("3")
  elseif options.copy == "use" then
    a2d.OAShortcut("4")
  end

  a2d.DialogOK()
  WaitForDesktopSystemTask()
end

function desktop.CopySelectionTo(path, is_volume, options)
  options = util.default_options(options)

  -- Assert: there is a selection
  --[[
    But we don't know if it's 1 or more than 1 so we index
    from the bottom of the menu, which is a fixed number.
    TODO: Make this less hacky
  ]]
  a2d.InvokeMenuItem(desktop.FILE_MENU, is_volume and -2 or -3)
  WaitForDesktopSystemTask()

  a2d.NavigateFilePickerTo(path)

  a2d.DialogOK(options)

  if not options.no_wait then
    WaitForDesktopSystemTask()
  end
end

function desktop.CopyPath(src, dst, options)
  desktop.SelectPath(src)
  local is_volume = not src:match("^/.*/")
  desktop.CopySelectionTo(dst, is_volume, options)
end

function desktop.CheckAllDrives(options)
  options = util.default_options(options)
  a2d.InvokeMenuItem(desktop.SPECIAL_MENU, desktop.SPECIAL_CHECK_ALL_DRIVES, options)
  if not options.no_wait then
    WaitForDesktopSystemTask()
  end
end

function desktop.FormatEraseSelectSlotDrive(slot, drive, options)
  options = util.default_options(options)
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

function desktop.RemoveClockDriverAndReboot()
  desktop.DeletePath("/A2.DESKTOP/CLOCK.SYSTEM")
  desktop.Reboot()
  a2d.WaitForDesktopReady()
end

function desktop.ToggleOptionCopyToRAMCard()
  desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS"))
  a2d.OAShortcut("1") -- Toggle "Copy to RAMCard"
  desktop.CloseWindow()
  desktop.CloseAllWindows()
end
function desktop.ToggleOptionShowShortcutsOnStartup()
  desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS"))
  a2d.OAShortcut("2") -- Toggle "Show shortcuts on startup"
  desktop.CloseWindow()
  desktop.CloseAllWindows()
end
function desktop.ToggleOptionShowKeyboardShortcuts()
  desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS"))
  a2d.OAShortcut("3") -- Toggle "Show keyboard shortcuts in dialogs"
  desktop.CloseWindow()
  desktop.CloseAllWindows()
end
function desktop.ToggleOptionPreserveCase()
  desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS"))
  a2d.OAShortcut("4") -- Toggle "Preserve uppercase and lowercase in names"
  desktop.CloseWindow()
  desktop.CloseAllWindows()
end
function desktop.ToggleOptionShowInvisible()
  desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS"))
  a2d.OAShortcut("5") -- Toggle "Show invisible files"
  desktop.CloseWindow()
  desktop.CloseAllWindows()
end
function desktop.ToggleOptionSkipChecking525Drives()
  desktop.InvokePath(a2d.GetLocalizedPath("/A2.DESKTOP/APPLE.MENU/CONTROL.PANELS/OPTIONS"))
  a2d.OAShortcut("6") -- Toggle "Check 5.25" drives on startup"
  desktop.CloseWindow()
  desktop.CloseAllWindows()
end

function desktop.Quit()
  a2d.OAShortcut("Q")
  apple2.WaitForBitsy()
end

function desktop.QuitAndRestart()
  desktop.Quit()
  apple2.BitsyInvokeFile("PRODOS")
  a2d.WaitForDesktopReady()
end

-- Reboot via menu equivalent of PR#7 (or PR#5 on IIc+)
function desktop.Reboot(options)
  options = util.default_options(options)
  if manager.machine.system.name:match("^apple2cp") then
    a2d.InvokeMenuItem(desktop.STARTUP_MENU, 2, options) -- PR#5 (list is 6,5,...)
  else
    a2d.InvokeMenuItem(desktop.STARTUP_MENU, 1, options) -- startup volume index
  end
  apple2.ResetMouse()
end

function desktop.MoveWindowBy(x, y, options)
  options = util.default_options(options)
  a2d.OAShortcut("M")
  a2d.MouseKeysMoveByApproximately(x,y)
  apple2.ReturnKey()
  if not options.no_wait then
    WaitForDesktopSystemTask() -- pick up update event
    WaitForDesktopSystemTask() -- idle after that
  end
end

function desktop.GrowWindowBy(x, y, options)
  options = util.default_options(options)
  a2d.OAShortcut("G")
  a2d.MouseKeysMoveByApproximately(x,y)
  apple2.ReturnKey()
  if not options.no_wait then
    WaitForDesktopSystemTask() -- pick up update event
    WaitForDesktopSystemTask() -- idle after that
  end
end

function desktop.DragSelectMultipleVolumes()
  a2d.InMouseKeysMode(function(m)
      m.MoveToApproximately(apple2.SCREEN_WIDTH,20)
      m.ButtonDown()
      m.MoveByApproximately(-80, 130)
      m.ButtonUp()
  end)
  WaitForDesktopSystemTask()
end

--------------------------------------------------
-- Icons
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

local function ReadIcon(id)
  local icon = {}
  local icon_entries = DESKTOP_SYMBOLS["icon_entries"] | 0x010000

  local IconEntry = {
    flags = 0,
    win_state = 1,
    iconx = 2,
    icony = 4,
    typ = 6,
    name = 7,
    record_num = 23,
    SIZE = 24,
  }

  local addr = icon_entries + (id-1) * IconEntry.SIZE

  icon.id = id
  icon.state = ram_u8(addr + IconEntry.win_state) & 0xF0
  icon.window = ram_u8(addr + IconEntry.win_state) & 0x0F
  icon.flags = ram_u8(addr + IconEntry.flags)
  icon.x = ram_s16(addr + IconEntry.iconx)
  icon.y = ram_s16(addr + IconEntry.icony)
  icon.name = apple2.GetPascalString(addr + IconEntry.name)
  icon.type = ram_u8(addr + IconEntry.typ)
  icon.record_num = ram_u8(addr + IconEntry.record_num)
  icon.dimmed = (icon.state & 0x80) ~= 0
  icon.highlighted = (icon.state & 0x40) ~= 0

  return icon
end

-- Based on enum in src/desktop/internals.inc
desktop.IconTypes = {
  -- volumes
  trash = 0,
  floppy140 = 1,
  ramdisk = 2,
  profile = 3,
  floppy800 = 4,
  fileshare = 5,
  cdrom = 6,

  -- files
  generic = 7,
  text = 8,
  binary = 9,
  graphics = 10,
  -- ...
  link = 27,
}

function desktop.GetSelectedIcons()
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

return desktop
