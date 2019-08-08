include ../res/Makefile.common

HEADERS = $(wildcard ../*.inc)

TARGETS = $(OUTDIR)/desktop.system.SYS

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(OUTDIR)/*.seg
	rm -f $(TARGETS)
