TOOLKITS = btk lbtk
HEADERS = $(COMMON_HEADERS) \
	$(SYS_FONTS) \
	../mgtk/mgtk.inc \
	$(foreach TK,$(TOOLKITS),../toolkits/$(TK).inc)

include ../common/Makefile.common

TARGETS = $(OUTDIR)/disk_copy.built

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

$(OUTDIR)/disk_copy.o: disk_copy.s $(HEADERS) loader.s auxlc.s main.s $(foreach TK,$(TOOLKITS),../toolkits/$(TK).s)
	ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.built: $(OUTDIR)/%.o ../common/asm.cfg
	ld65 $(LDFLAGS) -o '$@' $<
