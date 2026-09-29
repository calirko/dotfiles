#!/usr/bin/env bash

# Open a TUI (nmtui, bluetui, btop) in a floating kitty from the quick menu.
#
# Usage: open-tui.sh <command> [args...]
#
# The kitty class is tui.<command>; hyprland.lua floats and centers every
# tui.* window. If that TUI is already open, focus it instead of opening a
# second one. The menu closes either way so the terminal isn't behind it.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
class="tui.$1"

"$SCRIPT_DIR/close-menu.sh" >/dev/null 2>&1

if hyprctl clients -j | jq -e --arg c "$class" 'any(.[]; .class == $c)' >/dev/null; then
  # Lua config, so dispatch takes Lua (and the regex escape is doubled).
  hyprctl dispatch "hl.dsp.focus({ window = \"class:^${class//./\\\\.}\$\" })" >/dev/null
else
  setsid -f kitty --class "$class" -e "$@" >/dev/null 2>&1
fi
