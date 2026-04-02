#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
# Ensure the directory exists

mkdir -p "$WALLPAPER_DIR"
# Generate list with img: syntax for previews

wallpaper_list=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -printf "img:%p:text:%f\n")
# Use wofi to select a wallpaper with image previews

selected=$(printf '%s\n' "$wallpaper_list" | wofi --dmenu --allow-images --prompt "Select Wallpaper")

if [[ -n "$selected" ]]; then
   # Extract filename from selected entry (after "text:")
   filename="${selected#*text:}"
   WP_PATH="$WALLPAPER_DIR/$filename"

   # Get list of monitors
   monitors=$(hyprctl monitors -j | jq -r '.[].name')

   # Build the new configuration
   CONF_FILE="$(dirname "$0")/../hyprpaper.conf"
   config_content="splash = false
ipc = true
"

   # Add wallpaper block for each monitor
   while IFS= read -r monitor; do
      config_content+="
wallpaper {
    monitor = $monitor
    path = $WP_PATH
    fit_mode = cover
}
"
   done <<< "$monitors"

   # Write the new configuration
   echo "$config_content" > "$CONF_FILE"

   # Kill hyprpaper and reload it
   pkill hyprpaper
   sleep 0.5
   hyprpaper &>/dev/null &
fi