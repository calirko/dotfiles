#!/usr/bin/env bash

# Run wofi with the eww blur scrim behind it (same look as the quick menu's).
#
# Arguments, stdin and stdout pass straight through, so this also works inside
# dmenu pipelines (cliphist). The scrim is closed however wofi exits: a pick,
# Escape, or a click on the scrim itself (which kills wofi, see menu.yuck).

# eww --screen index of the focused monitor, which is where wofi opens. eww
# numbers monitors by hyprctl id among the enabled ones (see get-screen.sh).
screen=$(hyprctl monitors -j 2>/dev/null \
  | jq '[.[] | select((.disabled // false) == false)] | sort_by(.id) | map(.focused) | index(true) // 0' 2>/dev/null)

eww open wofi_scrim --screen "${screen:-0}" </dev/null >/dev/null 2>&1 &
# `wait` first: if wofi exits before the open lands, closing early would leave
# the scrim stuck on screen.
trap 'wait; eww close wofi_scrim >/dev/null 2>&1' EXIT

wofi "$@"
