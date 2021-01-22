#!/bin/sh

. "$(dirname "$(realpath "$0")")/common.sh"

get_pid() {
    # This assumes that there is only one ffplay process.
    # It may be a good idea to handle the other case as well.
    # Or maybe we can use pgrep's -G flag?
    pgrep ffplay
    return $?
}

has_player() {
    get_pid > /dev/null
    return $?
}

is_paused() {
    # This assumes that there is only one ffplay process.
    # It may be a good idea to handle the other case as well.
    # Or maybe we can use pgrep's -G flag?
    pgrep ffplay -r T > /dev/null
    return $?
}

get_current_track() {
    # This assumes that there is only one ffplay process.
    # It may be a good idea to handle the other case as well.
    # Or maybe we can use pgrep's -G flag?

    TEMPFILE=$(mktemp)
    pgrep -af ffplay | sed 's/[^/]\+\(.\+\)/\1/' > "$TEMPFILE"
    cat "$QUEUE_FILE" >> "$TEMPFILE"

    remove_common_path_prefix "$TEMPFILE"
    head -1 "$TEMPFILE"

    rm "$TEMPFILE"
}

pause() {
    kill -STOP "$(get_pid)"
}

resume_play() {
    kill -CONT "$(get_pid)"
}

next_track() {
    kill "$(get_pid)"
}

stop() {
    PID="$(get_pid)"
    test -z $PID && return
    is_paused && kill -CONT "$PID"
    kill "$PID"
}

status() {
    has_player || { echo 'Nothing is playing.' && exit 0; }

    is_paused && echo 'Player is paused!' || echo "Currently playing: $(get_current_track)"

    echo "There are $(cat "$QUEUE_FILE" | wc -l) more tracks in the queue."
}

case "$1" in
    # prepend) TODO ;;
    append)
        if   [ -f "$2" ]; then
            echo "$(realpath "$2")" >> "$QUEUE_FILE"
        elif [ -d "$2" ]; then
            for path in "$2"/*
            do
                "$0" append "$path"
            done
        else
            echo "No such file: $2" 1>&2
            exit 2
        fi
        ;;
    play)     is_paused && resume_play ;;
    pause)    pause ;;
    toggle)   is_paused && "$0" play || "$0" pause ;;
    next)     is_paused && resume_play; next_track ;;
    stop)     stop && rm "$QUEUE_FILE" && touch "$QUEUE_FILE" ;;
    getqueue) cat "$QUEUE_FILE" ;;
    status)   status ;;
    list)     TEMPFILE=$(mktemp) \
                && cp -f "$QUEUE_FILE" "$TEMPFILE" \
                && remove_common_path_prefix "$TEMPFILE" \
                && cat "$TEMPFILE" \
                && rm "$TEMPFILE"
                ;;
    *)        echo "Bad command: $1" && exit 2 ;;
esac
