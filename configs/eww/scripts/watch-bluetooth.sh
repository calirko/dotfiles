#!/usr/bin/env bash

# Emits {state, count, devices:[{mac,name,icon,battery}]}. battery is -1 when
# the device doesn't expose org.bluez.Battery1; icon is a menu icon path.

device_icon() {
    case "$1" in
        audio-headset|audio-headphones|audio-card) echo "icons/headphones.svg" ;;
        input-keyboard) echo "icons/keyboard.svg" ;;
        input-mouse|input-tablet) echo "icons/mouse-simple.svg" ;;
        input-gaming) echo "icons/game-controller.svg" ;;
        phone) echo "icons/device-mobile.svg" ;;
        *) echo "icons/bluetooth.svg" ;;
    esac
}

emit() {
    local state devices="[]"
    if ! command -v bluetoothctl >/dev/null 2>&1; then
        echo '{"state":"disabled","count":0,"devices":[]}'
        return
    fi
    if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        state="disabled"
    else
        devices=$(bluetoothctl devices Connected 2>/dev/null | while read -r _ mac name; do
            info=$(bluetoothctl info "$mac" 2>/dev/null)
            bat=$(sed -n 's/.*Battery Percentage:.*(\([0-9]*\)).*/\1/p' <<<"$info")
            icon=$(device_icon "$(sed -n 's/^\s*Icon: //p' <<<"$info")")
            jq -cn --arg mac "$mac" --arg name "$name" --arg icon "$icon" --arg bat "$bat" \
                '{mac:$mac,name:$name,icon:$icon,battery:($bat|if .=="" then -1 else tonumber end)}'
        done | jq -cs '.')
        if [[ "$devices" != "[]" ]]; then
            state="connected"
        else
            state="disconnected"
        fi
    fi
    jq -cn --arg state "$state" --argjson devices "$devices" \
        '{state:$state,count:($devices|length),devices:$devices}'
}

emit

dbus-monitor --system \
    "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='/org/bluez'" \
    2>/dev/null | grep --line-buffered "PropertiesChanged" | while read -r _; do
    emit
done
