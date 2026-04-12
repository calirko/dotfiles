#!/bin/bash

lid_state=$(cat /proc/acpi/button/lid/LID*/state | awk '{print $NF}')

# Count connected external monitors (exclude the laptop panel BOE)
external_monitors=$(hyprctl monitors -j | jq '[.[] | select(.description | test("BOE") | not)] | length')

if [ "$lid_state" = "open" ]; then
    hyprctl keyword monitor "desc:BOE 0x0A2A",1920x1200@60,auto-left,1
else
    hyprctl keyword monitor "desc:BOE 0x0A2A",disable
    if [ "$external_monitors" -eq 0 ]; then
        systemctl suspend
    fi
fi
