#!/usr/bin/env bash
set -euo pipefail

NOTIFY_TIMEOUT=5000

_device_name() {
    bluetoothctl info "$1" 2>/dev/null | awk -F': ' '/^\tName:/ {print $2; exit}'
}

_mac_from_path() {
    # /org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF -> AA:BB:CC:DD:EE:FF
    echo "$1" | sed -n 's#.*dev_\([0-9A-Fa-f_]*\)$#\1#p' | tr '_' ':'
}

path=""

dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='/org/bluez'" 2>/dev/null | \
while IFS= read -r line; do
    if [[ "$line" == signal* ]]; then
        path=$(echo "$line" | grep -oP "path=\K[^;]+" || true)
        continue
    fi

    if [[ "$line" == *'"Connected"'* ]]; then
        read -r value_line
        [[ -z "$path" ]] && continue

        mac=$(_mac_from_path "$path")
        [[ -z "$mac" ]] && continue

        name=$(_device_name "$mac")
        name=${name:-$mac}

        if [[ "$value_line" == *"true"* ]]; then
            notify-send -i "bluetooth-active" -t "$NOTIFY_TIMEOUT" \
                "Bluetooth" "Connected to $name"
        elif [[ "$value_line" == *"false"* ]]; then
            notify-send -i "bluetooth-disabled" -t "$NOTIFY_TIMEOUT" \
                "Bluetooth" "Disconnected from $name"
        fi
    fi
done
