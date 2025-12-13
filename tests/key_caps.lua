--[[
  Launch DeskTop. Run Apple Menu > Key Caps desk accessory. Turn Caps
  Lock off. Hold Apple (either one) and press the Q key. Verify the
  desk accessory exits.
]]
test.Step(
  "Key Caps - Quit",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS")
    local count = a2dtest.GetWindowCount()
    a2d.OAShortcut("q")
    test.Expect(a2dtest.GetWindowCount(), count-1, "the desk accessory should have closed")
end)

function find_field(name)
  for pn,p in pairs(manager.machine.ioport.ports) do
    for fn,f in pairs(p.fields) do
      if fn == name then
        return f
      end
    end
  end
  error("Unable to find field \""..name.."\"")
end

--[[
  Launch DeskTop. Run Apple Menu > Key Caps desk accessory. Press the
  semicolon/colon key. Verify that the highlight is correctly
  positioned.
]]
test.Step(
  "Key Caps - Semicolon",
  function()
    local field = find_field(";  :")
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS")
    field:set_value(1)
    a2d.WaitForRepaint()
    test.Snap("verify that the semicolon key is correctly highlighted")
    field:clear_value()
    a2d.CloseWindow()
end)

