#!/usr/bin/env bash
# Power-mode tweaks — toggles Hyprland eye-candy based on AC vs battery.
#
# On AC      : blur enabled
# On battery : blur disabled (cheaper compositing, better battery life)
#
# Applies the current state at startup, then reacts to power_supply udev events.
# Autostarted from hyprland.lua.

set -uo pipefail

get_ac_online() {
    for _p in /sys/class/power_supply/AC/online \
              /sys/class/power_supply/AC0/online \
              /sys/class/power_supply/ADP0/online \
              /sys/class/power_supply/ADP1/online; do
        [[ -f "$_p" ]] && cat "$_p" && return
    done
    # No AC device (e.g. desktop) — treat as always plugged in.
    echo "1"
}

apply() {
    local ac blur
    ac=$(get_ac_online)
    if [[ "$ac" == "1" ]]; then
        blur="true"
    else
        blur="false"
    fi

    # Only issue the command when the value actually changes.
    # The config is written in Lua, so `hyprctl keyword` is rejected
    # ("can't work with non-legacy parsers"); set it via the Lua API instead.
    if [[ "$blur" != "${_last_blur:-}" ]]; then
        hyprctl eval "hl.config({decoration={blur={enabled=$blur}}})" >/dev/null 2>&1 || true
        _last_blur="$blur"
    fi
}

_last_blur=""
apply

udevadm monitor --subsystem-match=power_supply --udev 2>/dev/null | while read -r _; do
    apply
done
