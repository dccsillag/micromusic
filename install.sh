#!/bin/sh

PREFIX=/usr

inst() {
    SOURCE="src/$1"
    TARGET="$PREFIX/bin/$2"

    test -f "$TARGET" && rm "$TARGET"

    ln -s "$(realpath "$SOURCE")" "$TARGET"
}

set -x

inst daemon.sh mmd
inst music-controller.sh mmc
