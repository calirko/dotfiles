#!/usr/bin/env bash

set -euo pipefail

step="${2:-5%}"
action="${1:-}"

case "$action" in
    up)
        wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ "${step}+"
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}-"
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *)
        echo "Usage: $0 {up|down|mute} [step]"
        exit 1
        ;;
esac

muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q '\[MUTED\]' && echo yes || echo no)
volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%d", $2 * 100}')

if [[ "$muted" == "yes" ]]; then
    notify-send -a "volume" -u low -h string:x-canonical-private-synchronous:volume "Volume" "Muted"
else
    notify-send -a "volume" -u low -h int:value:"$volume" -h string:x-canonical-private-synchronous:volume "Volume" "${volume}%"
fi
