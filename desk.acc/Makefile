
CC65 = ~/dev/cc65/bin
CAFLAGS = --target apple2enh --list-bytes 0
CCFLAGS = --config apple2-asm.cfg

OUTDIR = out

HEADERS = $(wildcard ../*.inc) $(wildcard ../inc/*.inc) $(wildcard *.inc)

DAS = calculator show_text_file date puzzle show_image_file

# ProDOS file type for DAs is $F1 ($ is pesky)
EXTENSION = F1

TARGETS = $(patsubst %,$(OUTDIR)/%.$(EXTENSION),$(DAS))

.PHONY: clean all
all: $(OUTDIR) $(TARGETS)

$(OUTDIR):
	mkdir -p $(OUTDIR)

clean:
	rm -f $(OUTDIR)/*.o
	rm -f $(TARGETS)

$(OUTDIR)/%.o: %.s $(HEADERS)
	$(CC65)/ca65 $(CAFLAGS) --listing $(basename $@).list -o $@ $<

$(OUTDIR)/%.$(EXTENSION): $(OUTDIR)/%.o
	$(CC65)/ld65 $(CCFLAGS) -o $@ $<
