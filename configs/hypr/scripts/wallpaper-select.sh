#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
# Ensure the directory exists

mkdir -p "$WALLPAPER_DIR"
# Generate list with img: syntax for previews

wallpaper_list=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -printf "img:%p:text:%f\n")
# Use wofi to select a wallpaper with image previews

selected=$(printf '%s\n' "$wallpaper_list" | wofi --dmenu --allow-images --prompt "Select Wallpaper")

if [[ -n "$selected" ]]; then
   filename="${selected#*text:}"
   WP_PATH="$WALLPAPER_DIR/$filename"

   echo "$WP_PATH" > "$HOME/.cache/current-wallpaper"

   CONF_FILE="$HOME/.config/hypr/hyprpaper.conf"
   cat > "$CONF_FILE" <<EOF
preload = $WP_PATH
wallpaper = ,$WP_PATH
splash = false
EOF

   pkill hyprpaper
   sleep 0.5
   hyprpaper &>/dev/null &
   sleep 1
   hyprctl hyprpaper preload "$WP_PATH"
   hyprctl hyprpaper wallpaper ",$WP_PATH"
fi
