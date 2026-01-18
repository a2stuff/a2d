--[[============================================================

  MouseGraphics ToolKit interaction via automation hook

  ============================================================]]

local mgtk = {}

local apple2 = require("apple2")

------------------------------------------------------------
-- Configuration
------------------------------------------------------------

local bank_offset
local top_window

function mgtk.Configure(offset, current_window)
  bank_offset = offset
  top_window = current_window
end

------------------------------------------------------------
-- Enumerations
------------------------------------------------------------

mgtk.area = {
        desktop         = 0,
        menubar         = 1,
        content         = 2,
        dragbar         = 3,
        grow_box        = 4,
        close_box       = 5,
}

mgtk.ctl = {
        not_a_control           = 0,
        vertical_scroll_bar     = 1,
        horizontal_scroll_bar   = 2,
        dead_zone               = 3,
}

mgtk.part = {
        inactive        = 0,
        up_arrow        = 1,
        left_arrow      = 1,
        down_arrow      = 2,
        right_arrow     = 2,
        page_up         = 3,
        page_left       = 3,
        page_down       = 4,
        page_right      = 4,
        thumb           = 5,
}

mgtk.scroll = {
        option_none      = 0,
        option_present   = 1 << 7,
        option_thumb     = 1 << 6,
        option_active    = 1 << 0,
}

------------------------------------------------------------
-- Wrapped Calls
------------------------------------------------------------

-- Returns addr of Winfo (without bank info)
function mgtk.GetWinPtr(window_id)
  local ram = apple2.GetRAMDeviceProxy()
  local ptr = ram.read_u16(bank_offset + top_window)
  while ptr ~= 0 do
    local id = ram.read_u8(bank_offset + ptr + 0)
    if id == window_id then
      return ptr
    end
    ptr = ram.read_u16(bank_offset + ptr + 56)
  end
  error(string.format("%s: No window for id %d", debug.getinfo(1,"n").name, window_id))
end

-- Returns window_id
function mgtk.FrontWindow()
  local ram = apple2.GetRAMDeviceProxy()
  local ptr = ram.read_u16(bank_offset + top_window)
  if ptr == 0 then
    return 0
  end
  local id = ram.read_u8(bank_offset + ptr + 0)
  return id
end

------------------------------------------------------------
-- Higher Level Helpers
------------------------------------------------------------

function mgtk.GetWindowName(window_id)
  local ram = apple2.GetRAMDeviceProxy()
  local winfo = bank_offset + mgtk.GetWinPtr(window_id)
  local addr = ram.read_u16(winfo + 2)
  if addr == 0 then
    return nil
  end
  return apple2.GetPascalString(addr + bank_offset)
end

function mgtk.GetWindowContentRect(window_id)
  local ram = apple2.GetRAMDeviceProxy()
  local winfo = bank_offset + mgtk.GetWinPtr(window_id)
  local port = winfo + 20
  local vx,vy = ram.read_s16(port + 0), ram.read_s16(port + 2)
  local x1,y1 = ram.read_s16(port + 8), ram.read_s16(port + 10)
  local x2,y2 = ram.read_s16(port + 12), ram.read_s16(port + 14)
  return {vx, vy, (x2-x1), (y2-y1)}
end

------------------------------------------------------------

return mgtk
