#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
CACHE_FILE="$HOME/.cache/current-wallpaper"

# Ensure the directory exists
mkdir -p "$WALLPAPER_DIR"

# Use last-selected wallpaper if cached, otherwise fall back to first alphabetically
if [[ -f "$CACHE_FILE" ]]; then
    cached=$(cat "$CACHE_FILE")
    if [[ -f "$cached" ]]; then
        WP_PATH="$cached"
    fi
fi

if [[ -z "${WP_PATH:-}" ]]; then
    first_wallpaper=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | sort | head -n 1)
    if [[ -z "$first_wallpaper" ]]; then
        echo "No wallpaper found in $WALLPAPER_DIR"
        exit 1
    fi
    WP_PATH="$first_wallpaper"
fi

"$HOME/.config/hypr/scripts/wallpaper-apply.sh" "$WP_PATH"

echo "Set wallpaper: $WP_PATH"
