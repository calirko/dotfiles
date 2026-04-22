#!/usr/bin/env bash
SIG="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | grep -v '\.lock' | head -1)}"
SOCK="/run/user/1000/hypr/${SIG}/.socket2.sock"

hyprctl activeworkspace -j | jq -r '.id | tostring'

socat -u UNIX-CONNECT:"$SOCK" STDOUT | while IFS= read -r event; do
    case "$event" in
        "workspace>>"*)
            echo "${event#workspace>>}"
            ;;
    esac
done
