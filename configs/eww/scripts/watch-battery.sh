#!/usr/bin/env bash

# Battery state for the bar.
#
# udev power_supply events alone are not enough: on raccoon the kernel emits
# them for AC plug/unplug but not reliably for capacity ticks, so a pure event
# loop published once at startup and then blocked forever on a silent stream.
# Poll on a timeout for the percentage, and still take udev events so AC
# changes show up instantly instead of waiting out the interval.

INTERVAL=30

build() {
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

last=""
emit() {
    local payload
    payload=$(build)
    [[ "$payload" == "$last" ]] && return
    last=$payload
    printf '%s\n' "$payload"
}

emit

# read -t gives us the poll interval; anything arriving on the monitor wakes us
# early. stdbuf keeps udevadm from block-buffering its output into the pipe.
stdbuf -oL udevadm monitor --subsystem-match=power_supply --udev 2>/dev/null | while true; do
    read -r -t "$INTERVAL" _
    rc=$?
    emit
    # rc 0 = event, rc > 128 = interval elapsed, rc 1 = monitor died. In the
    # last case read returns instantly, so pace ourselves or we'd spin.
    (( rc == 1 )) && sleep "$INTERVAL"
done
