#!/usr/bin/env bash

EVENTS="$(dirname "$0")/hypr-events.sh"

# The SUPER + S scratch plane (see hyprland.lua). Special workspaces have
# negative ids, so they're reported separately from the numbered list.
SPECIAL="special:magic"

# Workspaces aren't pinned to monitors, so the bar only shows the stack on
# its own monitor (get-screen.sh name), and "active" is that monitor's
# active workspace even while another monitor has focus.
get_workspace_data() {
    ws_json=$(hyprctl workspaces -j)
    mons_json=$(hyprctl monitors -j)
    mon=$("$(dirname "$0")/get-screen.sh" name 2>/dev/null)
    [[ -z "$mon" ]] && mon=$(jq -r '.[0].name' <<<"$mons_json")
    workspaces=$(jq -c --arg m "$mon" '[.[] | select(.id > 0 and .monitor == $m) | {id: .id, windows: .windows}] | sort_by(.id)' <<<"$ws_json")
    special=$(jq -c --arg n "$SPECIAL" --argjson mons "$mons_json" \
        '{windows: ([.[] | select(.name == $n) | .windows] | add // 0), shown: any($mons[]; .specialWorkspace.name == $n)}' <<<"$ws_json")
    active=$(jq -c --arg m "$mon" '[.[] | select(.name == $m) | .activeWorkspace.id][0] // 1' <<<"$mons_json")
    echo "{\"workspaces\": $workspaces, \"active\": $active, \"special\": $special}"
}

get_workspace_data

"$EVENTS" | while IFS= read -r event; do
    case "$event" in
        "workspace>>"*|"focusedmon>>"*|"createworkspace>>"*|"destroyworkspace>>"*|"moveworkspace>>"*|"openwindow>>"*|"closewindow>>"*|"movewindow>>"*|"activespecial>>"*|"monitoradded>>"*|"monitorremoved>>"*)
            get_workspace_data
            ;;
    esac
done
