#!/usr/bin/env bash

# Find the brightness path - check common backlight devices
BRIGHTNESS_PATH=""
MAX_BRIGHTNESS_PATH=""

for backlight_dir in /sys/class/backlight/*/; do
    if [[ -r "${backlight_dir}brightness" && -r "${backlight_dir}max_brightness" ]]; then
        BRIGHTNESS_PATH="${backlight_dir}brightness"
        MAX_BRIGHTNESS_PATH="${backlight_dir}max_brightness"
        break
    fi
done

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
    # Watch for file modifications; drain bursts (slider drags, held keys)
    # and re-read once, so the slider never replays stale values.
    inotifywait -m -e modify "$BRIGHTNESS_PATH" 2>/dev/null | while read -r _; do
        while read -r -t 0.03 _; do :; done
        get_brightness_data
    done
fi
