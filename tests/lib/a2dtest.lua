--[[============================================================

  A2D-specific Test Utilities

  ============================================================]]--

local a2dtest = {}

local apple2 = require("apple2")
local a2d = require("a2d")
local mgtk = require("mgtk")
local test = require("test")

--------------------------------------------------

local function EraseClock()
  for row = 0,11 do
    for col = 65,79 do
      apple2.SetDoubleHiresByte(row, col, 0x00)
    end
  end
  emu.wait_next_frame()
end

function a2dtest.ExpectNothingHappened(func)
  EraseClock()
  local bytes = apple2.SnapshotDHR()
  func()
  EraseClock()
  test.Expect(apple2.CompareDHR(bytes), "nothing should have changed", {snap=true}, 1)
end

--------------------------------------------------

local function RepaintFraction()
  local count = 0
  for row = 0,191 do
    for col = 0,79 do
      if not apple2.ValidateDHRDarkness(row, col) then
        count = count + 1
      end
    end
  end
  return count / (192*80)
end

function a2dtest.ExpectFullRepaint(func)
  a2dtest.ExpectRepaintFraction(0.9, 1.0, func, "should be full repaint", 1)
end

function a2dtest.ExpectMinimalRepaint(func)
  a2dtest.ExpectRepaintFraction(0, 0.5, func, "should be minimal repaint", 1)
end

function a2dtest.ExpectNoRepaint(func)
  a2dtest.ExpectRepaintFraction(0, 0.01, func, "should not have repainted", 1)
end

function a2dtest.ExpectRepaintFraction(min, max, func, message, level)
  apple2.DHRDarkness()
  func()
  local fraction = RepaintFraction()
  test.Expect(min <= fraction and fraction <= max,
              string.format("%s - diff about %d%%", message, math.floor(fraction * 100)),
              {snap=true}, level and level+1 or 1)
end

--------------------------------------------------
-- MGTK-based helpers
--------------------------------------------------

-- TODO: This changes if calling from DeskTop vs. Selector
local bank_offset = 0x10000

function a2dtest.GetFrontWindowDragCoords()
  local window_id = mgtk.FrontWindow()
  if window_id == 0 then
    error("No front window!")
  end
  local rect = mgtk.GetWinFrameRect(window_id)
  local x = math.floor((rect[1] + rect[3]) / 2)
  local y = rect[2] + 4
  return x,y
end

function a2dtest.GetFrontWindowCloseBoxCoords()
  local window_id = mgtk.FrontWindow()
  if window_id == 0 then
    error("No front window!")
  end
  local rect = mgtk.GetWinFrameRect(window_id)
  local x = rect[1] + 20
  local y = rect[2] + 4
  return x,y
end

function a2dtest.GetWindowCount()
  local count = 0
  local front = mgtk.FrontWindow()
  if front == 0 then
    return 0
  end
  local winfo = mgtk.GetWinPtr(front)
  repeat
    count = count + 1
    winfo = winfo + bank_offset
    winfo = apple2.ReadRAMDevice(winfo + 56) | (apple2.ReadRAMDevice(winfo + 57) << 8)
  until winfo == 0
  return count
end

function a2dtest.GetFrontWindowTitle()
  local window_id = mgtk.FrontWindow()
  if window_id == 0 then
    error("No front window!")
  end
  return mgtk.GetWindowName(window_id, bank_offset)
end

--------------------------------------------------

-- This scans for the left side of the alert bitmap at expected screen address
function a2dtest.IsAlertShowing()
  local bytes = {0x7F,0x7F,0x7F,0x3F,0x00,0x00,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x4F,0x0F,0x3F,0x4F,0x0F,0x3F,0x4F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x1F,0x00,0x3F,0x7F,0x01,0x3F,0x7F,0x01,0x3F,0x07,0x70,0x3F,0x7F,0x01,0x3F,0x7F,0x01,0x3F,0x00,0x00,0x7F,0x7F,0x7F}
  local index = 1
  for row = 75,100 do
    for col = 12,14 do
      if bytes[index] ~= apple2.GetDoubleHiresByte(row,col) then
        return false
      end
      index = index + 1
    end
  end
  return true
end

function a2dtest.ExpectAlertShowing()
  test.Expect(a2dtest.IsAlertShowing(), "an alert should be showing", nil, 1)
end

function a2dtest.ExpectAlertNotShowing()
  test.Expect(not a2dtest.IsAlertShowing(), "an alert should not be showing", nil, 1)
end

--------------------------------------------------

return a2dtest
