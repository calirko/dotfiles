#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

emit() {
    local title artist status art
    title=$(playerctl metadata title 2>/dev/null || true)
    artist=$(playerctl metadata artist 2>/dev/null || true)
    status=$(playerctl status 2>/dev/null || true)
    [[ -z "$status" ]] && status="Stopped"
    if [[ -n "$title" ]]; then
        art=$("$SCRIPT_DIR/media-art-path.sh" 2>/dev/null || true)
    else
        art=""
    fi
    jq -cn \
        --arg title "${title:-}" \
        --arg artist "${artist:-}" \
        --arg status "$status" \
        --arg art "${art:-}" \
        '{title:$title,artist:$artist,status:$status,art:$art}'
}

emit

while true; do
    # --follow exits when the player disappears; loop to re-attach
    playerctl --follow metadata --format '{{playerName}}' 2>/dev/null | while read -r _; do
        emit
    done
    emit  # emit Stopped state when player exits
    sleep 2
done
