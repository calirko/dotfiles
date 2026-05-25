#!/usr/bin/env bash
set -euo pipefail

NOTIFY_TIMEOUT=5000
SIGNAL_POLL=30
SIGNAL_WARN_THRESHOLD=25
_last_signal_bad=""

_dev_type() {
    case "$1" in
        wl*) echo "wifi" ;;
        en*|eth*) echo "ethernet" ;;
        *) echo "other" ;;
    esac
}

_wifi_ssid() {
    nmcli -t -f active,ssid dev wifi 2>/dev/null \
        | awk -F: '/^yes/ {print $2}' | head -1 || true
}

_signal_monitor() {
    while true; do
        sleep "$SIGNAL_POLL"
        local signal
        signal=$(nmcli -t -f IN-USE,SIGNAL dev wifi list 2>/dev/null \
            | awk -F: '/^\*/ {print $2}' | head -1 || true)

        if [[ -z "$signal" ]]; then
            _last_signal_bad=""
            continue
        fi

        if (( signal < SIGNAL_WARN_THRESHOLD )); then
            if [[ "$_last_signal_bad" != "1" ]]; then
                notify-send -i "network-wireless" -u critical \
                    -t 8000 "Network" "Weak WiFi signal: ${signal}%"
                _last_signal_bad="1"
            fi
        else
            _last_signal_bad=""
        fi
    done
}

_signal_monitor &

nmcli monitor 2>/dev/null | while IFS= read -r line; do
    dev=$(echo "$line" | awk '{print $1}' | tr -d ':')
    type=$(_dev_type "$dev")

    case "$type" in
        wifi)
            if echo "$line" | grep -q "connected" && ! echo "$line" | grep -q "disconnected"; then
                ssid=$(_wifi_ssid)
                notify-send -i "network-wireless" -t "$NOTIFY_TIMEOUT" \
                    "Network" "Connected to ${ssid:-WiFi}"
            elif echo "$line" | grep -q "disconnected"; then
                notify-send -i "network-wireless-disconnected" -t "$NOTIFY_TIMEOUT" \
                    "Network" "WiFi disconnected"
            fi
            ;;
        ethernet)
            if echo "$line" | grep -q "connected" && ! echo "$line" | grep -q "disconnected"; then
                notify-send -i "network-wired" -t "$NOTIFY_TIMEOUT" \
                    "Network" "Ethernet connected"
            elif echo "$line" | grep -q "disconnected"; then
                notify-send -i "network-wired-unavailable" -t "$NOTIFY_TIMEOUT" \
                    "Network" "Ethernet disconnected"
            fi
            ;;
    esac
done
