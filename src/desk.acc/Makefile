HEADERS = $(COMMON_HEADERS) \
	$(MONO_FONTS) \
	$(wildcard neko_frames/*.bin) \
	../desktop/desktop.inc ../mgtk/mgtk.inc $(wildcard ../toolkits/*.inc)

include ../common/Makefile.common

DAS = $(shell cat TARGETS | ../../bin/targets.pl targets)

TARGETS = $(patsubst %,$(OUTDIR)/%.da,$(DAS))

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(OUTDIR)/*.font
	rm -f $(TARGETS)
