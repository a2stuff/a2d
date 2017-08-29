Disassembly of the Show Text File desk accessory

* `go.sh` - bash script used to drive the initial disassembly
   (now commented out) and building

* `show_text_file.bin` - original binary (type $F1, start $800)
* `show_text_file.info` - da65 "info" file
* `stf.s` - source (originally generated using da65, now modified)
* `stf.o` - object file (assembled with ca65)
* `stf.list` - listing file (output by ca65)
* `stf` - linked target - byte-for-byte identical with original
