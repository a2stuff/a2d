#!/bin/bash

# Run this from the top level directory

# Use nulib2 to create a ShrinkIt! archive for distribution
# https://nulib.com

set -e
source "res/util.sh"

NULIB2=$(command -v nulib2 || echo '')
NULIB2="${PNULIB2:-$HOME/dev/nulib2/nulib2/nulib2}"

tempdir=$(mktemp -d -t SHK)
test -d "${tempdir}" || (cecho red "cannot make tempdir"; exit 1)

rm -f A2D.SHK

# Add file to staging directory
# Usage: add_file SRC DST TYPEAUXTYPE
function add_file {
    src="$1"
    dst="$2"
    typeauxtype="$3"
    cp "$src" "$tempdir/$dst#$typeauxtype" \
        && (cecho green "staging $dst" ) \
        || (cecho red "failed to stage $dst" ; return 1)
}

cecho yellow "Copying files..."

perl -p -i -e 's/\r?\n/\r/g' "res/package/READ.ME" # Ensure Apple line endings
add_file "res/package/READ.ME" "READ.ME" 040000

add_file "desktop.system/out/desktop.system.SYS" "DESKTOP.SYSTEM" FF0000
add_file "desktop/out/desktop.built" "DESKTOP2" F10000

mkdir -p $tempdir/OPTIONAL
add_file "selector/out/selector.built" "OPTIONAL/SELECTOR" F10000

for path in $(cat desk.acc/TARGETS | res/targets.pl dirs); do
    uc=$(echo "$path" | tr /a-z/ /A-Z/)
    mkdir -p "$tempdir/$uc"
done
for line in $(cat desk.acc/TARGETS | res/targets.pl); do
    IFS=',' read -ra array <<< "$line"
    file="${array[0]}"
    path="${array[1]}"
    uc_file=$(echo "$file" | tr /a-z/ /A-Z/)
    uc_path=$(echo "$path" | tr /a-z/ /A-Z/)
    add_file "desk.acc/out/${file}.da" "${uc_path}/${uc_file}" F10640
done

cecho yellow "Creating SHK..."

cdir=`pwd`
cd "${tempdir}"
$NULIB2 aer "${cdir}/A2D.SHK" * || (cecho red "failed to write ${cdir}/A2D.SHK" ; return 1)
cd "${cdir}"
rm -rf "${tempdir}"

ls -l A2D.SHK
