#!/usr/bin/env bash

EVENTS="$(dirname "$0")/hypr-events.sh"

# The SUPER + S scratch plane (see hyprland.lua). Special workspaces have
# negative ids, so they're reported separately from the numbered list.
SPECIAL="special:magic"

get_workspace_data() {
    ws_json=$(hyprctl workspaces -j)
    workspaces=$(jq -c '[.[] | select(.id > 0) | {id: .id, windows: .windows}] | sort_by(.id)' <<<"$ws_json")
    special=$(jq -c --arg n "$SPECIAL" --argjson mons "$(hyprctl monitors -j)" \
        '{windows: ([.[] | select(.name == $n) | .windows] | add // 0), shown: any($mons[]; .specialWorkspace.name == $n)}' <<<"$ws_json")
    active=$(hyprctl activeworkspace -j | jq -c '.id')
    echo "{\"workspaces\": $workspaces, \"active\": $active, \"special\": $special}"
}

get_workspace_data

"$EVENTS" | while IFS= read -r event; do
    case "$event" in
        "workspace>>"*|"createworkspace>>"*|"destroyworkspace>>"*|"openwindow>>"*|"closewindow>>"*|"movewindow>>"*|"activespecial>>"*)
            get_workspace_data
            ;;
    esac
done
