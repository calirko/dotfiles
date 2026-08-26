#!/bin/bash
set -uo pipefail

# Applies an image as the wallpaper via hyprpaper.
#
# The same image is used on every monitor: for each monitor, the source is
# cropped to that monitor's exact aspect ratio (highest quality resampling
# ffmpeg offers, lanczos) and scaled to its logical resolution, so each
# monitor shows the same crop of the image at native sharpness.
#
# Usage: wallpaper-apply.sh <path-to-image>

WP_PATH="$1"
CONF_FILE="$HOME/.config/hypr/hyprpaper.conf"
CROP_DIR="$HOME/.cache/hypr-wallpaper-crop"

mkdir -p "$CROP_DIR"
rm -f "$CROP_DIR"/*.png

monitors_json=$(hyprctl monitors -j 2>/dev/null)
monitor_count=$(jq 'length' <<<"${monitors_json:-[]}" 2>/dev/null || echo 0)

assignments=()

if [[ "$monitor_count" -ge 1 ]]; then
    while IFS= read -r mon; do
        name=$(jq -r '.name' <<<"$mon")
        transform=$(jq -r '.transform' <<<"$mon")
        scale=$(jq -r '.scale' <<<"$mon")
        mw_raw=$(jq -r '.width' <<<"$mon")
        mh_raw=$(jq -r '.height' <<<"$mon")

        if (( transform % 2 == 1 )); then
            lw_raw=$mh_raw
            lh_raw=$mw_raw
        else
            lw_raw=$mw_raw
            lh_raw=$mh_raw
        fi

        read -r lw lh <<<"$(awk -v lw="$lw_raw" -v lh="$lh_raw" -v scale="$scale" \
            'BEGIN { printf "%d %d", lw/scale, lh/scale }')"

        crop_path="$CROP_DIR/${name}.png"
        # Crop to the monitor's aspect ratio first (centered), then scale to
        # its exact resolution in one lanczos pass, so no double-resampling.
        ffmpeg -y -v error -i "$WP_PATH" -vf \
            "crop='min(iw,ih*(${lw}/${lh}))':'min(ih,iw*(${lh}/${lw}))',scale=${lw}:${lh}:flags=lanczos" \
            "$crop_path" </dev/null

        assignments+=("${name},${crop_path},cover")
    done < <(jq -c '.[]' <<<"$monitors_json")
fi

# No monitor info available: hyprpaper's own cover fit already does the
# right thing with the raw image.
if [[ ${#assignments[@]} -eq 0 ]]; then
    assignments=(",$WP_PATH,cover")
fi

# Write a clean hyprpaper.conf so the layout is also correct on the next
# full restart/boot, without depending on this script having run first.
{
    for a in "${assignments[@]}"; do
        IFS=',' read -r mon path fit <<<"$a"
        echo "wallpaper {"
        echo "    monitor = $mon"
        echo "    path = $path"
        echo "    fit_mode = $fit"
        echo "}"
    done
    echo "splash = false"
} > "$CONF_FILE"

if ! pgrep -x hyprpaper >/dev/null; then
    hyprpaper &>/dev/null &
    disown
fi

# Retry instead of guessing a fixed delay: apply as soon as hyprpaper's IPC
# is actually ready, so the new wallpaper shows up on the first selection.
hyprctl_retry() {
    local tries=0
    until hyprctl hyprpaper "$@" >/dev/null 2>&1; do
        tries=$((tries + 1))
        (( tries >= 50 )) && return 1
        sleep 0.1
    done
}

for a in "${assignments[@]}"; do
    hyprctl_retry wallpaper "$a"
done
