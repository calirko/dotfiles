#!/usr/bin/env bash

emit() {
    local has_battery capacity status ac
    if compgen -G "/sys/class/power_supply/BAT*" > /dev/null 2>&1; then
        has_battery=1
        capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
        capacity=${capacity:-0}
        status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
        status=${status:-""}
    else
        has_battery=0
        capacity=0
        status=""
    fi
    ac=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo "0")

    jq -cn \
        --argjson has_battery "$has_battery" \
        --argjson capacity "$capacity" \
        --arg status "$status" \
        --argjson ac "$ac" \
        '{has_battery:$has_battery,capacity:$capacity,status:$status,ac:$ac}'
}

emit

udevadm monitor --subsystem-match=power_supply --udev 2>/dev/null | while read -r _; do
    emit
done
