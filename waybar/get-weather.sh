#!/bin/bash

# Weather script for Waybar
# Fetches weather and caches it for 20 minutes

CACHE_DIR="$HOME/.cache/waybar"
CACHE_FILE="$CACHE_DIR/weather"
CACHE_TIME=1200  # 20 minutes in seconds

mkdir -p "$CACHE_DIR"

# Check if cache exists and is recent
if [ -f "$CACHE_FILE" ]; then
    CACHE_AGE=$(($(date +%s) - $(stat -c%Y "$CACHE_FILE" 2>/dev/null || date -r "$CACHE_FILE" +%s 2>/dev/null || echo 0)))
    if [ "$CACHE_AGE" -lt "$CACHE_TIME" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Fetch new weather data
WEATHER=$(curl -s 'wttr.in/Ivoti,RS,Brazil?format=%c+%t' 2>/dev/null | sed 's/+//g')

if [ -z "$WEATHER" ]; then
    WEATHER="  N/A"
fi

# Cache the result
echo "$WEATHER" > "$CACHE_FILE"
echo "$WEATHER"
