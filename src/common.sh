QUEUE_FILE="$HOME/.local/share/music-controller/queue"

test -d "$(dirname "$QUEUE_FILE")" || mkdir -p "$(dirname "$QUEUE_FILE")"
test -f "$QUEUE_FILE" || touch "$QUEUE_FILE"


remove_common_path_prefix() {
    test -f "$1" || { echo "no such file for remove_common_path_prefix: $1"; exit 2; }

    prefix="$(head -1 "$1" | cut -d/ -f1)"
    n_matches="$(grep -Gc "^$prefix" "$1")" # FIXME: $prefix might be interpreted as a regex
    n_lines="$(cat "$1" | wc -l)"

    if [ "$n_matches" -ne "$n_lines" ] || [ "$n_lines" -le 0 ]
    then
        sed -i 's|^\(.\+\)\.[A-Za-z0-9]\+$|\1|' "$1"
        return 0
    fi

    sed -i 's|^[^/]*/\(.\+\)$|\1|' "$1"
    remove_common_path_prefix "$1"
}
