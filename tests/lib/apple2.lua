
--[[============================================================

  Generic utilities for Apple II

  ============================================================]]

local apple2 = {
  SCREEN_HEIGHT = 192,
  SCREEN_WIDTH = 560,
  SCREEN_COLUMNS = 80,
}

local util = require("util")

local machine = manager.machine

--------------------------------------------------
-- System Abstractions
--------------------------------------------------

local mouse
local auxram

-- Defaults (Apple IIe, Apple IIc)
local keyboard = {
  ["Return"]      = { port = ":X6", field = "Return" },
  ["Delete"]      = { port = ":X7", field = "Delete" },
  ["Escape"]      = { port = ":X0", field = "Esc" },
  ["Tab"]         = { port = ":X1", field = "Tab" },

  ["Up Arrow"]    = { port = ":X6", field = "↑" },
  ["Left Arrow"]  = { port = ":X7", field = "←" },
  ["Right Arrow"] = { port = ":X7", field = "→" },
  ["Down Arrow"]  = { port = ":X7", field = "↓" },

  -- modifiers
  ["Control"]     = { port = ":keyb_special", field = "Control"     },
  ["Shift"]       = { port = ":keyb_special", field = "Left Shift"  },
  ["Open Apple"]  = { port = ":keyb_special", field = "Open Apple"  },
  ["Solid Apple"] = { port = ":keyb_special", field = "Solid Apple" },

  -- Other
  ["Reset"]       = { port = ":keyb_special", field = "RESET"     },
  ["Caps Lock"]   = { port = ":keyb_special", field = "Caps Lock", bits = 0x01 },
}

local function get_device(pattern)
  for name,dev in pairs(machine.devices) do
    if name:match(pattern) then return dev end
  end
  error("Failed to find device " .. pattern)
end


local scan_for_mouse = false
if machine.system.name:match("^apple2e") or machine.system.name:match("^tk3000") then
  -- Apple IIe
  -- * mouse card required (if mouse is used)
  -- * many possible aux memory devices
  scan_for_mouse = true
  if emu.subst_env("$CHECKAUXMEMORY") == "true" then
    auxram = emu.item(get_device("^:aux:").items["0/m_ram"])
  end

elseif machine.system.name:match("^apple2c") then
  -- Apple IIc / Apple IIc Plus
  -- * built-in mouse port
  -- * aux memory is just exposed as RAM > 0xFFFF
  mouse = {
    x = { port = ":mse_x",      field = "Mouse X" },
    y = { port = ":mse_y",      field = "Mouse Y" },
    b = { port = ":mse_button", field = "Mouse Button" },
  }
elseif machine.system.name:match("^las.*128") then
  -- Laser 128
  -- * built-in mouse port
  -- * aux memory is just exposed as RAM > 0xFFFF
  mouse = {
    x = { port = ":mse_x",      field = "Mouse X" },
    y = { port = ":mse_y",      field = "Mouse Y" },
    b = { port = ":mse_button", field = "Mouse Button" },
  }

  keyboard["Open Apple"].field = "Open Triangle"
  keyboard["Solid Apple"].field = "Solid Triangle"

elseif machine.system.name:match("^apple2gs") then
  -- Apple IIgs
  -- * built-in mouse port (ADB)
  -- * aux memory is just exposed as RAM > 0xFFFF
  mouse = {
    x = { port = ":macadb:MOUSE1", field = "Mouse X" },
    y = { port = ":macadb:MOUSE2", field = "Mouse Y" },
    b = { port = ":macadb:MOUSE0", field = "Mouse Button 0" },
  }

  keyboard = {
    ["Return"]      = { port = ":macadb:KEY2", field = "Return" },
    ["Delete"]      = { port = ":macadb:KEY3", field = "Backspace" },
    ["Escape"]      = { port = ":macadb:KEY3", field = "Esc" },
    ["Tab"]         = { port = ":macadb:KEY3", field = "Tab" },

    ["Up Arrow"]    = { port = ":macadb:KEY3", field = "Up Arrow"    },
    ["Left Arrow"]  = { port = ":macadb:KEY3", field = "Left Arrow"  },
    ["Right Arrow"] = { port = ":macadb:KEY3", field = "Right Arrow" },
    ["Down Arrow"]  = { port = ":macadb:KEY3", field = "Down Arrow"  },

    -- modifiers
    ["Control"]     = { port = ":macadb:KEY3", field = "Control"    },
    ["Shift"]       = { port = ":macadb:KEY3", field = "Shift"      },
    ["Open Apple"]  = { port = ":macadb:KEY3", field = "Command"    },
    ["Solid Apple"] = { port = ":macadb:KEY3", field = "Option"     },

    -- Other
    ["Reset"]     = { port = ":macadb:KEY5", field = "Reset / Power" },
    ["Caps Lock"] = { port = ":macadb:KEY3", field = "Caps Lock", bits = 0x0200 },
  }
