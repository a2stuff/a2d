--[[============================================================

  Key Caps

  ============================================================]]--

test.Step(
  "Key Caps - Quit",
  function()
    a2d.OpenPath("/A2.DESKTOP/APPLE.MENU/KEY.CAPS")
    apple2.PressOA()
    apple2.Type("q")
    apple2.ReleaseOA()
    a2d.WaitForRepaint()
    test.Snap("verify the desk accessory exited")
end)

function find_field(name)
  for pn,p in pairs(machine.ioport.ports) do
    for fn,f in pairs(p.fields) do
      if fn == name then
        return f
      end
    end
  end
  error("Unable to find field \""..name.."\"")
end


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

