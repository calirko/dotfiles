#!/usr/bin/env bash

EVENTS="$(dirname "$0")/hypr-events.sh"

emit() {
    hyprctl getoption input:kb_layout 2>/dev/null | head -1 | awk '{print $NF}'
}

emit

"$EVENTS" | while IFS= read -r event; do
    case "$event" in
        "activelayout>>"*) emit ;;
    esac
done
