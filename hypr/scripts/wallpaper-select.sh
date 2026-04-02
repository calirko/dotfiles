#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
CROP_DIR="$HOME/.cache/hyprpaper-spans"
CONF_FILE="$HOME/.config/hypr/hyprpaper.conf"

mkdir -p "$WALLPAPER_DIR" "$CROP_DIR"
rm -f "$CROP_DIR"/*

# ── Select wallpaper via wofi ────────────────────────────────────
wallpaper_list=$(find "$WALLPAPER_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -printf "img:%p:text:%f\n")

selected=$(echo "$wallpaper_list" | wofi --dmenu --allow-images --prompt "Select Wallpaper")
[[ -z "$selected" ]] && exit 0

filename="${selected#*text:}"
WP_PATH="$WALLPAPER_DIR/$filename"

# ── Gather active monitor geometry ───────────────────────────────
monitors=$(hyprctl monitors -j | jq '[.[] | select(.disabled == false)]')

readarray -t names      < <(echo "$monitors" | jq -r '.[].name')
readarray -t pos_x      < <(echo "$monitors" | jq -r '.[].x')
readarray -t pos_y      < <(echo "$monitors" | jq -r '.[].y')
readarray -t res_w      < <(echo "$monitors" | jq -r '.[].width')
readarray -t res_h      < <(echo "$monitors" | jq -r '.[].height')
readarray -t scales     < <(echo "$monitors" | jq -r '.[].scale')
readarray -t transforms < <(echo "$monitors" | jq -r '.[].transform')

# ── Compute logical sizes & canvas bounding box ─────────────────
min_x=999999 min_y=999999 max_r=-999999 max_b=-999999
declare -a log_w log_h

for i in "${!names[@]}"; do
    t=${transforms[$i]}
    if (( t % 2 == 1 )); then
        raw_w=${res_h[$i]}; raw_h=${res_w[$i]}
    else
        raw_w=${res_w[$i]}; raw_h=${res_h[$i]}
    fi

    log_w[$i]=$(awk "BEGIN {printf \"%d\", $raw_w / ${scales[$i]}}")
    log_h[$i]=$(awk "BEGIN {printf \"%d\", $raw_h / ${scales[$i]}}")

    x=${pos_x[$i]}; y=${pos_y[$i]}
    (( x < min_x )) && min_x=$x
    (( y < min_y )) && min_y=$y
    r=$(( x + log_w[i] )); b=$(( y + log_h[i] ))
    (( r > max_r )) && max_r=$r
    (( b > max_b )) && max_b=$b
done

canvas_w=$(( max_r - min_x ))
canvas_h=$(( max_b - min_y ))

# ── Scale wallpaper to cover the entire canvas ──────────────────
resized="$CROP_DIR/_spanned.png"
magick "$WP_PATH" \
    -resize "${canvas_w}x${canvas_h}^" \
    -gravity center \
    -extent "${canvas_w}x${canvas_h}" \
    "$resized"

# ── Crop per-monitor slices, build config, apply via IPC ────────
{
    echo "splash = false"
    echo "ipc = true"
    echo ""
} > "$CONF_FILE"

for i in "${!names[@]}"; do
    ox=$(( pos_x[i] - min_x ))
    oy=$(( pos_y[i] - min_y ))
    crop="$CROP_DIR/${names[$i]}.png"

    # Crop this monitor's logical region from the canvas
    magick "$resized" \
        -crop "${log_w[$i]}x${log_h[$i]}+${ox}+${oy}" +repage \
        "$crop"

    # Write wallpaper block to config
    cat >> "$CONF_FILE" <<EOF
wallpaper {
    monitor = ${names[$i]}
    path = $crop
    fit_mode = fill
}

EOF

    # Apply immediately via IPC
    hyprctl hyprpaper wallpaper "${names[$i]}, $crop, fill"
done
 
# kill and start hyprpaper
pkill -x hyprpaper
hyprpaper &