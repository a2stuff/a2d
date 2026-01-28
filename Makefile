# Enable color output in tput, used in Makefiles and scripts.
# This is theoretically bad, but in practice it's fine.
export TERM = xterm-256color

OUTDIR = out
BINDIR = bin

# --------------------------------------------------
# Build targets
# --------------------------------------------------

# Subdirectory targets
targets := desktop disk_copy selector launcher desk_acc extras


# Default target
.PHONY: all
all: vercheck $(targets)

# Unconditionally built; recursive make takes care of their
# dependencies
.PHONY: $(targets)
$(targets):
	@$(MAKE) -C src/$@ \
	  && echo "$$(tput setaf 2)make $@ good$$(tput sgr0)" \
	  || (echo "$$(tput blink && tput setaf 1)MAKE $@ BAD$$(tput sgr0)" && false)

# --------------------------------------------------
# Package/Install targets
# --------------------------------------------------

.PHONY: mount install package shk
.WAIT:

# Populate mount/ as a mountable directory for Virtual ][
mount: $(targets) .WAIT $(OUTDIR)/mount.sentinel
	@(tput setaf 2 && echo "make $@ good" && tput sgr0)

# Install to an existing disk image.
# Requires Cadius, and INSTALL_IMG and INSTALL_PATH to be set.
install: $(targets) .WAIT $(OUTDIR)/install.sentinel
	@(tput setaf 2 && echo "make $@ good" && tput sgr0)

# Build disk images for distribution.
# Requires Cadius.
package: $(targets) .WAIT $(OUTDIR)/package.sentinel
	@(tput setaf 2 && echo "make $@ good" && tput sgr0)

# Build ShrinkIt archive for distribution.
# Requires NuLib2.
shk: $(targets) .WAIT $(OUTDIR)/shk.sentinel
	@(tput setaf 2 && echo "make $@ good" && tput sgr0)


MANIFEST = $(shell bin/manifest_list)
$(OUTDIR)/%.sentinel: $(MANIFEST) $(OUTDIR)/buildinfo.inc
	@bin/$*
	@touch $(OUTDIR)/$*.sentinel
# Specialization for "install" which optionally skips sample media
$(OUTDIR)/install.sentinel: $(shell no_sample_media=$$INSTALL_NOSAMPLES bin/manifest_list) $(OUTDIR)/buildinfo.inc
	@bin/install
	@touch $(OUTDIR)/install.sentinel

.SECONDEXPANSION:
$(OUTDIR)/%.font: res/fonts/$$(basename $$*).unicode.txt
	$(BINDIR)/build_font_from_unicode_txt.pl $(subst .,,$(suffix $*)) < res/fonts/$(basename $*).unicode.txt > $@
.PRECIOUS: $(OUTDIR)/%.font

# --------------------------------------------------
# Miscellaneous
# --------------------------------------------------

# Clean all temporary/target files
clean:
	@for dir in $(targets); do \
	  echo "$$(tput setaf 3)cleaning $$dir$$(tput sgr0))"; \
	  $(MAKE) -C src/$$dir clean; \
	done
	rm -f $(OUTDIR)/*.sentinel

# Ensure minimum cc65 version
.PHONY: vercheck
vercheck:
	@bin/check_ver.pl ca65 v2.19
	@bin/check_ver.pl ld65 v2.19

# Build Date
$(OUTDIR)/buildinfo.inc: FORCE
	@$(BINDIR)/make_buildinfo_inc

FORCE:
