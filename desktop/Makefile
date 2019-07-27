
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config asm.cfg

OUTDIR = out

HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard ../mgtk/*.inc) $(wildcard *.inc)

SEGMENTS = loader mgtk desktop

TARGETS = $(OUTDIR)/DESKTOP2.built

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(OUTDIR)/*.built
	rm -f $(TARGETS)

$(OUTDIR)/mgtk.o: ../mgtk/mgtk.s $(HEADERS)
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/desktop.o: desktop.s $(HEADERS) desktop_* ovl*.s
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.o: %.s $(HEADERS)
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

# Built DeskTop segments
$(OUTDIR)/%.built: $(OUTDIR)/%.o asm.cfg
	$(CC65)/ld65 $(CCFLAGS) -o '$@' $<

# DeskTop combined
$(OUTDIR)/DESKTOP2.built: $(patsubst %,$(OUTDIR)/%.built,$(SEGMENTS))
	cat $(patsubst %,$(OUTDIR)/%.built,$(SEGMENTS)) > $@
