#!/usr/bin/env bash

# cecho - "color echo"
# ex: cecho red ...
# ex: cecho green ...
# ex: cecho yellow ...
function cecho {
    case $1 in
        red)    tput setaf 1 ; shift ;;
        green)  tput setaf 2 ; shift ;;
        yellow) tput setaf 3 ; shift ;;
    esac
    echo -e "$@"
    tput sgr0
}

# suppress - hide command output unless it failed; and if so show in red
# ex: suppress command_that_might_fail args ...
function suppress {
    set +e
    local result
    result=$("$@")
    if [ $? -ne 0 ]; then
        cecho red "$result" >&2
        exit 1
    fi
    set -e
}

# Progress meter
#  * init_progress
#  * eval "$manifest"
#  * fini_progress
#  ... and in add_file call:
#  * progress "$path"

repeat () {
    if [ $2 -gt 0 ]; then
        for i in $(seq 1 $2); do echo -n "$1"; done
    fi
}

init_progress() {
    total_lines=$(echo "$manifest" | grep add_file | wc -l)
    current_line=0
}

progress () {
    local path="$1"

    local w=30
    local l=$(expr $w \* $current_line / $total_lines)
    local r=$(expr $w - $l)
    local ls=$(repeat '#' $l)
    local rs=$(repeat ':' $r)

    local cols=$(tput cols)
    local pw=$(expr $cols - $w - 3)
    path="$(echo "$path" | cut -c1-$pw)"

    local reset="$(tput sgr0)"
    local red="$(tput setaf 1)"
    local green="$(tput setaf 2)"

    echo -ne "\r$(tput el)[${green}$ls${red}$rs${reset}] ${green}$path${reset}"
    current_line=$(expr $current_line + 1)
}

fini_progress () {
    echo -ne "\r$(tput el)"
}

# ============================================================
# Extract metadata for the build

vmajor=$(grep 'kDeskTopVersionMajor =' src/config.inc | sed -e 's/.* = //')
vminor=$(grep 'kDeskTopVersionMinor =' src/config.inc | sed -e 's/.* = //')
vsuffix=$(grep 'define kDeskTopVersionSuffix' src/config.inc | cut -d'"' -f2)
lang=$(grep 'define kBuildLang' src/config.inc | cut -d'"' -f2)
version=$(echo ${vmajor}.${vminor}${vsuffix}-${lang})
supports_lowercase=$(grep 'define kBuildSupportsLowercase' src/config.inc | cut -d' ' -f3)
