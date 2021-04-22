#!/bin/sh

. "$(dirname "$(realpath "$0")")/common.sh"

DOWNTIME=1
BETWEENTIME=10


play() {
    case "$1" in
        *.stream) ffplay -nodisp -hide_banner -nostats -autoexit "$(cat $1)" ;;
        *)        ffplay -nodisp -hide_banner -nostats -autoexit "$1"        ;;
    esac
}

while true
do
    next_track="$(head -1 "$QUEUE_FILE" 2> /dev/null)"

    if [ -n "$next_track" ]
    then
        echo "[INFO] Play: $next_track"
        sed -i 1d "$QUEUE_FILE"
        play "$next_track" && sleep "$BETWEENTIME"
    fi

    sleep "$DOWNTIME"
done
