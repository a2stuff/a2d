HEADERS = $(COMMON_HEADERS) \
	$(wildcard ../mgtk/fonts/System.*) \
	../mgtk/mgtk.inc ../toolkits/btk.inc

include ../res/Makefile.common

TARGETS = $(OUTDIR)/selector.built

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(TARGETS)

$(OUTDIR)/selector.o: selector.s $(HEADERS) loader.s app.s alert_dialog.s ovl_*.s ../mgtk/mgtk.s ../toolkits/btk.s
	../bin/warnerr ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.built: $(OUTDIR)/%.o ../res/asm.cfg
	../bin/warnerr ld65 $(LDFLAGS) -o '$@' $<
