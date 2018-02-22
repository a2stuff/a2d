#!/bin/bash

dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_loader  skip=$((    0x0)) count=$(( 0x580))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_mgtk    skip=$((  0x580)) count=$((0x451F))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_desktop skip=$(( 0x4A9F)) count=$((0xE3E1))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_invoker skip=$((0x12E80)) count=$(( 0x160))

dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl1    skip=$((0x12FE0)) count=$(( 0x200))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl1a   skip=$((0x131E0)) count=$(( 0x200))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl1b   skip=$((0x133E0)) count=$((0x2200))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl1c   skip=$((0x155E0)) count=$(( 0xB00))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl2    skip=$((0x160E0)) count=$((0x1400))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl3    skip=$((0x174E0)) count=$((0x1000))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl4    skip=$((0x184E0)) count=$((0x2000))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl5    skip=$((0x1A4E0)) count=$(( 0x800))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl6    skip=$((0x1ACE0)) count=$(( 0x800))
dd if=DESKTOP2.\$F1 bs=1 of=DESKTOP2_ovl7    skip=$((0x1B4E0)) count=$(( 0x800))
