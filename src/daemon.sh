#!/bin/sh

. "$(dirname "$0")/common.sh"

DOWNTIME=1

while true
do
    next_track="$(head -1 "$QUEUE_FILE" 2> /dev/null)"

    if [ -n "$next_track" ]
    then
        echo "[INFO] Play: $next_track"
        sed -i 1d "$QUEUE_FILE"
        ffplay -nodisp -hide_banner -nostats "$next_track"
    fi

    sleep "$DOWNTIME"
done
