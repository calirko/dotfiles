#!/usr/bin/env bash

set -euo pipefail

CACHE_DIR="$HOME/.cache/eww"
CACHE_FILE="$CACHE_DIR/weather"
CACHE_TIME=1200

mkdir -p "$CACHE_DIR"

if [[ -f "$CACHE_FILE" ]]; then
  cache_age=$(( $(date +%s) - $(stat -c%Y "$CACHE_FILE" 2>/dev/null || echo 0) ))
  if (( cache_age < CACHE_TIME )); then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

weather=$(curl -s 'wttr.in/Ivoti,RS,Brazil?format=%c+%t' 2>/dev/null | sed 's/+//g')

if [[ -z "$weather" ]]; then
  weather="N/A"
fi

echo "$weather" > "$CACHE_FILE"
echo "$weather"