elseif machine.system.name:match("^ace500") then
  -- Franklin ACE 500
  -- * has built-in mouse port
  -- * built-in aux memory device
  auxram = emu.item(get_device("^:aux$").items["0/m_ram"])

  mouse = {
    x = { port = ":mse_x",      field = "Mouse X" },
    y = { port = ":mse_y",      field = "Mouse Y" },
    b = { port = ":mse_button", field = "Mouse Button" },
  }

  keyboard["Open Apple"].field = "Open F"
  keyboard["Solid Apple"].field = "Solid F"
  keyboard["Reset"].field = "RESET"

elseif machine.system.name:match("^ace2200") then
  -- Franklin ACE 2200
  -- * mouse card required
  -- * built-in aux memory device
  auxram = emu.item(get_device("^:aux$").items["0/m_ram"])

  scan_for_mouse = true

  keyboard["Open Apple"].field = "Open F"
  keyboard["Solid Apple"].field = "Solid F"
  keyboard["Reset"].field = "RESET"
elseif machine.system.name:match("^apple2p") then
  -- minimal support for launcher testing

  if machine.ioport.ports[":keyb_special"] then
    -- MAME through 0.283
    keyboard = {
      ["Control"]     = { port = ":keyb_special", field = "Control"     },
      ["Shift"]       = { port = ":keyb_special", field = "Left Shift"  },

      ["Right Arrow"] = { port = ":X2", field = "→" },
      ["Down Arrow"]  = { port = ":X2", field = "↓"  },
      ["Return"]      = { port = ":X4", field = "Return" },
      ["Escape"]      = { port = ":X4", field = "Esc"    }
    }
  elseif machine.ioport.ports[":kbd:nkbd:keyb_special"] then
    -- MAME from 0.284
    keyboard = {
      ["Control"]     = { port = ":kbd:nkbd:keyb_special", field = "Ctrl"        },
      ["Shift"]       = { port = ":kbd:nkbd:keyb_special", field = "Left Shift"  },

      ["Right Arrow"] = { port = ":kbd:nkbd:X2", field = "Cursor Right" },
      ["Down Arrow"]  = { port = ":kbd:nkbd:X2", field = "Cursor Left"  },
      ["Return"]      = { port = ":kbd:nkbd:X4", field = "Return" },
      ["Escape"]      = { port = ":kbd:nkbd:X4", field = "Esc"    }
    }
  else
    error(string.format(
            "Unable to identify keyboard port for %s - was MAME updated?",
            machine.system.name))
  end
else
  error("Unknown model: " .. machine.system.name)
end

function EnsureMouse()
  if scan_for_mouse then
    local mousedev = get_device("^:sl.:mouse$").tag
    mouse = {
      x = { port = mousedev .. ":a2mse_x",      field = "Mouse X" },
      y = { port = mousedev .. ":a2mse_y",      field = "Mouse Y" },
      b = { port = mousedev .. ":a2mse_button", field = "Mouse Button" },
    }
    scan_for_mouse = false
  end
end

--------------------------------------------------
-- General System Configuration
--------------------------------------------------

local function get_port(port_name)
  local port = machine.ioport.ports[port_name]
  if port == nil then
    error("No such port: " .. port_name)
  end
  return port
end

local function get_field(port_name, field_name)
  local port = get_port(port_name)
  local field = port.fields[field_name]
  if field == nil then
    error("No field \"" .. field_name .. "\" for port: " .. port_name)
  end
  return field
end

function apple2.SetSystemConfig(port_name, field_name, mask, value)
  local port = get_port(port_name)
  local field = get_field(port_name, field_name)
  local initial = port:read()
  while (port:read() & mask) ~= value do
    -- each field toggle advances to the next setting (or wraps)
    field:clear_value()
    emu.wait(2/60)
    field:set_value(1) -- anything
    emu.wait(2/60)

    if port:read() == initial then
      error("Cycled field \"" .. field_name .. "\" on port \"" .. port_name .. "\" without hitting target value")
    end
  end
end

-- TODO: Come up with better API for this?
--[[
  https://github.com/mamedev/mame/blob/master/src/mame/apple/apple2e.cpp

  ":a2_config"

  IIe: bit 4 = "CPU type": 0="Standard", 1="4MHz Zip Chip"
  IIe: bit 5 = "Bootup speed": 0="Standard", 1="4MHz"

  Laser 128: bit 3 = "Printer Type", 0="Serial", 1="Parallel"
  Laser 128: bit 6 = "40/80 Columns", 0="80 columns", 1="40 columns"
  Laser 128: ":kbd_lang_select", mask=$FF="Keyboard", 0="QWERTY", 1="DVORAK"

  IIc: bit 6 = "40/80 Columns", 0="80 columns", 1="40 columns"
  IIc: bit 4 = "CPU type": 0="Standard", 1="4MHz Zip Chip"
  IIc: bit 5 = "Bootup speed": 0="Standard", 1="4MHz"

  IIgs: bits 0-7 = "CPU type": 0="Standard", 1="7MHz ZipGS", 3="8MHz ZipGS", 5="12MHz ZipGS", 7="16MHz ZipGS"
]]



