--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl5 cffa2 -sl6 superdrive"
DISKARGS="-flop1 $HARDIMG -hard1 sizes/image_65534_blocks.hdv -hard2 sizes/image_65534_blocks.hdv"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

local s6d1 = manager.machine.images[":sl6:cffa2:cffa2_ata:0:hdd:image"]
local s6d2 = manager.machine.images[":sl6:cffa2:cffa2_ata:1:hdd:image"]

require("lib/copy_blocks")

CopyBlocksTests(65534, s6d1, s6d2)
