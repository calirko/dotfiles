#!/usr/bin/env bash

# User picture for the bar button and menu header. Drop any square image at
# ~/.face to set it; until then a glyph stands in.
for f in "$HOME/.face" "$HOME/.face.icon" "/var/lib/AccountsService/icons/$USER"; do
    if [[ -r "$f" ]]; then
        jq -nc --arg p "$f" '{path: $p, fallback: false}'
        exit 0
    fi
done
jq -nc --arg p "$HOME/.config/eww/icons/user.svg" '{path: $p, fallback: true}'
