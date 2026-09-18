--[[ BEGINCONFIG ========================================

MODELARGS="-sl2 mouse -sl6 cffa2 -sl7 cffa2"
DISKARGS="-hard3 $HARDIMG -hard1 sizes/image_280_blocks.hdv -hard2 sizes/image_280_blocks_random.hdv"

======================================== ENDCONFIG ]]

local s6d1 = manager.machine.images[":sl6:cffa2:cffa2_ata:0:hdd:image"]
local s6d2 = manager.machine.images[":sl6:cffa2:cffa2_ata:1:hdd:image"]

require("lib/copy_blocks")

CopyBlocksTests(280, s6d1, s6d2)

