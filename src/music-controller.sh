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

get_current_track_path() {
    # This assumes that there is only one ffplay process.
    # It may be a good idea to handle the other case as well.
    # Or maybe we can use pgrep's -G flag?
    pgrep -af ffplay | sed 's/[^/]\+\(.\+\)/\1/'
}

get_current_track() {
    TEMPFILE=$(mktemp)
    get_current_track_path > "$TEMPFILE"
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

prepend_text() { printf '%s\n%s\n' "$1" "$(cat "$2")" > "$2"; }
append_text()  { echo "$1" >> "$2"; }

recursive_insert() {
    if   [ -f "$1" ]; then
        "$3" "$(realpath "$1")" "$2"
    elif [ -d "$1" ]; then
        ls "$1" | sort $4 | while read -r path
        do
            recursive_insert "$1/$path" "$2" "$3" "$4"
        done
    else
        echo "No such file or directory: $1" 1>&2
        exit 2
    fi
}

case "$1" in
    prepend)  recursive_insert "$2" "$QUEUE_FILE" prepend_text "-r" ;;
    append)   recursive_insert "$2" "$QUEUE_FILE" append_text  ""   ;;
    restart)  prepend_text "$(get_current_track_path)" "$QUEUE_FILE" && "$0" next ;;
    play)     is_paused && resume_play ;;
    pause)    pause ;;
    toggle)   is_paused && "$0" play || "$0" pause ;;
    next)     is_paused && resume_play; next_track ;;
    stop)     stop && rm "$QUEUE_FILE" && touch "$QUEUE_FILE" ;;
    status)   status ;;
    list)     TEMPFILE=$(mktemp) \
                && cp -f "$QUEUE_FILE" "$TEMPFILE" \
                && remove_common_path_prefix "$TEMPFILE" \
                && cat "$TEMPFILE" \
                && rm "$TEMPFILE"
                ;;
    getqueue) cat "$QUEUE_FILE" ;;
    edit)     "${EDITOR:edit}" "$QUEUE_FILE" ;;
    *)        echo "Bad command: $1" && exit 2 ;;
esac
