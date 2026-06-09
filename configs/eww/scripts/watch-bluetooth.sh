#!/usr/bin/env bash

emit() {
    local state device
    if ! command -v bluetoothctl >/dev/null 2>&1; then
        echo '{"state":"disabled","device":""}'
        return
    fi
    if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        state="disabled"
        device=""
    else
        device=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)
        if [[ -n "$device" ]]; then
            state="connected"
        else
            state="disconnected"
        fi
    fi
    jq -cn --arg state "$state" --arg device "$device" '{state:$state,device:$device}'
}

emit

dbus-monitor --system \
    "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='/org/bluez'" \
    2>/dev/null | grep --line-buffered "PropertiesChanged" | while read -r _; do
    emit
done
