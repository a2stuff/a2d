
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config asm.cfg

TARGETS = loader.built a2d.built desktop.built s5.built s6.built

.PHONY: clean all
all: $(TARGETS)

HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard *.inc)

clean:
	rm -f *.o
	rm -f $(TARGETS)

%.o: %.s $(HEADERS)
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

%.built: %.o asm.cfg
	$(CC65)/ld65 $(CCFLAGS) -o $@ $<

check:
	diff loader.built orig/DESKTOP2_s0_loader
	diff a2d.built orig/DESKTOP2_s1_a2d
	diff desktop.built orig/DESKTOP2_s2_desktop
	diff s5.built orig/DESKTOP2_s5
	diff s6.built orig/DESKTOP2_s6
