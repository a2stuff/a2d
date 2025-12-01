# Executable scripts, for builds or development

## Building/Packaging/Installation

* [bumpver](bumpver)
  * Bumps the version e.g. from alpha2 to alpha3.
* [defopt](defopt)
  * Adds a default configuration file to a disk image.
* [install](install)
  * Installs a build to a disk image.
* [lkg](lkg)
  * Builds a "last known good" package for the web site.
* [manifest](manifest)
  * Outputs a list of files. Used by `package`, `install`, etc.
* [mount](mount)
  * Installs a build to a directory, for use with Virtual ][.
* [package](package)
  * Generates a set of disk images for distribution.
* [roll](roll)
  * Updates external dependencies.
* [make_buildinfo_inc](make_buildinfo_inc)
  * Generates include file containing the last commit date, etc.
* [setlang](setlang)
  * Updates the config to build the specified language.
* [setopt](setopt)
  * Updates the configuration file in a disk image.
* [shk](shk)
  * Generates a ShrinkIt! archive for distribution.
* [targets.pl](targets.pl)
  * Parses the `desk.acc/TARGETS` file, generates requested lists.

## Internationalization/Localization

* [Transcode.pm](Transcode.pm)
  * Perl library implementing 7-bit encoders/decoders, for localized builds.
* [loc_makeres.pl](loc_makeres.pl)
  * Builds "res" files from a CSV copy of the master localization spreadsheet.
* [transcode.pl](transcode.pl)
  * Utility for doing encoding/decoding of strings, for localized builds.

## Fonts

* [build_font_from_unicode_txt.pl](build_font_from_unicode_txt.pl)
  * Converts a text representation of a font to an MGTK font, for a given encoding.
* [bw_font.pl](bw_font.pl)
  * Dumps a BeagleWrite font to a text representation.
* [convert_font.pl](convert_font.pl)
  * Converts an HRCG font to an MGTK font.
* [dump_font.pl](dump_font.pl)
  * Dumps an MGTK font to a text representation.
* [make_font.pl](make_font.pl)
  * Converts a text representation of a font to an MGTK font.

## Development Utilities

* [asmfmt.pl](asmfmt.pl)
  * Applies some of the coding style guidelines to a source file.
* [audit_das](audit_das)
  * Shows the size of the Main and Aux segments of all desk accessories.
* [endproc.pl](endproc.pl)
  * Applies the coding style guidelines for `.endproc` comments.
* [mametest](mametest)
  * Runs Lua test scripts from `tests/` in MAME.
* [md5](md5)
  * Generates MD5 checksums for all built files. Useful for ensuring a change does not alter the binaries in any way.
* [stats.pl](stats.pl)
  * Provides statistics about the disassembly status of source files.

## Miscellaneous

* [check_ver.pl](check_ver.pl)
  * Verify that the version string (e.g. from a build tool) matches out minimum requirements.
* [colorize](colorize)
  * Runs the passed command, and format any error output as red. Used in various Makefiles.
* [hr2dhr.pl](hr2dhr.pl)
  * Generates the tables used to convert an image from single hi-res to double hi-res form.
* [packbytes.pl](packbytes.pl)
  * Compresses the input to the "PackBytes" format.
* [unpackbytes.pl](unpackbytes.pl)
  * Decompresses the input from the "PackBytes" format.
* [util.sh](util.sh)
  * Helper functions used in other shell scripts.
