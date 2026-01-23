HEADERS = $(COMMON_HEADERS) \
	$(wildcard *.bin)

include ../common/Makefile.common

TARGETS = $(OUTDIR)/awlaunch.system.SYS \
	$(OUTDIR)/asmtest.system.SYS

.PHONY: all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

.PHONY: clean
clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(TARGETS)
