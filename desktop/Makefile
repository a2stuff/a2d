
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config asm.cfg

TARGETS = loader.built mgtk.built desktop.built invoker.built

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
