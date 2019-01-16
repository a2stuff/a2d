function cecho {
    case $1 in
        red)    tput setaf 1 ; shift ;;
        green)  tput setaf 2 ; shift ;;
        yellow) tput setaf 3 ; shift ;;
    esac
    echo -e "$@"
    tput sgr0
}

function do_make {
    make $MAKE_FLAGS "$1" \
        && (cecho green "make $1 good") \
        || (tput blink ; cecho red "MAKE $1 BAD" ; return 1)
}
