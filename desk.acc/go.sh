#!/bin/bash

set -e

CC65=~/dev/cc65/bin

original=show_text_file.bin
disasm=show_text_file.d

src=show_text_file.s
obj=show_text_file.o
list=show_text_file.list
out=show_text_file

# Origin of STF
#echo '        .org $800' > $disasm

# Disassemble original source
#$CC65/da65 $original --info show_text_file.info >> $disasm

#cp $disasm $src

# Assemble
$CC65/ca65 --target apple2enh --listing $list --list-bytes 0 -o $obj $src

# Link
$CC65/ld65 --config apple2-asm.cfg -o $out $obj

# Verify original and output match
diff $original $out

$CC65/ca65 --target apple2enh --listing dhr.list --list-bytes 0 -o dhr.o dhr.s
$CC65/ld65 --config apple2-asm.cfg -o dhr dhr.o

# Show output for review
#less $list
less dhr.list
