#!/usr/bin/env bash
set -uo pipefail

# Switch to a workspace from the bar.
#
# `hyprctl dispatch` on this Lua-config fork evaluates its argument as Lua
# and expects an HL.Dispatcher expression — the old CLI form
# (`hyprctl dispatch workspace 3`) is a Lua syntax error and silently does
# nothing, which is why the bar's workspace buttons stopped working.
#
# Takes any Hyprland workspace selector: a numeric id, or a keyword like
# `emptym` (first empty workspace on the current monitor) for the + button.
# `special:<name>` toggles that special workspace instead (like SUPER + S).

# hyprctl needs the instance signature; fill it in if eww's daemon was
# started outside the Hyprland session and didn't inherit it.
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    HYPRLAND_INSTANCE_SIGNATURE=$(ls "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/" 2>/dev/null | grep -v '\.lock' | head -1)
    export HYPRLAND_INSTANCE_SIGNATURE
fi

if [[ "${1:-}" == special:* ]]; then
    exec hyprctl dispatch "hl.dsp.workspace.toggle_special(\"${1#special:}\")"
fi

exec hyprctl dispatch "hl.dsp.focus({ workspace = \"${1:-emptym}\" })"