--------------------------------------------------
-- System Configuration: Video
--------------------------------------------------

-- https://github.com/mamedev/mame/blob/master/src/mame/apple/apple2video.cpp

--[[
  For the non-IIgs models:

  ":a2video:a2_video_config"
    field             mask
    ----------------- -----------
    "Monitor type"    00_00000111
    "Color algorithm" 00_01110000
    "Lores artifacts" 00_10000000
    "Text color"      11_00000000
  ]]


local function SetVideoConfig(field_name, value, mask, shift)
  apple2.SetSystemConfig(":a2video:a2_video_config", field_name, mask << shift, value << shift)
  emu.wait(2/60)
end


for k,v in pairs({
  MONITOR_TYPE_COLOR   = 0,
  MONITOR_TYPE_VIDEO7  = 3, -- not available on IIc
  MONITOR_TYPE_BW      = 4,
  MONITOR_TYPE_GREEN   = 5,
  MONITOR_TYPE_AMBER   = 6,
  MONITOR_TYPE_BWNTSC  = 7,

  ALGORITHM_BWBIAS     = 0,
  ALGORITHM_COLORBIAS  = 1,
  ALGORITHM_BOXFILTER  = 2,

  TEXTCOLOR_MODE_OFF   = 0,
  TEXTCOLOR_MODE_40COL = 1,
  TEXTCOLOR_MODE_ON    = 3,

  LORES_ARTIFACTS_OFF  = 0,
  LORES_ARTIFACTS_ON   = 1,
}) do apple2[k] = v end

local MONITOR_TYPE_MASK     = 0x07
local MONITOR_TYPE_SHIFT    = 0
local ALGORITHM_MASK        = 0x70
local ALGORITHM_SHIFT       = 4
local TEXTCOLOR_MODE_MASK   = 0x300
local TEXTCOLOR_MODE_SHIFT  = 8
local LORES_ARTIFACTS_MASK  = 1
local LORES_ARTIFACTS_SHIFT = 7

function apple2.SetMonitorType(mode)
  SetVideoConfig("Monitor type", mode, MONITOR_TYPE_MASK, MONITOR_TYPE_SHIFT)
end
function apple2.SetColorAlgorithm(mode)
  SetVideoConfig("Color algorithm", mode, ALGORITHM_MASK, ALGORITHM_SHIFT)
end
function apple2.SetLoresArtifacts(mode)
  SetVideoConfig("Lores artifacts", mode, LORES_ARTIFACTS_MASK, LORES_ARTIFACTS_SHIFT)
end
function apple2.SetTextColorMode(mode)
  SetVideoConfig("Text color", mode, TEXTCOLOR_MODE_MASK, TEXTCOLOR_MODE_SHIFT)
end

--------------------------------------------------
-- Keyboard Input
--------------------------------------------------

local kbd = machine.natkeyboard

local function wait_for_kbd_strobe_clear()
  while apple2.ReadSSW("KBD") > 127 do
    emu.wait(1/60)
  end
end

-- https://docs.mamedev.org/luascript/ref-input.html#natural-keyboard-manager
function apple2.Type(sequence)
  for i=1,sequence:len() do
    kbd:post(sequence:sub(i,i))
    while kbd.is_posting do
      emu.wait(1/60)
    end
    wait_for_kbd_strobe_clear()
  end
end

function apple2.TypeLine(sequence)
  apple2.Type(sequence)
  apple2.ReturnKey()
end

local function press(k)
  get_field(keyboard[k].port, keyboard[k].field):set_value(1)
end
local function release(k)
  get_field(keyboard[k].port, keyboard[k].field):clear_value()
end
local function press_and_release(k)
  press(k)
  emu.wait(2/60)
  release(k)
  emu.wait(2/60)
end

