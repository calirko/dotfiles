#!/usr/bin/env bash
set -euo pipefail

WINDOW="$1"
DELAY="${2:-2.5}"
PIDFILE="/tmp/eww-osd-${WINDOW}.pid"
MONITOR=$(~/.config/eww/scripts/get-screen.sh)

# only open if not already open
if ! eww active-windows | grep "${WINDOW}$"; then
    eww open "$WINDOW" --screen "$MONITOR"
fi

# cancel previous hide timer
if [[ -f "$PIDFILE" ]]; then
    kill "$(cat "$PIDFILE")" 2>/dev/null || true
    rm -f "$PIDFILE"
fi

# schedule new hide
(sleep "$DELAY" && eww close "$WINDOW" 2>/dev/null || true) &
echo $! > "$PIDFILE"
