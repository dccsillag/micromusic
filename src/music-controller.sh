#!/bin/sh

. "$(dirname "$(realpath "$0")")/common.sh"

get_pid() {
    # This assumes that there is only one ffplay process.
    # It may be a good idea to handle the other case as well.
    # Or maybe we can use pgrep's -G flag?
    pgrep ffplay
    return $?
}

is_paused() {
    # This assumes that there is only one ffplay process.
    # It may be a good idea to handle the other case as well.
    # Or maybe we can use pgrep's -G flag?
    pgrep ffplay -r T > /dev/null
    return $?
}

pause() {
    kill -TSTP "$(get_pid)"
}

resume_play() {
    kill -CONT "$(get_pid)"
}

stop() {
    PID="$(get_pid)"
    test -z $PID && return
    is_paused && kill -CONT "$PID"
    kill "$PID"
}

case "$1" in
    # prepend) TODO ;;
    append)  echo "$(realpath "$2")" >> "$QUEUE_FILE" ;;
    play)    is_paused && resume_play ;;
    pause)   pause ;;
    toggle)  is_paused && "$0" play || "$0" pause ;;
    stop)    stop && rm "$QUEUE_FILE" && touch "$QUEUE_FILE" ;;
esac