function apple2.IsCapsLockOn()
  local key = keyboard["Caps Lock"]
  if key == nil then
    return false -- Apple ][+ compat
  end
  local bits = get_port(key.port):read()
  return (bits & key.bits) ~= 0
end

function apple2.ToggleCapsLock()
  press_and_release("Caps Lock")
end

function apple2.CapsLockOn()
  if not apple2.IsCapsLockOn() then
    apple2.ToggleCapsLock()
  end
end

function apple2.CapsLockOff()
  if apple2.IsCapsLockOn() then
    apple2.ToggleCapsLock()
  end
end

function apple2.ControlReset()
  apple2.PressControl()
  press("Reset")
  emu.wait(2/60)
  release("Reset")
  apple2.ReleaseControl()
  emu.wait(1/60)
end

function apple2.ControlOAReset()
  press("Open Apple")
  apple2.ControlReset()
  release("Open Apple")
end

function apple2.ControlKey(key)
  apple2.PressControl()
  apple2.Type(key)
  apple2.ReleaseControl()
end

function apple2.SpaceKey()
  apple2.Type(" ")
end

function apple2.TabKey()
  press_and_release("Tab")
  wait_for_kbd_strobe_clear()
end

function apple2.ReturnKey()
  press_and_release("Return")
  wait_for_kbd_strobe_clear()
end

function apple2.DeleteKey()
  press_and_release("Delete")
  wait_for_kbd_strobe_clear()
end

function apple2.EscapeKey()
  press_and_release("Escape")
  wait_for_kbd_strobe_clear()
end

function apple2.LeftArrowKey()
  press_and_release("Left Arrow")
  wait_for_kbd_strobe_clear()
end

function apple2.RightArrowKey()
  press_and_release("Right Arrow")
  wait_for_kbd_strobe_clear()
end

function apple2.UpArrowKey()
  press_and_release("Up Arrow")
  wait_for_kbd_strobe_clear()
end

function apple2.DownArrowKey()
  press_and_release("Down Arrow")
  wait_for_kbd_strobe_clear()
end

function apple2.PressOA()
  press("Open Apple")
  emu.wait(1/60)
end

function apple2.ReleaseOA()
  release("Open Apple")
  emu.wait(1/60)
end

function apple2.PressSA()
  press("Solid Apple")
  emu.wait(1/60)
end

function apple2.ReleaseSA()
  release("Solid Apple")
  emu.wait(1/60)
end

function apple2.PressControl()
  press("Control")
  emu.wait(1/60)
end

function apple2.ReleaseControl()
  release("Control")
  emu.wait(1/60)
end

function apple2.PressShift()
  press("Shift")
  emu.wait(1/60)
end

function apple2.ReleaseShift()
  release("Shift")
  emu.wait(1/60)
end

function apple2.OAKey(key)
  apple2.PressOA()
  apple2.Type(key)
  emu.wait(1/60)
  apple2.ReleaseOA()
end

function apple2.SAKey(key)
  apple2.PressSA()
  apple2.Type(key)
  emu.wait(1/60)
  apple2.ReleaseSA()
end

function apple2.OASAKey(key)
  apple2.PressOA()
  apple2.PressSA()
  apple2.Type(key)
  emu.wait(1/60)
  apple2.ReleaseSA()
  apple2.ReleaseOA()
end

--------------------------------------------------
-- Joystick/Paddles
--------------------------------------------------

-- NOTE: On `apple2e` (etc) need `-gameio joy` or equivalent to enable

function apple2.SetJoy1(x,y)
  local xport = machine.ioport.ports[":gameio:joy:joystick_1_x"]
  local yport = machine.ioport.ports[":gameio:joy:joystick_1_y"]
  if not xport or not yport then
    error("No joystick ports present")
  end
  xport.fields["P1 Joystick X"]:set_value(x)
  yport.fields["P1 Joystick Y"]:set_value(y)
  emu.wait(1/10)
end

function apple2.SetJoy2(x,y)
  local xport = machine.ioport.ports[":gameio:joy:joystick_2_x"]
  local yport = machine.ioport.ports[":gameio:joy:joystick_2_y"]
  if not xport or not yport then
    error("No joystick ports present")
  end
  xport.fields["P2 Joystick X"]:set_value(x)
  yport.fields["P2 Joystick Y"]:set_value(y)
  emu.wait(1/10)
end

--------------------------------------------------
-- Mouse
--------------------------------------------------

local function clamp(n, min, max)
  if n < min then
    return min
  elseif n > max then
    return max
  else
    return n
  end
end

-- Can't move mouse more than 127 at a time, so track current position
local mouse_x = 0
local mouse_y = 0

-- Just updates our notion of where the mouse is
function apple2.ResetMouse()
  mouse_x = 0
  mouse_y = 0
end

function apple2.PressMouseButton()
  EnsureMouse()
  local field = get_field(mouse.b.port, mouse.b.field)
  field:set_value(1)
  emu.wait(1/60)
end

function apple2.ReleaseMouseButton()
  EnsureMouse()
  local field = get_field(mouse.b.port, mouse.b.field)
  field:clear_value()
  emu.wait(1/60)
end

function apple2.ClickMouseButton()
  apple2.PressMouseButton()
  apple2.ReleaseMouseButton()
end

function apple2.DoubleClickMouseButton()
  apple2.ClickMouseButton()
  emu.wait(10/60)
  apple2.ClickMouseButton()
end

function apple2.MoveMouse(x, y)
  --[[
    reading:

    # maxes out at 256
    machine.ioport.ports[mouse.x.port]:read()
    machine.ioport.ports[mouse.y.port]:read()

    # this is low level hardware... need to snoop at higher level
    # maybe screen holes?
    # but there's also scaling. Ugh.


  ]]

  EnsureMouse()

  local MAX_DELTA = 127

  repeat
    local delta_x = clamp(x - mouse_x, -MAX_DELTA, MAX_DELTA)
    if delta_x ~= 0 then
      mouse_x = mouse_x + delta_x
      get_field(mouse.x.port, mouse.x.field):set_value(mouse_x)
      emu.wait(10/60)
      -- print(machine.ioport.ports[mouse.x.port]:read())
    end
  until delta_x == 0
  emu.wait(1)

  repeat
    local delta_y = clamp(y - mouse_y, -MAX_DELTA, MAX_DELTA)
    if delta_y ~= 0 then
      mouse_y = mouse_y + delta_y
      get_field(mouse.y.port, mouse.y.field):set_value(mouse_y)
      emu.wait(10/60)
      -- print(machine.ioport.ports[mouse.y.port]:read())
    end
  until delta_y == 0
  emu.wait(1)
end

--------------------------------------------------
-- Memory
--------------------------------------------------

-- This is a "hardware" view of memory; i.e. the MMU/softswitch states
-- are ignored, which is useful as the banking configuration changes
-- constantly. Instead, call with explicit bank selection in the
-- address.

-- Note that internally MAME models LC memory on the IIe as:
-- * $D000/1 is presented at $C000
-- * $D000/2 is presented at $D000
-- * $E000 is presented at $F000
-- * $F000 is presented at $E000
-- For Apple IIe devices, Auxiliary RAM is a separate device. For
-- others, it just exists at 0x10000 and up.
--
-- The IIgs swaps E/F, but not the two D banks!


-- The ReadRAMDevice/WriteRAMDevice calls normalize this; call with
-- 0x0nnnn to access Main RAM and 0x1nnnn to acces Aux RAM. For
-- LCBANK2 use 0xbCnnnn instead of 0xDnnnn.

-- RAM should be device tag ":ram" item name "0/m_pointer" but
-- MAME 0.284 introduced https://github.com/mamedev/mame/issues/14762
-- so hunt for it using pattern matching.
local ram
for i,_ in pairs(machine.devices[":ram"].items) do
  if i:match("0/.*m_pointer") then
    ram = emu.item(machine.devices[":ram"].items[i])
    break
  end
end

local function swizzle(addr)
  -- Assume LCBANK1 is desired
  if machine.system.name:match("^apple2gs") then
    if (addr & 0xE000) == 0xE000 then
      return addr ~ 0x1000
    end
  elseif (addr & 0xC000) == 0xC000 then
    return addr ~ 0x1000
  end
  --print("not swizzled")
  return addr
end

function apple2.ReadRAMDevice(addr)
  addr = swizzle(addr)

  -- Apple IIe exposes Aux RAM as a separate device
  if addr >= 0x10000 and auxram ~= nil then
    return auxram:read(addr - 0x10000)
  else
    return ram:read(addr)
  end
end

function apple2.WriteRAMDevice(addr, value)
  addr = swizzle(addr)

  -- Apple IIe exposes Aux RAM as a separate device
  if addr >= 0x10000 and auxram ~= nil then
    auxram:write(addr - 0x10000, value)
  else
    ram:write(addr, value)
  end
end

--------------------------------------------------
-- Machine State
--------------------------------------------------

-- This is a "software" view of memory; i.e. the MMU/softswitch states
-- determines which banks (Main vs. Aux, LCBANK1 vs. LCBANK2 vs. ROM)
-- are accessed

-- Most useful for reading/writing softswitches
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]

