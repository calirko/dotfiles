#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Ensure the directory exists
mkdir -p "$WALLPAPER_DIR"

# Use wofi to select a wallpaper
selected=$(ls -1 "$WALLPAPER_DIR" | wofi --dmenu --prompt "Select Wallpaper")

if [[ -n "$selected" ]]; then
    WP_PATH="$WALLPAPER_DIR/$selected"
    
    # Load and set wallpaper dynamically
    hyprctl hyprpaper preload "$WP_PATH"
    hyprctl hyprpaper wallpaper ",$WP_PATH"
    
    # Update hyprpaper.conf to persist the change
    CONF_FILE="$(dirname "$0")/hyprpaper.conf"
    sed -i "s|^preload = .*|preload = $WP_PATH|" "$CONF_FILE"
    sed -i "s|^wallpaper = .*|wallpaper = ,$WP_PATH|" "$CONF_FILE"
fi
