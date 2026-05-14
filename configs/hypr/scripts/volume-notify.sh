#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
step="${2:-5%}"

case "$action" in
    up)   wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "${step}+" ;;
    down) wpctl set-volume    @DEFAULT_AUDIO_SINK@ "${step}-"  ;;
    mute) wpctl set-mute      @DEFAULT_AUDIO_SINK@ toggle      ;;
    *)
        echo "Usage: $0 {up|down|mute} [step]"
        exit 1
        ;;
esac

muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q '\[MUTED\]' && echo yes || echo no)
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2 * 100}')

# eww OSD
~/.config/hypr/scripts/osd-show.sh osd-volume 2.5