function apple2.ReadMemory(addr)
  return mem:read_u8(addr)
end

function apple2.WriteMemory(addr, value)
  return mem:write_u8(addr, value)
end

local ssw = {
  KBD          = 0xC000,        -- (R) keyboard
  CLR80STORE   = 0xC000,        -- (W) restore normal PAGE2 control
  SET80STORE   = 0xC001,        -- (W) cause PAGE2 to bank display memory

  RAMRDOFF     = 0xC002,        -- (W) Read from main 48K RAM ($200-$BFFF)
  RAMRDON      = 0xC003,        -- (W) Read from auxiliary 48K RAM ($200-$BFFF)
  RAMWRTOFF    = 0xC004,        -- (W) Write to main 48K RAM ($200-$BFFF)
  RAMWRTON     = 0xC005,        -- (W) Write to auxiliary 48K RAM ($200-$BFFF)
  SETSLOTCXROM = 0xC006,        -- (W) Bank in slot ROM in $C100-$CFFF      (IIe/IIgs)
  SETINTCXROM  = 0xC007,        -- (W) Bank in internal ROM in $C100-$CFFF  (IIe/IIgs)
  ALTZPOFF     = 0xC008,        -- (W) Use main zero page/stack/LC
  ALTZPON      = 0xC009,        -- (W) Use aux zero page/stack/LC
  SETINTC3ROM  = 0xC006,        -- (W) ROM in Slot 3                        (IIe/IIgs)
  SETSLOTC3ROM = 0xC007,        -- (W) ROM in Aux Slot                      (IIe/IIgs)
  CLR80VID     = 0xC00C,        -- (W) Disable 80-column hardware
  SET80VID     = 0xC00D,        -- (W) Enable 80-column hardware
  CLRALTCHAR   = 0xC00E,        -- (W) Primary character set
  SETALTCHAR   = 0xC00F,        -- (W) Alternate character set (MouseText)

  KBDSTRB      = 0xC010,        -- (R/W) clear keyboard strobe
  RDLCBNK2     = 0xC011,        -- (R7) bit 7=1 if LCBANK2 enabled
  RDLCRAM      = 0xC012,        -- (R7) bit 7=1 if LC RAM (0=ROM)
  RDRAMRD      = 0xC013,        -- (R7) bit 7=1 if reading auxiliary RAM
  RDRAMWRT     = 0xC014,        -- (R7) bit 7=1 if writing auxiliary RAM
  RDCXROM      = 0xC015,        -- (R7)                                     (IIe/IIgs)
  RDALTZP      = 0xC016,        -- (R7) bit 7=1 if auxiliary ZP/stack/LC enabled
  RDC3ROM      = 0XC017,        -- (R7)                                     (IIe/IIgs)
  RD80STORE    = 0xC018,        -- (R7) bit 7=1 if 80STORE enabled
  RDVBL        = 0xC019,        -- (R7) Vertical blanking
  RDTEXT       = 0xC01A,        -- (R7) bit 7=1 if text
  RDMIXED      = 0xC01B,        -- (R7) bit 7=1 if mixed
  RDPAGE2      = 0xC01C,        -- (R7) bit 7=1 if PAGE2 on
  RDHIRES      = 0xC01D,
  RDALTCHAR    = 0xC01E,        -- (R7) bit 7=1 if ALTCHAR on
  RD80VID      = 0xC01F,

  MONOCOLOR    = 0xC021,        -- IIgs - bit 7=1 switches composite to mono
  TBCOLOR      = 0xC022,        -- IIgs - text foreground/background colors
  KEYMODREG    = 0xC025,        -- IIgs - keyboard modifiers
  NEWVIDEO     = 0xC029,        -- IIgs - new video modes
  MACIIE       = 0xC02B,        -- Macintosh IIe Option Card

  SPKR         = 0xC030,
  CLOCKCTL     = 0xC034,        -- IIgs
  SHADOW       = 0xC035,        -- IIgs

  TXTCLR       = 0xC050,        -- (R/W) Graphics
  TXTSET       = 0xC051,        -- (R/W) Text
  MIXCLR       = 0xC052,        -- (R/W) Fullscreen
  MIXSET       = 0xC053,        -- (R/W) Mixed screen
  PAGE2OFF     = 0xC054,        -- (R/W) Page 1
  PAGE2ON      = 0xC055,        -- (R/W) Page 2
  HIRESOFF     = 0xC056,        -- (R/W) High resolution graphics
  HIRESON      = 0xC057,        -- (R/W) Low resolution graphics

  DISVBL       = 0xC05A,        -- (W) Disable VBL interrupts      (IIc)
  ENVBL        = 0xC05B,        -- (W) Enable VBL interrupts       (IIc)

  AN0_OFF      = 0xC058,        -- (W)
  AN0_ON       = 0xC059,        -- (W)
  AN1_OFF      = 0xC05A,        -- (W)
  AN1_ON       = 0xC05B,        -- (W)
  AN2_OFF      = 0xC05C,        -- (W)
  AN2_ON       = 0xC05D,        -- (W)
  AN3_OFF      = 0xC05E,        -- (W)
  AN3_ON       = 0xC05F,        -- (W)
  DHIRESON     = 0xC05E,        -- (W) Double high resolution graphics on
  DHIRESOFF    = 0xC05F,        -- (W) Double high resolution graphics off


  BUTN0        = 0xC061,        -- (R)
  BUTN1        = 0xC062,        -- (R)
  BUTN2        = 0xC063,        -- (R)
  PDL0         = 0xC064,        -- (R)
  PDL1         = 0xC065,        -- (R)
  PDL2         = 0xC066,        -- (R)
  PDL3         = 0xC067,        -- (R)

  STATEREG     = 0xC068,        -- Mega II chip (IIgs, etc)

  PTRIG        = 0xC070,

  RAMWORKS_BANK   = 0xC073,
  LASER128EX_CFG  = 0xC074,     -- high two bits control speed

  IOUDISON     = 0xC07E,        -- (W) Disable IOU access          (IIc)
  RDIOUDIS     = 0xC07E,        -- (R7) Read IOUDIS switch (1=on)  (IIc)
  IOUDISOFFF   = 0xC07F,        -- (W) Enable IOU access           (IIc)

  RDDHIRES     = 0xC07F,        -- (R7) Read DHIRES switch (0=on)  (IIc)

  ROMIN2       = 0xC082,        -- (W) Read ROM; no write
}

