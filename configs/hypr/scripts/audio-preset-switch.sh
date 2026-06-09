#!/bin/bash
# Auto-switch EasyEffects preset based on active audio output.
# Handles three cases: built-in speakers, P2/wired headphones, Bluetooth.

ANALOG_SINK="alsa_output.pci-0000_00_1f.3.analog-stereo"
LAST_PRESET=""

get_preset() {
    # BT running? Use BT preset.
    if pactl list sinks | grep -q "bluez_output.*RUNNING"; then
        echo "Redmi-Buds-5-Pro"
        return
    fi

    local port
    port=$(pactl list sinks | awk '/'"$ANALOG_SINK"'/{f=1} f && /Active Port:/{print $3; f=0}')

    case "$port" in
        *headphone*|*headset*) echo "Headphones" ;;
        *)                     echo "Speakers"   ;;
    esac
}

switch_if_changed() {
    local preset
    preset=$(get_preset)
    if [[ "$preset" != "$LAST_PRESET" ]]; then
        easyeffects -l "$preset"
        LAST_PRESET="$preset"
    fi
}

# Wait for EasyEffects to initialize before doing anything
sleep 3
switch_if_changed

pactl subscribe 2>/dev/null | grep --line-buffered -E "sink|card" | while read -r _; do
    sleep 0.3
    switch_if_changed
done
