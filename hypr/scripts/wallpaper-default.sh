#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
CONF_FILE="$HOME/.config/hypr/hyprpaper.conf"

# Ensure the directory exists
mkdir -p "$WALLPAPER_DIR"

# Find the first wallpaper file (jpg, jpeg, png, gif)
first_wallpaper=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | sort | head -n 1)

if [[ -z "$first_wallpaper" ]]; then
    echo "No wallpaper found in $WALLPAPER_DIR"
    exit 1
fi

WP_PATH="$first_wallpaper"

# Write a clean hyprpaper.conf BEFORE starting hyprpaper
# so it loads correctly on startup
cat > "$CONF_FILE" <<EOF
preload = $WP_PATH
wallpaper = ,$WP_PATH
splash = false
EOF

# Kill any existing hyprpaper instance
killall hyprpaper 2>/dev/null || true
sleep 0.5

# Start hyprpaper in the background
hyprpaper &
disown

# Wait for hyprpaper to initialize
sleep 2

# Set wallpaper dynamically (in case monitors weren't ready at config parse time)
hyprctl hyprpaper preload "$WP_PATH"
hyprctl hyprpaper wallpaper ",$WP_PATH"

echo "Set wallpaper: $WP_PATH"