function apple2.ReadSSW(symbol)
  return apple2.ReadMemory(ssw[symbol])
end
function apple2.WriteSSW(symbol, value)
  apple2.WriteMemory(ssw[symbol], value)
end

--------------------------------------------------
-- Misc Utilities
--------------------------------------------------

-- Address must include bank offset
function apple2.GetPascalString(addr)
  -- NOTE: Doesn't handle non-ASCII encodings
  local len = apple2.ReadRAMDevice(addr)
  local str = ""
  for i = 1,len do
    str = str .. string.char(apple2.ReadRAMDevice(addr+i))
  end
  return str
end

local function GetDHRByteAddress(row, col)
  local bank = col % 2
  col = col >> 1
  local aa = (row & 0xC0) >> 6
  local bbb = (row & 0x38) >> 3
  local ccc = (row & 0x07)
  return bank, 0x2000 + (aa * 0x28) + (bbb * 0x80) + (ccc * 0x400) + col
end

function apple2.GetDHRByte(row, col)
  local bank, addr = GetDHRByteAddress(row, col)
  return apple2.ReadRAMDevice(addr + 0x10000 * (1-bank)) & 0x7F
end

function apple2.SetDHRByte(row, col, value)
  local bank, addr = GetDHRByteAddress(row, col)
  apple2.WriteRAMDevice(addr + 0x10000 * (1-bank), value)
