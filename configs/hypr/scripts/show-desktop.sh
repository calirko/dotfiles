#!/usr/bin/env bash
set -uo pipefail

# Windows-style "show desktop" toggle for Hyprland.
#
# Hyprland has no native minimize/show-desktop dispatcher, and the
# classic `hyprctl dispatch movetoworkspacesilent WORKSPACE,address:ADDR`
# CLI syntax no longer works on this Lua-config fork (`hyprctl dispatch`
# now evaluates its argument as Lua and expects an HL.Dispatcher
# expression, e.g. `hl.dsp.window.move({...})`, not the old two-arg
# dispatcher/args string, and there's no "silent" option on window.move —
# moving a window always follows/shows its destination). So this drives
# window moves through `hyprctl repl`, calling hl.dsp.window.move()
# directly, and works *with* the follow behavior instead of around it:
#
# - Hide: every window visible on any monitor's active workspace gets
#   moved into a shared special workspace. Hyprland auto-opens a special
#   workspace as an overlay on whichever monitor last received a window —
#   so right after stashing everything, toggle_special closes that
#   overlay again, leaving the windows parked out of sight (a special
#   workspace isn't rendered anywhere while closed).
# - Show: each window is moved back to the plain workspace it was
#   remembered as coming from; the same follow behavior is what makes
#   each monitor redisplay its original workspace correctly here.

STATE_FILE="$HOME/.cache/hypr-show-desktop"
SPECIAL_NAME="desktop_hidden"

if [[ -s "$STATE_FILE" ]]; then
    # Restore: put every remembered window back on its original workspace.
    lua_moves=""
    while IFS=' ' read -r address workspace; do
        [[ -z "$address" ]] && continue
        lua_moves+="hl.dispatch(hl.dsp.window.move({workspace = \"${workspace}\", window = hl.get_window(\"address:${address}\")}));"
    done < "$STATE_FILE"

    if [[ -n "$lua_moves" ]]; then
        hyprctl repl "$lua_moves" >/dev/null 2>&1
    fi

    : > "$STATE_FILE"
else
    # Hide: stash every window on a currently-visible workspace.
    visible_workspaces=$(hyprctl monitors -j | jq -c '[.[].activeWorkspace.id]')

    hyprctl clients -j | jq -r --argjson visible "$visible_workspaces" '
        .[] | select(.workspace.id as $w | $visible | index($w) != null) | "\(.address) \(.workspace.id)"
    ' > "$STATE_FILE"

    lua_moves=""
    while IFS=' ' read -r address workspace; do
        [[ -z "$address" ]] && continue
        lua_moves+="hl.dispatch(hl.dsp.window.move({workspace = \"special:${SPECIAL_NAME}\", window = hl.get_window(\"address:${address}\")}));"
    done < "$STATE_FILE"

    if [[ -n "$lua_moves" ]]; then
        # Close the overlay that got auto-opened by the moves above, so
        # the stashed windows are actually out of sight.
        lua_moves+="hl.dispatch(hl.dsp.workspace.toggle_special(\"${SPECIAL_NAME}\"));"
        hyprctl repl "$lua_moves" >/dev/null 2>&1
    fi
fi
