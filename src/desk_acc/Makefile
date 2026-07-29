TOOLKITS = letk btk lbtk
HEADERS = $(COMMON_HEADERS) \
	../desktop/desktop.inc \
        ../mgtk/mgtk.inc \
	$(foreach TK,$(TOOLKITS),../toolkits/$(TK).inc)

include ../common/Makefile.common

DAS := $(shell cat TARGETS | ../../bin/targets.pl targets)

TARGETS = $(patsubst %,$(OUTDIR)/%.da,$(DAS))

.PHONY: all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

.PHONY: clean
clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(OUTDIR)/*.font
	rm -f $(OUTDIR)/*.inc
	rm -f $(OUTDIR)/*.tmp
	rm -f $(TARGETS)

# Additional dependencies of specific targets
$(OUTDIR)/message.o: ../../res/fonts/Athens
$(OUTDIR)/minesweeper.o $(OUTDIR)/minesweeper.x.o: minesweeper_base.s
$(OUTDIR)/neko.o: $(wildcard neko_frames/*.bin.lzsa)
$(OUTDIR)/show.text.file.o: $(MONO_FONT)
