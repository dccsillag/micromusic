#!/bin/sh

BASE_DIR="$HOME/.local/share/music-controller"
SOCKET_FILE="$BASE_DIR/mpvsocket"

mkdir -p "$BASE_DIR"

remove_common_path_prefix() {
    test -f "$1" || { echo "no such file for remove_common_path_prefix: $1"; exit 2; }

    prefix="$(head -1 "$1" | cut -d/ -f1)"
    n_matches="$(grep -Gc "^$prefix" "$1")" # FIXME: $prefix might be interpreted as a regex
    n_lines="$(cat "$1" | wc -l)"

    test "$n_lines" -eq 1 && basename "$(cat "$1")" > "$1"

    if [ "$n_matches" -ne "$n_lines" ] || [ "$n_lines" -le 1 ]
    then
        sed -i 's|^\(.\+\)\.[A-Za-z0-9]\+$|\1|' "$1"
        return 0
    fi

    sed -i 's|^[^/]*/\(.\+\)$|\1|' "$1"
    remove_common_path_prefix "$1"
}

has_player() {
    test -S "$SOCKET_FILE" \
        && ( echo '{ "command": "print-text hello" }' \
            | socat - ~/.local/share/music-controller/mpvsocket > /dev/null 2>&1 )
}

mpvcmd() {
    has_player || launch_idle_mpv
    cmd="$({ for arg in "$@"; do echo "$arg"; done; } | jq -MRsc 'split("\n")[:-1]')"
    echo "{ \"command\": $cmd }" | socat - "$SOCKET_FILE" | jq -M .data
}

is_paused() {
    case "$(mpvcmd get_property pause)" in
        true) true  ;;
        *)    false ;;
    esac
}

get_current_track_path() {
    mpvcmd get_property path | jq -r
}

get_queue() {
    mpvcmd get_property playlist | jq -r 'map(.filename) | join("\n")'
}

get_current_track() {
    TEMPFILE=$(mktemp)
    get_current_track_path > "$TEMPFILE"
    get_queue >> "$TEMPFILE"

    remove_common_path_prefix "$TEMPFILE"
    head -1 "$TEMPFILE"

    rm "$TEMPFILE"
}

pause() {
    mpvcmd set_property pause yes >/dev/null
}

resume_play() {
    mpvcmd set_property pause no >/dev/null
}

next_track() {
    mpvcmd playlist-next force >/dev/null
}

prev_track() {
    mpvcmd playlist-prev force >/dev/null
}

clear() {
    mpvcmd quit >/dev/null && rm "$SOCKET_FILE"
}

get() {
    case "$1" in
        active) has_player ;;
        status)
            if has_player
            then
                if is_paused
                then
                    echo paused
                else
                    echo playing
                fi
            else
                echo empty
            fi
            ;;
        ninqueue) mpvcmd get_property playlist-count ;;
        queuepos) mpvcmd get_property playlist-pos-1 ;;
        nremaining) total=$(get ninqueue)
                    pos=$(get queuepos)
                    echo $((total - pos))
                    ;;
    esac
}

status() {
    case $(get status) in
        paused)
            echo "Status: paused"
            echo "Currently playing ($(get queuepos)/$(get ninqueue)): $(get_current_track)"
            ;;
        playing)
            echo "Status: playing"
            echo "Currently playing ($(get queuepos)/$(get ninqueue)): $(get_current_track)"
            ;;
        waiting)
            echo "Status: waiting"
            echo
            ;;
        empty)
            echo "Nothing is playing."
            exit 0
            ;;
    esac
    echo "There are $(get nremaining) more tracks in the queue."
}

launch_idle_mpv() {
    echo "[INFO] launching mpv"
    nohup mpv --input-ipc-server="$SOCKET_FILE" --idle=once > /dev/null 2>&1 &
    sleep 1
}

append_track() {
    has_player || launch_idle_mpv

    mpvcmd loadfile "$1" append-play >/dev/null
}

recursive_insert() {
    if   [ -f "$1" ]; then
        "$2" "$(realpath "$1")"
    elif [ -d "$1" ]; then
        ls "$1" | sort $3 | while read -r path
        do
            recursive_insert "$1/$path" "$2" "$3"
        done
    else
        echo "No such file or directory: $1" 1>&2
        exit 2
    fi
}

case "$1" in
    append)   recursive_insert "$2" append_track ""   ;;
    # restart)  prepend_text "$(get_current_track_path)" "$QUEUE_FILE" && "$0" next ;;
    play)     is_paused && resume_play ;;
    pause)    pause ;;
    toggle)   is_paused && "$0" play || "$0" pause ;;
    next)     is_paused && resume_play; next_track ;;
    prev)     is_paused && resume_play; prev_track ;;
    clear)    clear ;;
    status)   status ;;
    get)      get "$2" ;;
    list)     TEMPFILE=$(mktemp)
              get_queue > "$TEMPFILE"
              remove_common_path_prefix "$TEMPFILE"
              sed -i 's/^/    /' "$TEMPFILE"
              sed -i "$(get queuepos)s/^    \(.\+\)$/$(tput bold)--> \1$(tput sgr0)/" "$TEMPFILE"
              cat "$TEMPFILE"
              rm "$TEMPFILE"
              ;;
    *)        echo "Bad command: $1" && exit 2 ;;
esac
