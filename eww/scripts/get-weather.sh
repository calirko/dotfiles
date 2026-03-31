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

condition=$(curl -s 'wttr.in/Ivoti,RS,Brazil?format=%C' 2>/dev/null)
temp=$(curl -s 'wttr.in/Ivoti,RS,Brazil?format=%t' 2>/dev/null | sed 's/+//g')

if [[ -z "$condition" || -z "$temp" ]]; then
  result=" N/A"
else
  cond="${condition,,}"
  case "$cond" in
    *"sunny"*|*"clear"*)            icon="" ;;
    *"partly cloudy"*)              icon="" ;;
    *"cloudy"*|*"overcast"*)        icon="" ;;
    *"mist"*|*"fog"*|*"haze"*)     icon="󰖑" ;;
    *"patchy rain"*|*"light rain"*|*"light drizzle"*|*"drizzle"*)
                                    icon="" ;;
    *"heavy rain"*|*"torrential"*)  icon="" ;;
    *"moderate rain"*|*"rain"*)     icon="" ;;
    *"thundery"*|*"thunder"*)       icon="" ;;
    *"snow"*|*"blizzard"*)          icon="󰖘" ;;
    *"sleet"*|*"ice"*|*"freezing"*) icon="󰖒" ;;
    *"windy"*)                      icon="" ;;
    *)                              icon="󰖐" ;;
  esac
  result="$icon    $temp"
fi

echo "$result" > "$CACHE_FILE"
echo "$result"