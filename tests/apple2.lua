
--[[============================================================

  Generic utilities for Apple II

  ============================================================]]--

local apple2 = {}

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

function get_device(pattern)
  for name,dev in pairs(machine.devices) do
    if name:match(pattern) then return dev end
  end
  error("Failed to find device " .. pattern)
end


local scan_for_mouse = false
if machine.system.name:match("^apple2e") then
  -- Apple IIe
  -- * mouse card required
  -- * many possible aux memory devices
  scan_for_mouse = true
  auxram = emu.item(get_device("^:aux:").items["0/m_ram"])

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
    ["Delete"]      = { port = ":macadb:KEY7", field = "Delete" },
    ["Escape"]      = { port = ":macadb:KEY3", field = "Esc" },

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
else
  error("Unknown model: " .. machine.system.name)
end

if scan_for_mouse then
  local mousedev = get_device("^:sl.:mouse$").tag
  -- TODO: Allow operation without a mouse
  mouse = {
    x = { port = mousedev .. ":a2mse_x",      field = "Mouse X" },
    y = { port = mousedev .. ":a2mse_y",      field = "Mouse Y" },
    b = { port = mousedev .. ":a2mse_button", field = "Mouse Button" },
  }
end

--------------------------------------------------
-- General System Configuration
--------------------------------------------------

function get_port(port_name)
  local port = machine.ioport.ports[port_name]
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

--------------------------------------------------
-- Keyboard Input
--------------------------------------------------

local kbd = machine.natkeyboard

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

function wait_for_kbd_strobe_clear()
  while apple2.ReadSSW("KBD") > 127 do
    emu.wait(1/60)
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
  press_and_release("Return")
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
    machine.ioport.ports[mouse.x.port]:read()
    machine.ioport.ports[mouse.y.port]:read()

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
      -- print(machine.ioport.ports[mouse.x.port]:read())
    end
  until delta_x == 0
  emu.wait(0.5)

  repeat
    local delta_y = clamp(y - mouse_y, -MAX_DELTA, MAX_DELTA)
    if delta_y ~= 0 then
      mouse_y = mouse_y + delta_y
      get_field(mouse.y.port, mouse.y.field):set_value(mouse_y)
      emu.wait(10/60)
      -- print(machine.ioport.ports[mouse.y.port]:read())
    end
  until delta_y == 0
  emu.wait(0.5)
end

--------------------------------------------------
-- Memory
--------------------------------------------------

-- This is a hardware view of memory
-- * It does not reflect bank states; aux starts at is 0x10000
-- * LCBANK1 is presented at $C000 (!!!)
-- * LCBANK2 is presented at $D000
local ram = emu.item(machine.devices[":ram"].items["0/m_pointer"])

function apple2.ReadRAMDevice(addr)
  -- Apple IIe exposes Aux RAM as a separate device
  if addr > 0x10000 and auxram ~= nil then
    return auxram:read(addr - 0x10000)
  else
    return ram:read(addr)
  end
end

function apple2.WriteRAMDevice(addr, value)
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

function apple2.GrabTextScreen()
  local is80 = apple2.ReadSSW("RD80VID") > 127
  local screen = ""
  for row = 0,23 do
    local base = 0x400 + (row - math.floor(row/8) * 8) * 0x80 + 40 * math.floor(row/8)
    for col = 0,39 do
      if is80 then
        byte = apple2.ReadRAMDevice(0x10000 + base + col)
        byte = byte & 0x7F
        screen = screen .. string.format("%c", byte)
      end
      byte = apple2.ReadRAMDevice(base + col)
      byte = byte & 0x7F
      screen = screen .. string.format("%c", byte)
    end
    screen = screen .. "\n"
  end
  return screen
end

--------------------------------------------------

return apple2
