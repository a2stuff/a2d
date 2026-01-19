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

.PHONY: all $(targets) mount install package shk vercheck

# Default target
all: vercheck $(targets)

# Unconditionally built; recursive make takes care of their
# dependencies
$(targets):
	@tput setaf 3 && echo "Building: $@" && tput sgr0
	@$(MAKE) -C src/$@ \
	  && (tput setaf 2 && echo "make $@ good" && tput sgr0) \
          || (tput blink && tput setaf 1 && echo "MAKE $@ BAD" && tput sgr0 && false)

# --------------------------------------------------
# Package/Install targets
# --------------------------------------------------

# Populate mount/ as a mountable directory for Virtual ][
mount: $(targets) $(OUTDIR)/mount.sentinel
	@(tput setaf 2 && echo "make $@ good" && tput sgr0)

# Install to an existing disk image.
# Requires Cadius, and INSTALL_IMG and INSTALL_PATH to be set.
install: $(targets) $(OUTDIR)/install.sentinel
	@(tput setaf 2 && echo "make $@ good" && tput sgr0)

# Build disk images for distribution.
# Requires Cadius.
package: $(targets) $(OUTDIR)/package.sentinel
	@(tput setaf 2 && echo "make $@ good" && tput sgr0)

# Build ShrinkIt archive for distribution.
# Requires NuLib2.
shk: $(targets) $(OUTDIR)/shk.sentinel
	@(tput setaf 2 && echo "make $@ good" && tput sgr0)

MANIFEST = $(shell bin/manifest_list)
$(OUTDIR)/%.sentinel: $(MANIFEST) $(OUTDIR)/buildinfo.inc
	@bin/$*
	@touch $(OUTDIR)/$*.sentinel

# --------------------------------------------------
# Miscellaneous
# --------------------------------------------------

# Clean all temporary/target files
clean:
	@for dir in $(targets); do \
	  tput setaf 2 && echo "cleaning $$dir" && tput sgr0; \
	  $(MAKE) -C src/$$dir clean; \
	done
	rm -f $(OUTDIR)/*.sentinel

# Ensure minimum cc65 version
vercheck:
	@bin/check_ver.pl ca65 v2.19
	@bin/check_ver.pl ld65 v2.19

# Build Date
$(OUTDIR)/buildinfo.inc: FORCE
	@$(BINDIR)/make_buildinfo_inc

FORCE:
