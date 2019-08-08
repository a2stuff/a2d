include ../res/Makefile.common

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
	rm -f $(OUTDIR)/*.seg
	rm -f $(TARGETS)

$(OUTDIR)/mgtk.o: ../mgtk/mgtk.s $(HEADERS)
	ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/desktop.o: desktop.s $(HEADERS) desktop_*.s ovl*.s
	ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

# Built DeskTop segments
$(OUTDIR)/%.seg: $(OUTDIR)/%.o ../res/asm.cfg
	ld65 $(LDFLAGS) -o '$@' $<

# DeskTop combined
$(OUTDIR)/DESKTOP2.built: $(patsubst %,$(OUTDIR)/%.seg,$(SEGMENTS))
	cat $(patsubst %,$(OUTDIR)/%.seg,$(SEGMENTS)) > $@