end

function IterateTextScreen(char_cb, row_cb)
  local is80 = apple2.ReadSSW("RD80VID") > 127
  local isAlt = apple2.ReadSSW("RDALTCHAR") > 127
  for row = 0,23 do
    local base = 0x400 + (row - math.floor(row/8) * 8) * 0x80 + 40 * math.floor(row/8)
    for col = 0,39 do
      if is80 then
        char_cb(apple2.ReadRAMDevice(0x10000 + base + col), isAlt)
      end
      char_cb(apple2.ReadRAMDevice(base + col), isAlt)
    end
    row_cb()
  end
end
function apple2.GrabTextScreen()
  -- Apple IIe and later, non-MouseText
  -- 0x00-0x1F: Inverse  @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_
  -- 0x20-0x3F: Inverse  !"#$%&'()*+,-./0123456789:;<=>?@
  -- 0x40-0x5F: Flashing @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_ (ALTCHAR - MouseText)
  -- 0x60-0x7F: Flashing !"#$%&'()*+,-./0123456789:;<=>?@ (ALTCHAR - inverse lower)
  -- 0x80-0x9F: Normal   @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_
  -- 0xA0-0xBF: Normal   !"#$%&'()*+,-./0123456789:;<=>?@
  -- 0xC0-0xDF: Normal   @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_
  -- 0xE0-0xFF: Normal   `abcdefghijklmnopqrstuvwxyz{|}~ `

  local screen = ""
  IterateTextScreen(
    function(byte, isAlt)
      if     byte < 0x20 then -- 0x00-0x1F: inverse upper
        byte = byte + 0x40
      elseif byte < 0x40 then -- 0x20-0x3F: inverse punctuation
        byte = byte
      elseif byte < 0x60 then -- 0x40-0x5F: flashing upper / MouseText
        if not isAlt then
          byte = byte
        else
          byte = 0x20 -- TODO: MouseText mapping
        end
      elseif byte < 0x80 then -- 0x60-0x7F: flashing punctuation / inverse lower
        if not isAlt then
          byte = byte - 0x40
        else
          byte = byte
        end
      elseif byte < 0xA0 then -- 0x80-0x9F: normal upper
        byte = byte - 0x40
      else -- 0xA0-0xFF: normal punctuation / upper / lower
        byte = byte - 0x80
      end
      screen = screen .. string.format("%c", byte)
    end,
    function()
      screen = screen .. "\n"
  end)
  return screen
end

