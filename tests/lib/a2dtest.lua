--[[============================================================

  A2D-specific Test Utilities

  ============================================================]]

local a2dtest = {}

local util = require("util")
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
    test.ExpectEquals(apple2.GetDHRByte(0, col), 0x7F, "Menu should not be highlighted", {}, 1)
  end
end

function a2dtest.ExpectClockVisible()
  test.ExpectNotEquals(apple2.GetDHRByte(4, 78), 0x7F, "Clock should be visible", {}, 1)
end

--------------------------------------------------
-- MGTK-based helpers
--------------------------------------------------

local bank_offset

local DESKTOP_SYMBOLS = {}
for pair in emu.subst_env("$DESKTOP_SYMBOLS"):gmatch("([^ ]+)") do
  local k,v = pair:match("^(.+)=(.+)$")
  DESKTOP_SYMBOLS[k] = tonumber(v, 16)
end
local SELECTOR_SYMBOLS = {}
for pair in emu.subst_env("$SELECTOR_SYMBOLS"):gmatch("([^ ]+)") do
  local k,v = pair:match("^(.+)=(.+)$")
  SELECTOR_SYMBOLS[k] = tonumber(v, 16)
end

function a2dtest.ConfigureForDeskTop()
  bank_offset = 0x10000
  mgtk.Configure(bank_offset, DESKTOP_SYMBOLS["current_window"])
end
a2dtest.ConfigureForDiskCopy = a2dtest.ConfigureForDeskTop

function a2dtest.ConfigureForSelector()
  bank_offset = 0x00000
  mgtk.Configure(bank_offset, SELECTOR_SYMBOLS["current_window"])
end

local function ram_u8(addr)
  return apple2.GetRAMDeviceProxy().read_u8(addr)
end

local function ram_u16(addr)
  return apple2.GetRAMDeviceProxy().read_u16(addr)
end

local function ram_s16(addr)
  return apple2.GetRAMDeviceProxy().read_s16(addr)
end

function a2dtest.GetFrontWindowID()
  local window_id = mgtk.FrontWindow()
  if window_id == 0 then
    error("No front window!", 2)
  end
  return window_id
end

function a2dtest.GetNextWindowID(window_id)
  local winfo = mgtk.GetWinPtr(window_id) + bank_offset
  local next = ram_u16(winfo + 56)
  if next == 0 then
    return 0
  end
  return ram_u8(next + bank_offset)
end

function a2dtest.GetFrontWindowDragCoords()
  return a2dtest.GetWindowDragCoords(a2dtest.GetFrontWindowID())
end

function a2dtest.GetWindowDragCoords(window_id)
  local x, y, w, h = a2dtest.GetWindowContentRect(window_id)
  return x + w / 2, y - 5
end

function a2dtest.GetFrontWindowCloseBoxCoords()
  local window_id = mgtk.FrontWindow()
  if window_id == 0 then
    error("No front window!", 2)
  end
  local x, y, w, h = a2dtest.GetFrontWindowContentRect()
  return x + 20, y - 8
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
    winfo = ram_u16(winfo + 56)
  until winfo == 0
  return count
end

function a2dtest.GetFrontWindowTitle()
  return a2dtest.GetWindowTitle(a2dtest.GetFrontWindowID())
end
function a2dtest.GetWindowTitle(window_id)
  return mgtk.GetWindowName(window_id)
end

-- returns x,y,width,height
function a2dtest.GetFrontWindowContentRect()
  return a2dtest.GetWindowContentRect(a2dtest.GetFrontWindowID())
end
function a2dtest.GetWindowContentRect(window_id)
  local winfo = bank_offset + mgtk.GetWinPtr(window_id)
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

function a2dtest.GetFrontWindowDownScrollArrowCoords()
  local x,y,w,h = a2dtest.GetFrontWindowContentRect()
  return x + w + 10, y + h - 5
end

function a2dtest.GetFrontWindowScrollOptions()
  local winfo = bank_offset + mgtk.GetWinPtr(mgtk.FrontWindow())
  local hscroll = ram_u8(winfo + 4)
  local vscroll = ram_u8(winfo + 5)
  return hscroll, vscroll
end

