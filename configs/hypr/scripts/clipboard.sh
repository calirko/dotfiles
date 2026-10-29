#!/usr/bin/env bash

# Clipboard history picker: cliphist entries in wofi, with image entries shown
# as thumbnails instead of "[[ binary data ... ]]". The pick is copied back.

cache=${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbs
mkdir -p "$cache"

list() {
    local line id rest
    while IFS= read -r line; do
        if [[ $line =~ ^([0-9]+)[[:space:]]+\[\[\ binary\ data\ (.*)\ \]\]$ ]]; then
            id=${BASH_REMATCH[1]}
            rest=${BASH_REMATCH[2]}
            [[ -f $cache/$id.png ]] || printf '%s\n' "$line" | cliphist decode >"$cache/$id.png"
            printf 'img:%s:text:%s\t%s\n' "$cache/$id.png" "$id" "$rest"
        else
            printf '%s\n' "$line"
        fi
    done < <(cliphist list)
}

choice=$(list | ~/.config/hypr/scripts/wofi.sh --dmenu --allow-images --image_size 56 --cache-file /dev/null) || exit 0
[[ -n $choice ]] && printf '%s\n' "$choice" | cliphist decode | wl-copy
