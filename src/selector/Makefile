TOOLKITS = btk lbtk optk
HEADERS = $(COMMON_HEADERS) \
	$(SYS_FONTS) \
	../mgtk/mgtk.inc \
	$(foreach TK,$(TOOLKITS),../toolkits/$(TK).inc)

include ../common/Makefile.common

TARGETS = $(OUTDIR)/selector.built

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(OUTDIR)/*.fonts
	rm -f $(OUTDIR)/*.inc
	rm -f $(OUTDIR)/*.tmp
	rm -f $(TARGETS)

$(OUTDIR)/selector.o: selector.s $(HEADERS) loader.s app.s alert_dialog.s ovl_*.s ../mgtk/mgtk.s $(foreach TK,$(TOOLKITS),../toolkits/$(TK).s)
	ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.built: $(OUTDIR)/%.o ../common/asm.cfg
	ld65 $(LDFLAGS) -o '$@' $<
