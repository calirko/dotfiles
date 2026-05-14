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

# eww OSD
~/.config/hypr/scripts/osd-show.sh osd-Brightness 2.5
