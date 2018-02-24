
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config asm.cfg

OUTDIR = out

HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard *.inc)

SEGMENTS = loader mgtk desktop invoker \
        ovl1 ovl1a ovl2 ovl5 ovl6 ovl7

TARGETS = $(patsubst %,$(OUTDIR)/%.built,$(SEGMENTS))

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(OUTDIR)/*.list
	rm -f $(OUTDIR)/*.built
	rm -f $(OUTDIR)/*.\$$F1
	rm -f $(OUTDIR)/*.sys

$(OUTDIR)/%.o: %.s $(HEADERS)
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

# Built DeskTop segments
$(OUTDIR)/%.built: $(OUTDIR)/%.o asm.cfg
	$(CC65)/ld65 $(CCFLAGS) -o '$@' $<

# Desk Accessories .$F1
$(OUTDIR)/%.$$F1: $(OUTDIR)/%.o
	$(CC65)/ld65 $(CCFLAGS) -o '$@' $<
	xattr -w prodos.AuxType '@' '$@'

# System Files .SYS
$(OUTDIR)/%.SYS: $(OUTDIR)/%.o
	$(CC65)/ld65 $(CCFLAGS) -o '$@' $<
	xattr -wx prodos.AuxType '00 20' $@
