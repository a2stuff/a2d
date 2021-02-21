targets := desktop desktop.system desk.acc selector

.PHONY: all $(targets) mount install installsel package

all: $(targets)

# Build all targets
$(targets):
	@tput setaf 3 && echo "Building: $@" && tput sgr0
	@$(MAKE) -C $@ \
	  && (tput setaf 2 && echo "make $@ good" && tput sgr0) \
          || (tput blink && tput setaf 1 && echo "MAKE $@ BAD" && tput sgr0 && false)

# Optional target: populate mount/ as a mountable directory for Virtual ][
mount:
	bin/mount

# Optional target: run install script. Requires Cadius, and INSTALL_IMG and INSTALL_PATH to be set.
install:
	bin/install

# Optional target: run install script. Requires Cadius, and INSTALL_IMG and INSTALL_PATH to be set.
installsel:
	bin/install selector

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
	  $(MAKE) -C $$dir clean; \
	done
