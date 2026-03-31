#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Ensure the directory exists
mkdir -p "$WALLPAPER_DIR"

# Find the first wallpaper file (jpg, jpeg, png, gif)
first_wallpaper=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | head -n 1)

if [[ -n "$first_wallpaper" ]]; then
    WP_PATH="$first_wallpaper"
    
    # Load and set wallpaper dynamically
    hyprctl hyprpaper preload "$WP_PATH"
    hyprctl hyprpaper wallpaper ",$WP_PATH"
    
    # Update hyprpaper.conf to persist the change
    CONF_FILE="$(dirname "$0")/hyprpaper.conf"
    sed -i "s|^preload = .*|preload = $WP_PATH|" "$CONF_FILE"
    sed -i "s|^wallpaper = .*|wallpaper = ,$WP_PATH|" "$CONF_FILE"
    
    echo "Set wallpaper: $WP_PATH"
else
    echo "No wallpaper found in $WALLPAPER_DIR"
fi