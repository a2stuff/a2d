--[[ BEGINCONFIG ========================================

MODEL="las128e2"
MODELARGS="-ramsize 1152K"
DISKARGS="-flop1 $FLOP1IMG"

# Doesn't recognize -sl7
# MODELARGS="-ramsize 1152K -sl7 cffa2"
# DISKARGS="-hard1 $HARDIMG"

======================================== ENDCONFIG ]]

require("lib/config_test")

ConfigTest()
