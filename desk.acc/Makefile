HEADERS = $(wildcard ../*.inc) $(wildcard ../*/*.inc) $(wildcard ../lib/*.s) $(wildcard *.inc) $(wildcard res/*.res.??) $(wildcard ../common/res/*.res.??) $(wildcard ../mgtk/fonts/*)

include ../res/Makefile.common

DAS = $(shell cat TARGETS | ../bin/targets.pl targets)

TARGETS = $(patsubst %,$(OUTDIR)/%.da,$(DAS))

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(TARGETS)
