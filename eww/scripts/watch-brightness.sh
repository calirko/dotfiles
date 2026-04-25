#!/usr/bin/env bash

# Find the brightness path
BRIGHTNESS_PATH=$(find /sys/class/backlight -name "brightness" 2>/dev/null | head -n1)
MAX_BRIGHTNESS_PATH=$(find /sys/class/backlight -name "max_brightness" 2>/dev/null | head -n1)

get_brightness_data() {
    if [[ -r "$BRIGHTNESS_PATH" && -r "$MAX_BRIGHTNESS_PATH" ]]; then
        has_brightness="\"1\""
        brightness_raw=$(cat "$BRIGHTNESS_PATH" 2>/dev/null || echo "0")
        brightness_max=$(cat "$MAX_BRIGHTNESS_PATH" 2>/dev/null || echo "100")
    else
        has_brightness="\"0\""
        brightness_raw="0"
        brightness_max="100"
    fi

    echo "{\"has_brightness\": $has_brightness, \"brightness_raw\": $brightness_raw, \"brightness_max\": $brightness_max}"
}

get_brightness_data

# Only watch if brightness file exists
if [[ -r "$BRIGHTNESS_PATH" ]]; then
    # Watch for file modifications
    inotifywait -m -e modify "$BRIGHTNESS_PATH" --format '%e %w%f' 2>/dev/null | while read -r event file; do
        echo "GOT: $event on $file" >&2
        get_brightness_data
    done
else
    echo "No brightness control found, exiting" >&2
fi

echo "DIED" >&2
