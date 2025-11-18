
--[[============================================================

  Generic utilities for Apple II

  ============================================================]]--

local apple2 = {}

local machine = manager.machine
local ioport = machine.ioport
local kbd = machine.natkeyboard

--------------------------------------------------
-- System Abstractions
--------------------------------------------------

local mouse
local auxram

-- Defaults (Apple IIe, Apple IIc)
local keyboard = {
  ["Up Arrow"]    = { port = ":X6", field = "↑" },
  ["Left Arrow"]  = { port = ":X7", field = "←" },
  ["Right Arrow"] = { port = ":X7", field = "→" },
  ["Down Arrow"]  = { port = ":X7", field = "↓" },

  -- modifiers
  ["Control"]     = { port = ":keyb_special", field = "Control"     },
  ["Open Apple"]  = { port = ":keyb_special", field = "Open Apple"  },
  ["Solid Apple"] = { port = ":keyb_special", field = "Solid Apple" },

  -- Other
  ["Reset"] = { port = ":keyb_special", field = "RESET" },
}

if machine.system.name:match("^apple2e") then
  -- Apple IIe
  local auxdev, mousedev
  for devname,j in pairs(machine.devices) do
    if devname:match("^:aux:") then auxdev = devname end
    if devname:match("^:sl.:mouse$") then mousedev = devname end
  end

  if auxdev == nil then
    error("Failed to identify aux memory device")
  end
  if mousedev == nil then
    error("Failed to identify mouse device")
  end

  mouse = {
    x = { port = mousedev .. ":a2mse_x",      field = "Mouse X" },
    y = { port = mousedev .. ":a2mse_y",      field = "Mouse Y" },
    b = { port = mousedev .. ":a2mse_button", field = "Mouse Button" },
  }

  auxram = emu.item(machine.devices[auxdev].items["0/m_ram"])
elseif machine.system.name:match("^apple2c") then
  -- Apple IIc / Apple IIc Plus
  -- * has built-in mouse port
  -- * Aux memory is just exposed as RAM > 0xFFFF
  mouse = {
    x = { port = ":mse_x",      field = "Mouse X" },
    y = { port = ":mse_y",      field = "Mouse Y" },
    b = { port = ":mse_button", field = "Mouse Button" },
  }
elseif machine.system.name:match("^las.*128") then
  -- Laser 128
  -- * has built-in mouse port
  -- * Aux memory is just exposed as RAM > 0xFFFF
  mouse = {
    x = { port = ":mse_x",      field = "Mouse X" },
    y = { port = ":mse_y",      field = "Mouse Y" },
    b = { port = ":mse_button", field = "Mouse Button" },
  }
  keyboard["Open Apple"].field = "Open Triangle"
  keyboard["Solid Apple"].field = "Solid Triangle"

elseif machine.system.name:match("^apple2gs") then
  -- Apple IIgs
  -- * has built-in mouse port (ADB)
  -- * Aux memory is just exposed as RAM > 0xFFFF
  mouse = {
    x = { port = ":macadb:MOUSE1", field = "Mouse X" },
    y = { port = ":macadb:MOUSE2", field = "Mouse Y" },
    b = { port = ":macadb:MOUSE0", field = "Mouse Button 0" },
  }

  keyboard = {
    ["Up Arrow"]    = { port = ":macadb:KEY3", field = "Up Arrow"    },
    ["Left Arrow"]  = { port = ":macadb:KEY3", field = "Left Arrow"  },
    ["Right Arrow"] = { port = ":macadb:KEY3", field = "Right Arrow" },
    ["Down Arrow"]  = { port = ":macadb:KEY3", field = "Down Arrow"  },

    -- modifiers
    ["Control"]     = { port = ":macadb:KEY3", field = "Control" },
    ["Open Apple"]  = { port = ":macadb:KEY3", field = "Command" },
    ["Solid Apple"] = { port = ":macadb:KEY3", field = "Option"  },

    -- Other
    ["Reset"] = { port = ":macadb:KEY5", field = "Reset / Power" },
  }
else
  error("Unknown model: " .. machine.system.name)
end

--------------------------------------------------
-- General System Configuration
--------------------------------------------------

function get_port(port_name)
  local port = ioport.ports[port_name]
  if port == nil then
    error("No such port: " .. port_name)
  end
  return port
end

function get_field(port_name, field_name)
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
]]--



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
  ]]--


function SetVideoConfig(field_name, value, mask, shift)
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

-- CPU types - 1MHz, 4MHz Zip Chip
-- Bootup speed: Standard, 4MHz

--------------------------------------------------
-- Keyboard Input
--------------------------------------------------

-- Supports embedded codes e.g. {ENTER}
-- https://docs.mamedev.org/luascript/ref-input.html#natural-keyboard-manager
function apple2.Type(sequence)
  kbd:post_coded(sequence)
  while kbd.is_posting do
    emu.wait(0.1)
  end
end

function apple2.TypeSlow(sequence, pacing)
  for i=1,sequence:len() do
    kbd:post(sequence:sub(i,i))
    while kbd.is_posting do
      emu.wait(0.1)
    end
    emu.wait(pacing)
  end
