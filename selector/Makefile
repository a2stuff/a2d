
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config asm.cfg

OUTDIR = out

HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard ../mgtk/*.inc) $(wildcard *.inc)

SEGMENTS = selector

TARGETS = $(OUTDIR)/selector.built

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(OUTDIR)/*.inc
	rm -f $(OUTDIR)/*.built
	rm -f $(OUTDIR)/*.sys

$(OUTDIR)/selector.o: selector.s $(HEADERS) selector*.s
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

# Built segments
$(OUTDIR)/%.built: $(OUTDIR)/%.o asm.cfg
	$(CC65)/ld65 $(CCFLAGS) -o '$@' $<
