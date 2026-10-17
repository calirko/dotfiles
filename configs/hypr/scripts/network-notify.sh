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

# Last known state per device. nmcli monitor reports every transition,
# including retry loops on devices that never come up (e.g. a Quest
# headset's USB NCM link failing DHCP every 45s emits "disconnected" each
# cycle). Only notify when a device actually goes connected <-> disconnected.
declare -A _state

# Seed with current state so startup doesn't fire spurious notifications.
while IFS=: read -r dev _ state; do
    [[ "$state" == "connected" ]] && _state[$dev]="up" || _state[$dev]="down"
done < <(nmcli -t -f DEVICE,TYPE,STATE dev status 2>/dev/null || true)

nmcli monitor 2>/dev/null | while IFS= read -r line; do
    dev="${line%%:*}"
    event="${line#*: }"
    type=$(_dev_type "$dev")
    [[ "$type" == "other" ]] && continue

    case "$event" in
        connected) new="up" ;;
        disconnected|unavailable|unmanaged|"device removed") new="down" ;;
        *) continue ;;
    esac

    old="${_state[$dev]:-down}"
    _state[$dev]="$new"
    [[ "$old" == "$new" ]] && continue

    case "$type:$new" in
        wifi:up)
            ssid=$(_wifi_ssid)
            notify-send -i "network-wireless" -t "$NOTIFY_TIMEOUT" \
                "Network" "Connected to ${ssid:-WiFi}"
            ;;
        wifi:down)
            notify-send -i "network-wireless-disconnected" -t "$NOTIFY_TIMEOUT" \
                "Network" "WiFi disconnected"
            ;;
        ethernet:up)
            notify-send -i "network-wired" -t "$NOTIFY_TIMEOUT" \
                "Network" "Ethernet connected"
            ;;
        ethernet:down)
            notify-send -i "network-wired-unavailable" -t "$NOTIFY_TIMEOUT" \
                "Network" "Ethernet disconnected"
            ;;
    esac
done
