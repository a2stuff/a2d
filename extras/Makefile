HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard ../lib/*.s) $(wildcard res/*.res.??) $(wildcard ../common/res/*.res.??)

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