function a2dtest.GetFrontWindowScrollPos()
  local winfo = bank_offset + mgtk.GetWinPtr(mgtk.FrontWindow())
  local hthumbpos = ram_u8(winfo + 7)
  local vthumbpos = ram_u8(winfo + 9)
  return hthumbpos, vthumbpos
end

function a2dtest.GetFrontWindowScrollMax()
  local winfo = bank_offset + mgtk.GetWinPtr(mgtk.FrontWindow())
  local hthumbmax = ram_u8(winfo + 6)
  local vthumbmax = ram_u8(winfo + 8)
  return hthumbmax, vthumbmax
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

function a2dtest.ExpectAlertNotShowing()
  test.Expect(not a2dtest.IsAlertShowing(), "an alert should not be showing", nil, 1)
end

function a2dtest.WaitForAlert(options)
  util.WaitFor("alert", a2dtest.IsAlertShowing, options)
  emu.wait(0.5) -- let the alert finish drawing
  if options and (options.match or options.imatch) then
    local ocr = a2dtest.OCRScreen({x1=130, y1=75, x2=470, y2=100})
    if options.imatch then
      ocr = ocr:upper()
      options.match = options.imatch:upper()
    end
    test.ExpectMatch(ocr, options.match, "alert should match " .. options.match, {snap=true}, 1)
  end
end

--------------------------------------------------

function a2dtest.ExpectNotHanging()
  local dhr = a2dtest.SnapshotDHRWithoutClock()
  a2d.OpenMenu(a2d.APPLE_MENU)
  local new = a2dtest.SnapshotDHRWithoutClock()
  test.Expect(not a2dtest.CompareDHR(dhr, new), "about dialog should have shown", {snap=true}, 1)
  apple2.EscapeKey()
  a2d.WaitForRepaint()
  local new2 = a2dtest.SnapshotDHRWithoutClock()
  test.Expect(a2dtest.CompareDHR(dhr, new2), "about dialog should have closed", {snap=true}, 1)
end

--------------------------------------------------

function a2dtest.MultiSnap(frames, opt_title)
  local last = nil
  for i=1,frames/2 do
    local dhr = a2dtest.SnapshotDHRWithoutClock()
    if not last or not a2dtest.CompareDHR(last, dhr) then
      test.Snap(opt_title)
      last = dhr
    end
    emu.wait(2/60)
  end
end

--------------------------------------------------

function a2dtest.GetSelectedIconName()
  local icons = a2d.GetSelectedIcons()
  if #icons == 0 then
    error("Selection is empty", 2)
  end
  local icon = icons[1]
  return icon.name
end

function a2dtest.GetSelectedIconCoords()
  local icons = a2d.GetSelectedIcons()
  if #icons == 0 then
    error("Selection is empty", 2)
  end
  local icon = icons[1]
  return icon.x+10, icon.y+5
end

--------------------------------------------------

--[[
  Scans the screen for font glyphs and return a string reprentation of
  what was found. The representation is a single string with multiple
  "\n"-delimited lines. Characters that were identified on the same
  row of the screen will appear on a single line. Runs of spaces are
  collapsed, and blank lines are removed.

  False positives are expected (e.g. vertical bars, underscores, etc)
  but false negatives should not occur, apart from homoglyphs, which
  are filtered out by the table generator, and overlapping/clipping.

  Call with {invert=true} to look for white-on-black text e.g. a
  selected menu item, list box item, flashing button, etc.

  NOTE: The function is relatively slow, taking 1/4 second on an
  example machine.
]]
local ocr_table = require("ocr_table")

