#!/usr/bin/env bash

SIG="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/1000/hypr/ 2>/dev/null | grep -v '\.lock' | head -1)}"
SOCK="/run/user/1000/hypr/${SIG}/.socket2.sock"

emit() {
    hyprctl getoption input:kb_layout 2>/dev/null | head -1 | awk '{print $NF}'
}

emit

socat -u UNIX-CONNECT:"$SOCK" STDOUT | while IFS= read -r event; do
    case "$event" in
        "activelayout>>"*) emit ;;
    esac
done
