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
# Also looks for "Error" lines in stdout, those cause failure too.
function suppress {
    set +e
    local result=$("$@")
    if [ $? -ne 0 ]; then
        cecho red "$result" >&2
        exit 1
    fi
    while read line; do
        if [[ $line == *"Error"* ]]; then
            cecho red "$line" >&2
            exit 1
        fi
    done <<<"$result"
    set -e
}