-- callback is invoked with (run, x, y)
function a2dtest.OCRIterate(callback, options)
  if options == nil then options = {} end

  -- Grab screen pixels
  local dhr = apple2.SnapshotDHR()

  local font_height = ocr_table.height
  local font_width = ocr_table.width
  local mask = (1 << font_height) - 1

  if options.x1 == nil then options.x1 = 0 end
  if options.y1 == nil then options.y1 = 0 end
  if options.x2 == nil then options.x2 = apple2.SCREEN_WIDTH-1 end
  if options.y2 == nil then options.y2 = apple2.SCREEN_HEIGHT-1 end

  -- Walk over entire screen
  for y = options.y1, options.y2-font_height do
    -- Process a stripe `font_height` pixels tall, convert to numbers
    local numbers = {}
    for i = 0, apple2.SCREEN_WIDTH-1 do
      numbers[i] = 0
    end
    for col = 0, apple2.SCREEN_COLUMNS-1 do
      for bit = 0, 6 do
        local n = 0
        for r = 0, font_height-1 do
          local byte = dhr[(y + r) * apple2.SCREEN_COLUMNS + col]
          local b = ((byte >> bit) & 1) ~ 1
          n = (n << 1) | b
        end
        numbers[col * 7 + bit] = n
      end
    end

    -- Iterate over stripe
    local x = options.x1
    local run, run_x = "", x
    while x < options.x2 do
      -- Try each character width, longest to shortest
      for w = font_width, 1, -1 do
        if x + w > options.x2 then
          goto try_shorter
        end
        -- Compute hash keys (normal and inverted)
        local key1, key2 = "", ""
        for c = x, x+w-1 do
          if not options.invert then
            key1 = key1 .. utf8.char(numbers[c])
          else
            key2 = key2 .. utf8.char(numbers[c] ~ mask)
          end
        end
        -- Match?
        local char = ocr_table[key1] or ocr_table[key2]
        if char then
          run = run .. char
          x = x + w
          goto got_a_hit
        end
        ::try_shorter::
      end

      -- miss; if end of run, emit
      if run ~= "" then
        callback(run, run_x, y)
        run = ""
      end
      x = x + 1
      run_x = x

      ::got_a_hit::
    end

    if not run:match("^ *+$") then
      callback(run, run_x, y)
    end
  end
end

function a2dtest.OCRScreen(options)
  if options == nil then options = {} end

  local str = ""
  local line = ""
  local last_y = nil

  function finish_line()
    -- Collapse multiple spaces
    line = line:gsub("  +", "  ")

    -- Ignore blank lines
    if not line:find("^ *$") then
      str = str .. line .. "\n"
    end

    line = ""
  end

  a2dtest.OCRIterate(function(run, x, y)
      --[[
        NOTE: With current system font, 0 and O are not homoglyphs, so
        this is not necessary.

        -- Contextually recognize zero (0) vs. capital 'O'
        -- run = run:gsub("(%d)O", "%10"):gsub("O(%d)", "0%1")
        -- run = run:gsub("([%l%u])0", "%1O"):gsub("0([%l%u])", "O%1")
      ]]

      if y ~= last_y then
        finish_line()
        last_y = y
      end

      line = line .. run
  end, options)
  finish_line()


  return str
end

--------------------------------------------------

function a2dtest.DiskCopyGetBlockCounts()
  local ocr = a2dtest.OCRScreen()
  function extract(pattern)
    local _, _, group = ocr:find(pattern)
    local n = assert(group:gsub(",", ""))
    return tonumber(n)
  end
  local transfer = extract("Blocks to transfer: (%d+[.,]?%d*)")
  local read = extract("Blocks Read: (%d+[.,]?%d*)")
  local written = extract("Blocks Written: (%d+[.,]?%d*)")
  return transfer, read, written
end

--------------------------------------------------

function a2dtest.GetFilesRemainingCount()
  local count = nil
  local ocr = a2dtest.OCRScreen({x1=280, y1=25, x2=470, y2=45})
  local _, _, match = ocr:find("Files remaining: ([0-9,]+)")
  if match then
    count = tonumber((match:gsub(",", "")))
  end
  return count
end

function a2dtest.VerifyFilesRemainingCountdown(frames, message)
  local last = nil

  for i = 1, frames/2 do
    local count = a2dtest.GetFilesRemainingCount()
    if count then
      test.Expect(not last or count <= last,
                  string.format("%s - should only count down, saw %q -> %q", message, last, count),
                  {}, 1)

      last = count
    elseif last then
      -- erased, so done early
      break
    end

    emu.wait(2/60)
  end

  test.ExpectEquals(last, 0,
              string.format("%s - progress should bottom out at 0", message),
              {}, 1)
end

--------------------------------------------------

return a2dtest
