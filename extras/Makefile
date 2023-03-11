HEADERS = $(COMMON_HEADERS) \
	$(wildcard *.bin)

include ../res/Makefile.common

TARGETS = $(OUTDIR)/awlaunch.system.SYS

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(TARGETS)
