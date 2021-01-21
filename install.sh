#!/bin/sh

PREFIX=/usr

ln -s "$(realpath src/daemon.sh)"           "$PREFIX/bin/mmd"
ln -s "$(realpath src/music-controller.sh)" "$PREFIX/bin/mmc"
