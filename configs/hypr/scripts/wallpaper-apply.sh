#!/bin/bash
set -uo pipefail

# Applies an image as the wallpaper via hyprpaper.
#
# Two modes, picked by the contents of $MODE_FILE (toggled with
# wallpaper-toggle-span.sh):
#
#   mirror (default) - the same image is used on every monitor: for each
#     monitor, the source is cropped to that monitor's exact aspect ratio
#     (highest quality resampling ffmpeg offers, lanczos) and scaled to its
#     logical resolution, so each monitor shows the same crop of the image
#     at native sharpness.
#
#   span - one image is stretched across the whole monitor layout as if the
#     monitors were windows onto a single canvas. The image is scaled
#     uniformly (never distorted) by the smallest factor that still covers
#     the layout's bounding box, centered, and each monitor gets its slice.
#     Every slice comes from one lanczos pass over the source, and all slices
#     are cut from the same scaled grid, so edges line up pixel-exactly.
#
# Usage: wallpaper-apply.sh <path-to-image>

WP_PATH="$1"
CONF_FILE="$HOME/.config/hypr/hyprpaper.conf"
CROP_DIR="$HOME/.cache/hypr-wallpaper-crop"
MODE_FILE="$HOME/.cache/wallpaper-mode"

mode=$(cat "$MODE_FILE" 2>/dev/null)
[[ "$mode" == "span" ]] || mode="mirror"

mkdir -p "$CROP_DIR"
rm -f "$CROP_DIR"/*.png

monitors_json=$(hyprctl monitors -j 2>/dev/null)
monitor_count=$(jq 'length' <<<"${monitors_json:-[]}" 2>/dev/null || echo 0)

assignments=()

# Logical layout rect of a monitor: "x y w h", with rotation applied.
logical_rect() {
    jq -r '
        (if .transform % 2 == 1 then [.height, .width] else [.width, .height] end) as $wh
        | "\(.x) \(.y) \($wh[0] / .scale | floor) \($wh[1] / .scale | floor)"
    ' <<<"$1"
}

if [[ "$mode" == "span" && "$monitor_count" -ge 1 ]]; then
    read -r img_w img_h <<<"$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=width,height -of csv=p=0:s=x "$WP_PATH" </dev/null | tr x ' ')"

    # Bounding box of the whole layout, in logical pixels.
    read -r bx by bw bh <<<"$(jq -r '
        map(
            (if .transform % 2 == 1 then [.height, .width] else [.width, .height] end) as $wh
            | {x, y, r: (.x + ($wh[0] / .scale | floor)), b: (.y + ($wh[1] / .scale | floor))}
        )
        | (map(.x) | min) as $x | (map(.y) | min) as $y
        | "\($x) \($y) \((map(.r) | max) - $x) \((map(.b) | max) - $y)"
    ' <<<"$monitors_json")"

    while IFS= read -r mon; do
        name=$(jq -r '.name' <<<"$mon")
        scale=$(jq -r '.scale' <<<"$mon")
        read -r mx my lw lh <<<"$(logical_rect "$mon")"

        # Cover-fit: k = max(bw/iw, bh/ih) maps source px -> logical px.
        # Each monitor renders at its own scale, so the whole image is scaled
        # to (iw*k*scale) and the monitor's physical-resolution window is cut
        # out of it, offset by the centering margin of the cover fit.
        read -r sw sh cx cy cw ch <<<"$(awk \
            -v iw="$img_w" -v ih="$img_h" -v bw="$bw" -v bh="$bh" \
            -v bx="$bx" -v by="$by" -v mx="$mx" -v my="$my" \
            -v lw="$lw" -v lh="$lh" -v s="$scale" '
            function round(v) { return int(v + 0.5) }
            BEGIN {
                k = bw / iw; if (bh / ih > k) k = bh / ih
                sw = round(iw * k * s); sh = round(ih * k * s)
                cw = round(lw * s); ch = round(lh * s)
                cx = round(((iw * k - bw) / 2 + (mx - bx)) * s)
                cy = round(((ih * k - bh) / 2 + (my - by)) * s)
                # Guard against rounding pushing the window past the edge.
                if (cx + cw > sw) cx = sw - cw; if (cx < 0) cx = 0
                if (cy + ch > sh) cy = sh - ch; if (cy < 0) cy = 0
                printf "%d %d %d %d %d %d", sw, sh, cx, cy, cw, ch
            }')"

        crop_path="$CROP_DIR/${name}.png"
        ffmpeg -y -v error -i "$WP_PATH" -vf \
            "scale=${sw}:${sh}:flags=lanczos,crop=${cw}:${ch}:${cx}:${cy}" \
            "$crop_path" </dev/null

        assignments+=("${name},${crop_path},cover")
    done < <(jq -c '.[]' <<<"$monitors_json")
elif [[ "$monitor_count" -ge 1 ]]; then
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
