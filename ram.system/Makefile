
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config apple2-asm.cfg

OUTDIR = out

HEADERS = $(wildcard ../*.inc)

TARGETS = $(OUTDIR)/ram.system.SYS

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(TARGETS)

$(OUTDIR)/%.o: %.s $(HEADERS)
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

# System Files .SYS
$(OUTDIR)/%.SYS: $(OUTDIR)/%.o
	$(CC65)/ld65 $(CCFLAGS) -o '$@' $<
	xattr -wx prodos.AuxType '00 20' $@
