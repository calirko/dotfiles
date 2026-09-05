#!/usr/bin/env bash
set -euo pipefail

POLL_INTERVAL=5

_active_vpn() {
    nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
        | awk -F: '$2 == "wireguard" {print $1}' | head -1 || true
}

last=$(_active_vpn)

while true; do
    sleep "$POLL_INTERVAL"
    current=$(_active_vpn)

    if [[ -z "$current" && -n "$last" ]]; then
        notify-send -i "network-vpn" -t 8000 \
            "VPN" "Disconnected from $last"
    elif [[ -n "$current" && -z "$last" ]]; then
        notify-send -i "network-vpn" -t 5000 \
            "VPN" "Connected to $current"
    elif [[ -n "$current" && "$current" != "$last" ]]; then
        notify-send -i "network-vpn" -t 5000 \
            "VPN" "Switched to $current"
    fi

    last="$current"
done
