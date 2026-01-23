HEADERS = $(COMMON_HEADERS)

include ../common/Makefile.common

TARGETS = $(OUTDIR)/desktop.system.SYS

.PHONY: all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

.PHONY: clean
clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(TARGETS)
