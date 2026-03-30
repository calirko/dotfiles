#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"
step="${2:-5%}"

case "$action" in
    up)
        brightnessctl -e4 -n2 set "${step}+" >/dev/null
        ;;
    down)
        brightnessctl -e4 -n2 set "${step}-" >/dev/null
        ;;
    *)
        echo "Usage: $0 {up|down} [step]"
        exit 1
        ;;
esac

percent=$(brightnessctl -m | awk -F, '{gsub(/%/, "", $4); print $4}')
notify-send -a "brightness" -u low -h int:value:"$percent" -h string:x-canonical-private-synchronous:brightness "Brightness" "${percent}%"
