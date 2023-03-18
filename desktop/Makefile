HEADERS = $(COMMON_HEADERS) \
	$(wildcard ../mgtk/fonts/System.*) \
	../mgtk/mgtk.inc ../toolkits/icontk.inc ../toolkits/letk.inc ../toolkits/btk.inc

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

$(OUTDIR)/desktop.o: desktop.s $(HEADERS) loader.s auxmem.s lc.s res.s main.s init.s ovl*.s ../disk_copy/disk_copy.inc ../mgtk/mgtk.s ../toolkits/icontk.s ../toolkits/letk.s ../toolkits/btk.s
	../bin/colorize ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.built: $(OUTDIR)/%.o ../res/asm.cfg
	../bin/colorize ld65 $(LDFLAGS) -o '$@' $<
