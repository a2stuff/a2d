--[[============================================================

  MouseGraphics ToolKit interaction via automation hook

  ============================================================]]--

local mgtk = {}

local apple2 = require("apple2")

------------------------------------------------------------
-- Automation Hook
------------------------------------------------------------

-- Example 1:
--   result = MGTKCall(InRect, { x1lo, x1hi, y1lo, y1hi, x2lo, x2hi, y2lo, y2hi})
-- Example 2:
--   params = {0}
--   MGTKCall(FrontWindow, params)
--   return params[1]
-- Example 3:
--   MGTKCall(GetWinPtr, {win_id, 0, 0}, function(result, params)
--     win_ptr = params[2] | (params[3] << 8)
--     ... use ptr here ...
--   end)
-- Use opt_callback for memory access other than params
function MGTKCall(call, params, opt_callback)

  -- Give MGTK the unlock sequence

  apple2.PressOA()
  apple2.PressSA()
  apple2.ControlKey('@')
  apple2.ReleaseSA()
  apple2.ReleaseOA()

  -- prepare call

  local zp_call, zp_params, params_addr = 0x00, 0x01, 0x03

  local saved_bytes = {
    apple2.ReadMemory(zp_call),
    apple2.ReadMemory(zp_params),
    apple2.ReadMemory(zp_params+1),
  }

  apple2.WriteMemory(zp_call, call)
  if #params == 0 then
    apple2.WriteMemory(zp_params, 0)
    apple2.WriteMemory(zp_params+1, 0)
  else
    apple2.WriteMemory(zp_params, (params_addr >> 0) & 0xFF)
    apple2.WriteMemory(zp_params+1, (params_addr >> 8) & 0xFF)
    for i = 0, #params-1 do
      saved_bytes[3+i] =  apple2.ReadMemory(params_addr + i)
      apple2.WriteMemory(params_addr + i, params[i+1])
    end
  end

  -- tell MGTK to execute call

  apple2.SpaceKey() -- execute call

  -- extract results and restore memory

  local result = apple2.ReadMemory(0x00)
  apple2.WriteMemory(zp_call, saved_bytes[1])
  apple2.WriteMemory(zp_params, saved_bytes[2])
  apple2.WriteMemory(zp_params+1, saved_bytes[3])

  if #params > 0 then
    for i = 0, #params-1 do
      params[i+1] = apple2.ReadMemory(params_addr + i)
      apple2.WriteMemory(params_addr + i, saved_bytes[3+i])
    end
  end

  if opt_callback then
    opt_callback(result, params)
  end

  -- tell MGTK resume normal execution

  apple2.SpaceKey()

  return result
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

------------------------------------------------------------
-- Wrapped Calls
------------------------------------------------------------

-- Helpers for reading 8 and 16-bit values from out params
function u8(params, offset)
  return params[offset+1]
end
function u16(params, offset)
  return u8(params, offset) | (u8(params, offset+1) << 8)
end
function s16(params, offset)
  local v = u16(params, offset)
  if v & 0x8000 ~= 0 then
    return 0x10000 - v
  else
    return v
  end
end

-- Returns addr of Winfo (without bank info)
function mgtk.GetWinPtr(window_id)
  local params = {
    window_id,
    0,0
  }
  local result = MGTKCall(0x3B, params)
  if result ~= 0 then
    error(string.format("Unexpected result from %s: $%02X", debug.getinfo(1,"n").name, result))
  end
  return u16(params, 1)
end

-- Returns window_id, which_area
function mgtk.FindWindow(x, y)
  local params = {
    (x >> 0) & 0xFF,
    (x >> 8) & 0xFF,
    (y >> 0) & 0xFF,
    (y >> 8) & 0xFF,
    0, 0
  }
  local result = MGTKCall(0x40, params)
  if result ~= 0 then
    error(string.format("Unexpected result from %s: $%02X", debug.getinfo(1,"n").name, result))
  end
  return params[6], params[5]
end

-- Returns window_id
function mgtk.FrontWindow()
  local params = {0}
  local result = MGTKCall(0x41, params)
  if result ~= 0 then
    error(string.format("Unexpected result from %s: $%02X", debug.getinfo(1,"n").name, result))
  end
  return u8(params, 0)
end

-- Returns {x1, x2, y1, y2}
function mgtk.GetWinFrameRect(window_id)
  local params = {
    window_id,
    0,0, 0,0, 0,0, 0,0
  }
  local result = MGTKCall(0x51, params)
  if result ~= 0 then
    error(string.format("Unexpected result from %s: $%02X", debug.getinfo(1,"n").name, result))
  end
  return {
    s16(params, 1), s16(params, 3),
    s16(params, 5), s16(params, 7),
  }
end


-- Returns which_ctl, which_part
function mgtk.FindControl(x, y)
  local params = {
    (x >> 0) & 0xFF,
    (x >> 8) & 0xFF,
    (y >> 0) & 0xFF,
    (y >> 8) & 0xFF,
    0, 0
  }
  local result = MGTKCall(0x48, params)
  if result ~= 0 then
    error(string.format("Unexpected result from %s: $%02X", debug.getinfo(1,"n").name, result))
  end
  return params[5], params[6]
end

-- Returns which_ctl, which_part
function mgtk.FindControlEx(x, y, window_id)
  local params = {
    (x >> 0) & 0xFF,
    (x >> 8) & 0xFF,
    (y >> 0) & 0xFF,
    (y >> 8) & 0xFF,
    0, 0,
    window_id
  }
  local result = MGTKCall(0x53, params)
  if result ~= 0 then
    error(string.format("Unexpected result from %s: $%02X", debug.getinfo(1,"n").name, result))
  end
  return params[5], params[6]
end

------------------------------------------------------------
-- Higher Level Helpers
------------------------------------------------------------

function ram_u8(addr)
  return apple2.ReadRAMDevice(addr)
end

function ram_u16(addr)
  return ram_u8(addr) | (ram_u8(addr+1) << 8)
end

function ram_s16(addr)
  local v = ram_u16(addr)
  if v & 0x8000 == 0 then
    return v
  else
    return 0x10000 - v
  end
end

function mgtk.GetWindowName(window_id, bank_offset)
  local winfo = bank_offset + mgtk.GetWinPtr(window_id)
  local addr = apple2.ReadRAMDevice(winfo + 2) | (apple2.ReadRAMDevice(winfo + 3) << 8)
  return apple2.GetPascalString(addr + bank_offset)
end

function mgtk.GetWindowContentRect(window_id, bank_offset)
  local winfo = bank_offset + mgtk.GetWinPtr(window_id)
  local port = winfo + 20
  local vx,vy = ram_s16(port + 0), ram_s16(port + 2)
  local x1,y1 = ram_s16(port + 8), ram_s16(port + 10)
  local x2,y2 = ram_s16(port + 12), ram_s16(port + 14)
  return {vx, vy, (x2-x1), (y2-y1)}
end

------------------------------------------------------------

return mgtk
