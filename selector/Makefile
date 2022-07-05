HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard ../lib/*.s) $(wildcard ../mgtk/*.inc) $(wildcard *.inc) $(wildcard res/*.res.??) $(wildcard ../common/res/*.res.??) $(wildcard ../mgtk/fonts/System.*)

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

$(OUTDIR)/selector.o: selector.s $(HEADERS) quit_handler.s loader.s app.s alert_dialog.s ovl_*.s ../mgtk/mgtk.s
	../bin/warnerr ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

# Built segments
$(OUTDIR)/%.built: $(OUTDIR)/%.o ../res/asm.cfg
	../bin/warnerr ld65 $(LDFLAGS) -o '$@' $<
