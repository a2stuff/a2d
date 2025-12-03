--[[============================================================

  A2D-specific Test Utilities

  ============================================================]]--

local a2dtest = {}

local apple2 = require("apple2")
local a2d = require("a2d")
local test = require("test")

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
  test.Expect(apple2.CompareDHR(bytes), "nothing should have changed", {snap=true})
end

--------------------------------------------------

return a2dtest
