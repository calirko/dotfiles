#!/bin/bash
# Run this to find the correct hwmon paths for your AMD system

echo "═══ CPU Temperature (k10temp / zenpower) ═══"
for hwmon in /sys/class/hwmon/hwmon*; do
    name=$(cat "$hwmon/name" 2>/dev/null)
    if [[ "$name" == "k10temp" || "$name" == "zenpower" ]]; then
        echo "  Name: $name"
        echo "  Path: $(readlink -f "$hwmon")"
        echo "  Temp: $(cat "$hwmon/temp1_input" 2>/dev/null | awk '{printf "%.1f°C\n", $1/1000}')"
        echo ""
        echo "  For config.jsonc, set temperature#cpu hwmon-path-abs to:"
        echo "  \"$(readlink -f "$hwmon" | sed 's|/hwmon/hwmon[0-9]*||')\""
    fi
done

echo ""
echo "═══ GPU Temperature (amdgpu) ═══"
for hwmon in /sys/class/hwmon/hwmon*; do
    name=$(cat "$hwmon/name" 2>/dev/null)
    if [[ "$name" == "amdgpu" ]]; then
        echo "  Name: $name"
        echo "  Path: $(readlink -f "$hwmon")"
        echo "  Temp: $(cat "$hwmon/temp1_input" 2>/dev/null | awk '{printf "%.1f°C\n", $1/1000}')"
        echo ""
        echo "  For config.jsonc, set temperature#gpu hwmon-path-abs to:"
        echo "  \"$(readlink -f "$hwmon" | sed 's|/hwmon/hwmon[0-9]*||')\""
    fi
done

echo ""
echo "═══ All hwmon devices ═══"
for hwmon in /sys/class/hwmon/hwmon*; do
    echo "  $(basename $hwmon): $(cat "$hwmon/name" 2>/dev/null) → $(readlink -f "$hwmon")"
done