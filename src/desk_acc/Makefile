TOOLKITS = letk btk lbtk
HEADERS = $(COMMON_HEADERS) \
	$(MONO_FONT) \
	$(wildcard neko_frames/*.bin) \
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
