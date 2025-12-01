TOOLKITS = icontk letk btk lbtk optk
HEADERS = $(COMMON_HEADERS) \
	$(SYS_FONTS) \
	../mgtk/mgtk.inc \
	$(foreach TK,$(TOOLKITS),../toolkits/$(TK).inc)

include ../common/Makefile.common

TARGETS = $(OUTDIR)/desktop.built

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(OUTDIR)/*.font
	rm -f $(OUTDIR)/*.inc
	rm -f $(OUTDIR)/*.tmp
	rm -f $(TARGETS)

$(OUTDIR)/desktop.o: desktop.s $(HEADERS) loader.s auxmem.s lc.s res.s main.s init.s ovl*.s ../disk_copy/disk_copy.inc ../mgtk/mgtk.s $(foreach TK,$(TOOLKITS),../toolkits/$(TK).s)
	ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.built: $(OUTDIR)/%.o ../common/asm.cfg
	ld65 $(LDFLAGS) -o '$@' $<
