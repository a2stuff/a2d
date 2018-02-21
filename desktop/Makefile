
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config asm.cfg

OUTDIR = out

HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard *.inc)

SEGMENTS = loader mgtk desktop invoker \
        ovl1 ovl1a ovl5 ovl6

EXTENSION = built

TARGETS = $(patsubst %,$(OUTDIR)/%.$(EXTENSION),$(SEGMENTS))

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(TARGETS)

$(OUTDIR)/%.o: %.s $(HEADERS)
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.$(EXTENSION): $(OUTDIR)/%.o asm.cfg
	$(CC65)/ld65 $(CCFLAGS) -o $@ $<
