# Enable color output in tput, used in Makefiles and scripts.
# This is theoretically bad, but in practice it's fine.
export TERM = xterm-256color

targets := desktop disk_copy selector launcher desk_acc extras

.PHONY: all $(targets) mount install package shk vercheck

all: vercheck $(targets)

# Build all targets
$(targets):
	@tput setaf 3 && echo "Building: $@" && tput sgr0
	@$(MAKE) -C src/$@ \
	  && (tput setaf 2 && echo "make $@ good" && tput sgr0) \
          || (tput blink && tput setaf 1 && echo "MAKE $@ BAD" && tput sgr0 && false)

# Optional target: populate mount/ as a mountable directory for Virtual ][
mount:
	bin/mount

# Optional target: run install script. Requires Cadius, and INSTALL_IMG and INSTALL_PATH to be set.
install:
	bin/install

# Optional target: run package script. Requires Cadius.
package:
	bin/package

# Optional target: make ShrinkIt archive. Requires NuLib2.
shk:
	bin/shk

# Clean all temporary/target files
clean:
	@for dir in $(targets); do \
	  tput setaf 2 && echo "cleaning $$dir" && tput sgr0; \
	  $(MAKE) -C src/$$dir clean; \
	done

# Ensure minimum cc65 version
vercheck:
	@bin/check_ver.pl ca65 v2.19
	@bin/check_ver.pl ld65 v2.19
