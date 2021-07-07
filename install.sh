#!/bin/sh -x

if [ -n "$PREFIX" ]
then
    echo "$PREFIX"
elif [ "$(id -u)" -eq 0 ]
then
    PREFIX=/usr
else
    PREFIX="$HOME/.local"
fi

install micromusic.sh "$PREFIX/bin/mcm"
