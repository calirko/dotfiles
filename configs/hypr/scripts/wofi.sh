#!/usr/bin/env bash

# Run wofi with the eww blur scrim behind it (same look as the quick menu's).
#
# Arguments, stdin and stdout pass straight through, so this also works inside
# dmenu pipelines (cliphist). The scrim is closed however wofi exits: a pick,
# Escape, or a click on the scrim itself (which kills wofi, see menu.yuck).

# One scrim per monitor, so every screen blurs, not just the one wofi is on.
scrim=~/.config/eww/scripts/scrim.sh

"$scrim" open wofi </dev/null >/dev/null 2>&1 &
# `wait` first: if wofi exits before the opens land, closing early would leave
# a scrim stuck on screen.
trap 'wait; "$scrim" close wofi </dev/null >/dev/null 2>&1' EXIT

wofi "$@"
