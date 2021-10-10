HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard ../lib/*.s) $(wildcard ../mgtk/*.inc) $(wildcard *.inc) $(wildcard res/*.res.??) $(wildcard ../common/res/*.res.??)

include ../res/Makefile.common

TARGETS = $(OUTDIR)/desktop.built

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(TARGETS)

$(OUTDIR)/desktop.o: desktop.s $(HEADERS) loader.s aux.s lc.s res.s main.s init.s ovl*.s ../disk_copy/*.s ../mgtk/mgtk.s
	../bin/warnerr ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

# Built segments
$(OUTDIR)/%.built: $(OUTDIR)/%.o ../res/asm.cfg
	../bin/warnerr ld65 $(LDFLAGS) -o '$@' $<
