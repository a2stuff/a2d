--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl7 cffa2 -aux ext80"
DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]--


--[[============================================================

  Test Script

  ============================================================]]--

test.Step(
  "Sample Media",
  function()
    a2d.SelectAndOpen("A2.DESKTOP")
    a2d.SelectAndOpen("SAMPLE.MEDIA")
    test.Snap("Sample Media")

    -- Change window size
    a2d.OAShortcut("G")
    apple2.RightArrowKey()
    apple2.RightArrowKey()
    apple2.RightArrowKey()
    apple2.RightArrowKey()
    apple2.ReturnKey()
    a2d.WaitForRepaint()
    test.Snap("Changed window size")

    -- Open MONARCH (image preview)
    a2d.SelectAndOpen("MONARCH")
    emu.wait(5) -- load big file
    test.Snap("Image preview")
    apple2.EscapeKey()
    a2d.WaitForRepaint()
    test.Snap("Back to desktop")
    return test.PASS
end)

test.Step(
  "Move Mouse",
  function()
    -- Move the mouse
    apple2.MoveMouse(480, 170)
    test.Snap("Mouse to 480,170")

    -- Move the mouse
    apple2.MoveMouse(0, 0)
    test.Snap("Mouse to 0,0")
    return test.PASS
end)

function IsHi(ident)
  if apple2.ReadSSW(ident) > 127 then
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

--[[
  local last = apple2.ReadMemory(0x2000)
  while true do
  emu.wait(5/60)
  local cur = apple2.ReadMemory(0x2000)
  if cur ~= last then
  print("Now is " .. cur)
  last = cur
  end
  end
]]--
