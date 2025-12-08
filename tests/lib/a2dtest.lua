--[[============================================================

  A2D-specific Test Utilities

  ============================================================]]--

local a2dtest = {}

local apple2 = require("apple2")
local a2d = require("a2d")
local mgtk = require("mgtk")
local test = require("test")

--------------------------------------------------
-- Graphics Screen Helpers
--------------------------------------------------

-- TODO: Unify these

function a2dtest.CompareDHR(dhr_expected, dhr_actual, log)
  for row = 0,apple2.SCREEN_HEIGHT-1 do
    for col = 0,apple2.SCREEN_COLUMNS-1 do
      local expected = dhr_expected[row*apple2.SCREEN_COLUMNS+col]
      local actual = dhr_actual[row*apple2.SCREEN_COLUMNS+col]
      if actual ~= expected then
        if log then
          print(string.format("difference at row %d col %d - %02X vs. %02X", row, col, actual, expected))
        end
        return false
      end
    end
  end
  return true
end

local function RepaintFraction(dhr_expected, dhr_actual)
  local count = 0
  for row = 0,apple2.SCREEN_HEIGHT-1 do
    for col = 0,apple2.SCREEN_COLUMNS-1 do
      local before = dhr_expected[row*apple2.SCREEN_COLUMNS+col]
      local after = dhr_actual[row*apple2.SCREEN_COLUMNS+col]
      if before ~= after then
        count = count + 1
      end
    end
  end
  return count / (apple2.SCREEN_HEIGHT*apple2.SCREEN_COLUMNS)
end

--------------------------------------------------

-- These functions internally "censor" the menu bar clock in the
-- snapshots, to avoid false positives. The actual DHR screen is left
-- untouched, however.

-- Explicit "take snapshot" ... "compare with snapshot" functions
function a2dtest.SnapshotDHRWithoutClock()
  local dhr = apple2.SnapshotDHR()
  for row = 0,11 do
    for col = 65,79 do
      dhr[row*apple2.SCREEN_COLUMNS+col] = 0x00
    end
  end
  return dhr
end
function a2dtest.ExpectUnchangedExceptClock(dhr, message)
  local new = a2dtest.SnapshotDHRWithoutClock()
  test.Expect(a2dtest.CompareDHR(dhr, new, true), message, {snap=true}, 1)
end

-- The above, wrapped into a helper that takes a callback
function a2dtest.ExpectNothingChanged(func)
  local dhr = a2dtest.SnapshotDHRWithoutClock()
  func()
  local new = a2dtest.SnapshotDHRWithoutClock()
  test.Expect(a2dtest.CompareDHR(dhr, new, true), "nothing should have changed", {snap=true}, 1)
end

--------------------------------------------------

local darkness_bytes = {
  {0x00, 0x00, 0x00, 0x00},
  {0x08, 0x11, 0x22, 0x44},
  {0x00, 0x00, 0x00, 0x00},
  {0x22, 0x44, 0x08, 0x11},
}

local darkness_ref = {}
for row = 0,apple2.SCREEN_HEIGHT-1 do
  for col = 0,apple2.SCREEN_COLUMNS-1 do
    darkness_ref[row*apple2.SCREEN_COLUMNS+col] = darkness_bytes[row % 4 + 1][col % 4 + 1]
  end
end

function a2dtest.DHRDarkness()
  for row = 0,apple2.SCREEN_HEIGHT-1 do
    for col = 0,apple2.SCREEN_COLUMNS-1 do
      local byte = darkness_bytes[row % 4 + 1][col % 4 + 1]
      apple2.SetDHRByte(row, col, byte)
    end
  end
end

--------------------------------------------------

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
  a2dtest.DHRDarkness()
  func()
  local fraction = RepaintFraction(darkness_ref, apple2.SnapshotDHR())
  test.Expect(min <= fraction and fraction <= max,
              string.format("%s - diff about %d%%", message, math.floor(fraction * 100)),
              {snap=true}, level and level+1 or 1)
end

function a2dtest.ExpectMenuNotHighlighted()
  for col = 0,apple2.SCREEN_COLUMNS-1 do
    test.ExpectEquals(apple2.GetDHRByte(0, col), 0x7F, "Menu should not be highlighted", 1)
  end
end

function a2dtest.ExpectClockVisible()
  test.ExpectNotEquals(apple2.GetDHRByte(4, 78), 0x7F, "Clock should be visible", 1)
end

--------------------------------------------------
-- MGTK-based helpers
--------------------------------------------------

local bank_offset = 0x10000

function a2dtest.SetBankOffsetForDeskTopModule()
  bank_offset = 0x10000
end
function a2dtest.SetBankOffsetForDiskCopyModule()
  bank_offset = 0x10000
end
function a2dtest.SetBankOffsetForSelectorModule()
  bank_offset = 0x00000
end

function a2dtest.GetFrontWindowDragCoords()
  local window_id = mgtk.FrontWindow()
  if window_id == 0 then
    error("No front window!", 2)
  end
  local rect = mgtk.GetWinFrameRect(window_id)
  local x = math.floor((rect[1] + rect[3]) / 2)
  local y = rect[2] + 4
  return x,y
end

function a2dtest.GetFrontWindowCloseBoxCoords()
  local window_id = mgtk.FrontWindow()
  if window_id == 0 then
    error("No front window!", 2)
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
    error("No front window!", 2)
  end
  return mgtk.GetWindowName(window_id, bank_offset)
end

-- returns x,y,width,height
function a2dtest.GetFrontWindowContentRect()
  local winfo = bank_offset + mgtk.GetWinPtr(mgtk.FrontWindow())
  local port = winfo + 20
  local vx,vy = ram_s16(port + 0), ram_s16(port + 2)
  local x1,y1 = ram_s16(port + 8), ram_s16(port + 10)
  local x2,y2 = ram_s16(port + 12), ram_s16(port + 14)
  return vx, vy, (x2-x1), (y2-y1)
end

function a2dtest.GetFrontWindowRightScrollArrowCoords()
  local x,y,w,h = a2dtest.GetFrontWindowContentRect()
  return x + w - 10, y + h + 5
end

function a2dtest.GetFrontWindowUpScrollArrowCoords()
  local x,y,w,h = a2dtest.GetFrontWindowContentRect()
  return x + w + 10, y + 5
end

--------------------------------------------------

-- This scans for the left side of the alert bitmap at expected screen address
function a2dtest.IsAlertShowing()
  local bytes = {0x7F,0x7F,0x7F,0x3F,0x00,0x00,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x4F,0x0F,0x3F,0x4F,0x0F,0x3F,0x4F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x7F,0x0F,0x3F,0x1F,0x00,0x3F,0x7F,0x01,0x3F,0x7F,0x01,0x3F,0x07,0x70,0x3F,0x7F,0x01,0x3F,0x7F,0x01,0x3F,0x00,0x00,0x7F,0x7F,0x7F}
  local index = 1
  for row = 75,100 do
    for col = 12,14 do
      if bytes[index] ~= apple2.GetDHRByte(row,col) then
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
