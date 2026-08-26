#!/bin/bash
set -uo pipefail

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
CACHE_FILE="$HOME/.cache/current-wallpaper"

mkdir -p "$WALLPAPER_DIR"

# Generate list with img: syntax for previews
wallpaper_list=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -printf "img:%p:text:%f\n")

# Use wofi to select a wallpaper with image previews
selected=$(printf '%s\n' "$wallpaper_list" | wofi --dmenu --allow-images --prompt "Select Wallpaper")

[[ -z "$selected" ]] && exit 0

filename="${selected#*text:}"
WP_PATH="$WALLPAPER_DIR/$filename"

echo "$WP_PATH" > "$CACHE_FILE"

"$HOME/.config/hypr/scripts/wallpaper-apply.sh" "$WP_PATH"
