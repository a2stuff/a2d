--[[ BEGINCONFIG ========================================

MODELARGS="-sl1 thclock -sl2 mouse -sl4 softcard -sl7 cffa2"

======================================== ENDCONFIG ]]

a2d.ConfigureRepaintTime(0.25)

require("lib/date_and_time")

ClockTests("ThunderClock")
