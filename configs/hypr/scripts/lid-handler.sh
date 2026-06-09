#!/usr/bin/env bash
# Lid switch handler — raccoon only
#
# Plugged in + external monitor : lid close disables eDP-1, lid open re-enables it
# Plugged in + no external      : lid close suspends
# On battery (any)              : lid close suspends; timeout suspend is handled by hypridle

set -uo pipefail

EDP_NAME="eDP-1"
EDP_MODE="1920x1200@60"
EDP_POS="-1920x0"
EDP_SCALE="1.2"

# Locate lid state file (name varies by hardware: LID, LID0, LID1 …)
LID_STATE_FILE=""
for _f in /proc/acpi/button/lid/*/state; do
    [[ -f "$_f" ]] && LID_STATE_FILE="$_f" && break
done

get_lid_state() {
    [[ -z "$LID_STATE_FILE" ]] && echo "open" && return
    if grep -q "closed" "$LID_STATE_FILE" 2>/dev/null; then
        echo "closed"
    else
        echo "open"
    fi
}

get_ac_online() {
    for _p in /sys/class/power_supply/AC/online \
              /sys/class/power_supply/AC0/online \
              /sys/class/power_supply/ADP0/online \
              /sys/class/power_supply/ADP1/online; do
        [[ -f "$_p" ]] && cat "$_p" && return
    done
    echo "0"
}

hyprctl_cmd() {
    # If the env var is missing (e.g. service started before Hyprland exported it),
    # look up the running instance from the socket directory.
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        local _rt="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        local _sig
        _sig=$(ls "$_rt/hypr/" 2>/dev/null | head -1)
        [[ -z "$_sig" ]] && return 1
        export HYPRLAND_INSTANCE_SIGNATURE="$_sig"
    fi
    hyprctl "$@"
}

get_external_monitor_count() {
    hyprctl_cmd monitors -j 2>/dev/null \
        | jq -r "[.[] | select(.name != \"$EDP_NAME\" and (.disabled // false) == false)] | length" 2>/dev/null \
        || echo "0"
}

reopen_bar() {
    bash "$HOME/.config/hypr/scripts/bar.sh" &
    disown
}

disable_edp() {
    hyprctl_cmd eval "hl.monitor({output=\"$EDP_NAME\", disabled=true})" >/dev/null 2>&1 || true
    reopen_bar
}

enable_edp() {
    hyprctl_cmd eval "hl.monitor({output=\"$EDP_NAME\", disabled=false, mode=\"$EDP_MODE\", position=\"$EDP_POS\", scale=$EDP_SCALE})" >/dev/null 2>&1 || true
    reopen_bar
}

on_lid_close() {
    local _ac _ext
    _ac=$(get_ac_online)
    _ext=$(get_external_monitor_count)

    if [[ "$_ac" == "1" && "$_ext" -gt 0 ]]; then
        disable_edp
    else
        systemctl suspend
    fi
}

on_lid_open() {
    # Brief pause so Hyprland settles after a potential wake-from-suspend.
    sleep 1
    enable_edp
}

# Act on the current state at startup (handles boot-with-lid-closed).
# Wait for Hyprland to finish initializing before issuing hyprctl commands.
wait_for_hyprland() {
    local _rt="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    local _i=0
    while [[ $_i -lt 30 ]]; do
        local _sig
        _sig=$(ls "$_rt/hypr/" 2>/dev/null | head -1)
        if [[ -n "$_sig" ]]; then
            export HYPRLAND_INSTANCE_SIGNATURE="$_sig"
            # Give monitors a moment to register
            sleep 2
            return 0
        fi
        sleep 1
        (( _i++ ))
    done
    return 1
}

prev_state=$(get_lid_state)
if [[ "$prev_state" == "closed" ]]; then
    wait_for_hyprland && on_lid_close
fi

while true; do
    state=$(get_lid_state)

    if [[ "$state" != "$prev_state" ]]; then
        if [[ "$state" == "closed" ]]; then
            on_lid_close
        elif [[ "$state" == "open" ]]; then
            on_lid_open
        fi
        prev_state="$state"
    fi

    sleep 1
done
