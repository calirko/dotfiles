#!/bin/bash
set -uo pipefail

# Toggles between mirroring the wallpaper on every monitor and spanning one
# image across the whole layout, then re-applies the current wallpaper.

MODE_FILE="$HOME/.cache/wallpaper-mode"

if [[ "$(cat "$MODE_FILE" 2>/dev/null)" == "span" ]]; then
    mode="mirror"
    label="Same image on every monitor"
else
    mode="span"
    label="One image spanned across monitors"
fi

echo "$mode" > "$MODE_FILE"

"$HOME/.config/hypr/scripts/wallpaper-default.sh" >/dev/null
notify-send -i "preferences-desktop-wallpaper" -t 2000 "Wallpaper" "$label"
