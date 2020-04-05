HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard ../mgtk/*.inc) $(wildcard *.inc)

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

$(OUTDIR)/selector.o: selector.s $(HEADERS) selector*.s
	ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

# Built segments
$(OUTDIR)/%.built: $(OUTDIR)/%.o asm.cfg
	ld65 $(LDFLAGS) -o '$@' $<
