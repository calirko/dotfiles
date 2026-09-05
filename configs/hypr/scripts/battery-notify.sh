#!/usr/bin/env bash
# Low-battery warning — no upower daemon is running (see power-tweaks.sh for
# the udev-driven pattern this follows), so nothing else warns on low charge.
#
# Fires once when capacity drops to/below WARN_THRESHOLD while discharging,
# and re-arms once capacity recovers above RESET_THRESHOLD or AC is plugged in.

set -uo pipefail

WARN_THRESHOLD=20
RESET_THRESHOLD=25
_warned=""

check() {
    local bat capacity status
    bat=$(compgen -G "/sys/class/power_supply/BAT*" 2>/dev/null | head -1) || return
    [[ -n "$bat" ]] || return

    capacity=$(cat "$bat/capacity" 2>/dev/null) || return
    status=$(cat "$bat/status" 2>/dev/null) || return

    if [[ "$status" == "Discharging" && "$capacity" -le "$WARN_THRESHOLD" ]]; then
        if [[ -z "$_warned" ]]; then
            notify-send -i "battery-low" -u critical -t 8000 \
                "Battery low" "${capacity}% remaining — plug in soon"
            _warned="1"
        fi
    elif [[ "$status" != "Discharging" || "$capacity" -ge "$RESET_THRESHOLD" ]]; then
        _warned=""
    fi
}

check

udevadm monitor --subsystem-match=power_supply --udev 2>/dev/null | while read -r _; do
    check
done
