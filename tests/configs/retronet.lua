--[[ BEGINCONFIG ========================================

MODEL="apple2ee"
MODELARGS="-sl2 mouse -sl6 retronet -sl7 retronet"
DISKARGS="\
  -hard1 disk_e.2mg \
  -hard2 disk_f.2mg \
  -hard3 disk_g.2mg \
  -hard4 disk_h.2mg \
  -hard5 disk_i.2mg \
  -hard6 disk_j.2mg \
  -hard7 disk_k.2mg \
  -hard8 disk_l.2mg \
  \
  -hard9 $HARDIMG \
  -hard10 disk_a.2mg \
  -hard11 disk_b.2mg \
  -hard12 disk_c.2mg \
  -hard13 disk_d.2mg \
  "

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

test.Step(
  "Apple > About This Apple II",
  function()
    a2d.InvokeMenuItem(a2d.APPLE_MENU, a2d.ABOUT_THIS_APPLE_II)
    emu.wait(1)
    test.Snap(manager.machine.system.name)
end)