function apple2.GrabInverseText()
  local str = ""
  IterateTextScreen(
    function(byte, isAlt)
      if     byte < 0x20 then -- 0x00-0x1F: inverse upper
        byte = byte + 0x40
      elseif byte < 0x40 then -- 0x20-0x3F: inverse punctuation
        byte = byte
      elseif byte < 0x60 then -- 0x40-0x5F: flashing upper / alt: MouseText
        return
      elseif byte < 0x80 then -- 0x60-0x7F: flashing punctuation / alt: inverse lower
        if not isAlt then
          return
        else
          byte = byte
        end
      elseif byte < 0xA0 then -- normal upper
        return
      else -- normal punctuation / upper / lower
        return
      end
      str = str .. string.format("%c", byte)
    end,
    function()
  end)
  return str
end

function apple2.SnapshotDHR()
  local bytes = {}
  for row = 0,apple2.SCREEN_HEIGHT-1 do
    for col = 0,apple2.SCREEN_COLUMNS-1 do
      bytes[row*apple2.SCREEN_COLUMNS+col] = apple2.GetDHRByte(row, col)
    end
  end
  return bytes
end

--------------------------------------------------

function apple2.IsCrashedToMonitor()
  local cpu = manager.machine.devices[":maincpu"]
  local sp = cpu.state.SP.value
  if sp == 0x1FE and apple2.ReadMemory(sp) == 0x4E and apple2.ReadMemory(sp+1) == 0xEB then
    return true
  else
    return false
  end
end

--------------------------------------------------

function apple2.WaitForBitsy(options)
  util.WaitFor(
    "Bitsy Bye",
    function()
      local text = apple2.GrabTextScreen()
      return text:match("BITSY") and text:match("^([^:]+):(/[^\n ]+)")
    end,
    options)
end

function apple2.GetBitsyLocation()
  local slot_drive, path = apple2.GrabTextScreen():match("^([^:]+):(/[^\n ]+)")
  return slot_drive, path
end

function apple2.BitsySelectSlotDrive(sd)
  local slot_drive, path = apple2.GetBitsyLocation()

  while path:match("^/.*/") do
    apple2.EscapeKey()
    emu.wait(5)
    slot_drive, path = apple2.GetBitsyLocation()
  end

  while slot_drive ~= sd do
    apple2.ControlKey("I") -- for Apple ][+ compat
    emu.wait(5)
    slot_drive, path = apple2.GetBitsyLocation()
  end
end

function apple2.BitsySelectVolume(name)
  local slot_drive, path = apple2.GetBitsyLocation()

  while path:match("^/.*/") do
    apple2.EscapeKey()
    emu.wait(5)
    slot_drive, path = apple2.GetBitsyLocation()
  end

  while path ~= "/" .. name do
    apple2.ControlKey("I") -- for Apple ][+ compat
    emu.wait(5)
    slot_drive, path = apple2.GetBitsyLocation()
  end
end

function apple2.BitsyInvokePath(path)
  local segments = {}
  for segment in path:gmatch("([^/]+)") do
    table.insert(segments, segment)
  end
  -- volume
  apple2.BitsySelectVolume(segments[1])
  -- directories
  for i = 2, #segments-1 do
    apple2.BitsyInvokeFile("/" .. segments[i])
  end
  -- file
  apple2.BitsyInvokeFile(segments[#segments])
end

function apple2.BitsyInvokeFile(name)
  while apple2.GrabInverseText() ~= name do
    apple2.RightArrowKey() -- for Apple ][+ compat
    emu.wait(1)
  end
  apple2.ReturnKey()
end

--------------------------------------------------

function apple2.WaitForBasicSystem(options)
  util.WaitFor(
    "Basic System",
    function()
      return apple2.GrabTextScreen():match("PRODOS BASIC")
    end,
    options)
end

--------------------------------------------------

function apple2.IsMono()
  --[[
    IIgs border is 72 (left/right) x 40 (top/bottom) ... but the edge
    pixels are blurred. So make the border black.
    TODO: Something less hacky than this
  ]]
  if manager.machine.system.name:match("^apple2gs") then
    apple2.WriteSSW("CLOCKCTL", 0)
    emu.wait(2/60)
  end

  emu.wait_next_frame()

  -- https://docs.mamedev.org/luascript/ref-core.html#video-manager
  local bytes = manager.machine.video:snapshot_pixels()
  local width, height = manager.machine.video:snapshot_size()

  function pixel(x,y)
    local a = string.byte(bytes, (x + y * width) * 4 + 0)
    local b = string.byte(bytes, (x + y * width) * 4 + 1)
    local g = string.byte(bytes, (x + y * width) * 4 + 2)
    local r = string.byte(bytes, (x + y * width) * 4 + 3)
    return r,g,b,a
  end

  local fr,fg,fb = pixel(0,0)

  for y = 0, height-1 do
    for x = 0, width-1 do
      local r,g,b,a = pixel(x,y)
      if r ~= g or r ~=b then
        return false
      end
    end
  end

  return true
end

function apple2.IsColor()
  return not apple2.IsMono()
end

--------------------------------------------------

return apple2
