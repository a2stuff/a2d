
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config asm.cfg

TARGETS = s0_loader.built s123_aux.built s4_main1.built

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
	diff s0_loader.built orig/DESKTOP2_s0_loader
	diff s123_aux.built orig/DESKTOP2_s123_aux
	diff s4_main1.built orig/DESKTOP2_s4_main1