end

function press(k)
  get_field(keyboard[k].port, keyboard[k].field):set_value(1)
end
function release(k)
  get_field(keyboard[k].port, keyboard[k].field):clear_value(1)
end
function press_and_release(k)
  press(k)
  emu.wait(2/60)
  release(k)
  emu.wait(2/60)
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

function apple2.ReturnKey()
  apple2.Type("{ENTER}")
end

function apple2.EscapeKey()
  apple2.Type("{ESC}")
end

function apple2.LeftArrowKey()
  press_and_release("Left Arrow")
end

function apple2.RightArrowKey()
  press_and_release("Right Arrow")
end

function apple2.UpArrowKey()
  press_and_release("Up Arrow")
end

function apple2.DownArrowKey()
  press_and_release("Down Arrow")
end

function apple2.PressOA()
  press("Open Apple")
end

function apple2.ReleaseOA()
  release("Open Apple")
end

function apple2.PressSA()
  press("Solid Apple")
end

function apple2.ReleaseSA()
  release("Solid Apple")
end

function apple2.PressControl()
  press("Control")
end

function apple2.ReleaseControl()
  release("Control")
end

function apple2.OAKey(key)
  apple2.PressOA()
  apple2.Type(key)
  apple2.ReleaseOA()
end

function apple2.SAKey(key)
  apple2.PressSA()
  apple2.Type(key)
  apple2.ReleaseSA()
end

function apple2.OASAKey(key)
  apple2.PressOA()
  apple2.PressSA()
  apple2.Type(key)
  apple2.ReleaseSA()
  apple2.ReleaseOA()
end

--------------------------------------------------
-- Mouse
--------------------------------------------------

function clamp(n, min, max)
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

function apple2.MoveMouse(x, y)
  --[[
    reading:

    # maxes out at 256
    ioport.ports[mouse.x.port]:read()
    ioport.ports[mouse.y.port]:read()

    # this is low level hardware... need to snoop at higher level
    # maybe screen holes?
    # but there's also scaling. Ugh.


  ]]--

  local MAX_DELTA = 127

  repeat
    local delta_x = clamp(x - mouse_x, -MAX_DELTA, MAX_DELTA)
    if delta_x ~= 0 then
      mouse_x = mouse_x + delta_x
      get_field(mouse.x.port, mouse.x.field):set_value(mouse_x)
      emu.wait(10/60)
      -- print(ioport.ports[mouse.x.port]:read())
    end
  until delta_x == 0
  emu.wait(0.5)

  repeat
    local delta_y = clamp(y - mouse_y, -MAX_DELTA, MAX_DELTA)
    if delta_y ~= 0 then
      mouse_y = mouse_y + delta_y
      get_field(mouse.y.port, mouse.y.field):set_value(mouse_y)
      emu.wait(10/60)
      -- print(ioport.ports[mouse.y.port]:read())
    end
  until delta_y == 0
  emu.wait(0.5)
end

--------------------------------------------------
-- Memory
--------------------------------------------------

-- This is a hardware view of memory
local ram = emu.item(machine.devices[":ram"].items["0/m_pointer"])

-- LCBANK1 is presented at $C000
-- LCBANK2 is presented at $D000

function apple2.ReadRAM(addr)
  -- Apple IIe exposes Aux RAM as a separate device
  if addr > 0x10000 and auxram ~= nil then
    return auxram:read(addr - 0x10000)
  else
    return ram:read(addr)
  end
end

function apple2.WriteRAM(addr, value)
  -- Apple IIe exposes Aux RAM as a separate device
  if addr > 0x10000 and auxram ~= nil then
    auxram:write(addr - 0x10000, value)
  else
    ram:write(addr, value)
  end
end

--------------------------------------------------
-- Machine State
--------------------------------------------------

-- This is a software view of memory; i.e. banking matters!

-- Most useful for reading/writing softswitches
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]

-- TODO: Build an API around this
function apple2.DumpReadableStates()
  local ssw = {
    RDBNK2    = 0xC011,
    RDLCRAM   = 0xC012,
    RDRAMRD   = 0xC013,
    RDRAMWRT  = 0xC014,
    RDCXROM   = 0xC015,
    RDALTZP   = 0xC016,
    RDC3ROM   = 0XC017,
    RD80STORE = 0xC018,
    RDVBL     = 0xC019,
    RDTEXT    = 0xC01A,
    RDMIXED   = 0xC01B,
    RDPAGE2   = 0xC01C,
    RDHIRES   = 0xC01D,
    RDALTCHAR = 0xC01E,
    RD80VID   = 0xC01F,
  }
  function IsHi(ident)
    if mem:read_u8(ssw[ident]) > 127 then
      return "true"
    else
      return "false"
    end
  end

  print("text?   " .. IsHi("RDTEXT"))
  print("mixed?  " .. IsHi("RDMIXED"))
  print("page2?  " .. IsHi("RDPAGE2"))
  print("hires?  " .. IsHi("RDHIRES"))
  print("altchr? " .. IsHi("RDALTCHR"))
  print("80vid?  " .. IsHi("RD80VID"))
end

--------------------------------------------------

return apple2
