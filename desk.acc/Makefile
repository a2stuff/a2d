
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config apple2-asm.cfg

# ProDOS file type is $F1 ($ is pesky)
TARGETS = show_text_file.F1 show_dhr_file.F1

.PHONY: clean all
all: $(TARGETS)

HEADERS = $(wildcard ../*.h)

clean:
	rm -f *.o
	rm -f $(TARGETS)

%.o: %.s $(HEADERS)
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

%.F1: %.o
	$(CC65)/ld65 $(CCFLAGS) -o $@ $<
