#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"
step="${2:-1}"

kbd_device=$(brightnessctl --list | awk '/::kbd_backlight/ {print $1; exit}')
if [[ -z "${kbd_device:-}" ]]; then
    notify-send -a "keyboard" -u low "Keyboard Backlight" "No keyboard backlight device found"
    exit 0
fi

case "$action" in
    up)
        brightnessctl -d "$kbd_device" set "${step}+" >/dev/null
        ;;
    down)
        brightnessctl -d "$kbd_device" set "${step}-" >/dev/null
        ;;
    *)
        echo "Usage: $0 {up|down} [step]"
        exit 1
        ;;
esac

percent=$(brightnessctl -d "$kbd_device" -m | awk -F, '{gsub(/%/, "", $4); print $4}')
notify-send -a "keyboard" -u low -h int:value:"$percent" -h string:x-canonical-private-synchronous:kbdbacklight "Keyboard Backlight" "${percent}%"
