QUEUE_FILE="$HOME/.local/share/music-controller/queue"

test -d "$(dirname "$QUEUE_FILE")" || mkdir -p "$(dirname "$QUEUE_FILE")"
test -f "$QUEUE_FILE" || touch "$QUEUE_FILE"
