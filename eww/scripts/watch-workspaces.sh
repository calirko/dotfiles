#!/usr/bin/env bash

SIG="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | grep -v '\.lock' | head -1)}"
SOCK="/run/user/1000/hypr/${SIG}/.socket2.sock"

get_workspace_data() {
    workspaces=$(hyprctl workspaces -j | jq -c '[.[] | {id: .id, windows: .windows}] | sort_by(.id)')
    active=$(hyprctl activeworkspace -j | jq -c '.id')
    echo "{\"workspaces\": $workspaces, \"active\": $active}"
}

get_workspace_data

socat -u UNIX-CONNECT:"$SOCK" STDOUT | while IFS= read -r event; do
    echo "GOT: $event" >&2
    case "$event" in
        "workspace>>"*|"createworkspace>>"*|"destroyworkspace>>"*|"openwindow>>"*|"closewindow>>"*|"movewindow>>"*)
            get_workspace_data
            ;;
    esac
done

echo "DIED" >&2
